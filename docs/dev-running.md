# Running on a Device or Emulator

Building the APK happens inside Docker (`make build`). Running it requires an ADB connection to a physical device or emulator, which is managed on the host.

---

## Emulator Setup (one-time, host only)

The Android emulator is installed directly on the host using Google's command-line tools — no Android Studio required. The emulator uses hardware acceleration natively on each platform (KVM on Linux, Hypervisor.framework on macOS) so no special configuration is needed.

**~2 GB total download:** cmdline-tools (~150 MB) + emulator (~400 MB) + system image (~1.5 GB).

**Java 17+ required** for `sdkmanager` and `avdmanager` (the container uses Java 21 — install the same on the host to match):
- Linux: `sudo apt install openjdk-21-jdk-headless`
- macOS: `brew install openjdk@21`

### Linux — Debian/Ubuntu (recommended)

The packages `google-android-platform-tools-installer`, `google-android-cmdline-tools-13.0-installer`, and `google-android-emulator-installer` are available in the Debian/Ubuntu `contrib` archive component.

```bash
# 1. Enable the contrib component and install Android tools
sudo apt-get install software-properties-common
sudo add-apt-repository contrib   # Debian; on Ubuntu: sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install google-android-platform-tools-installer \
                     google-android-cmdline-tools-13.0-installer \
                     google-android-emulator-installer

# 2. Install the Android 35 system image and platform
yes | sdkmanager --licenses
sdkmanager "system-images;android-35;google_apis;x86_64"
sudo apt-get install android-sdk-platform-35
# The emulator requires the platforms/ directory to be present — without it you get:
# "PANIC: Cannot find AVD system path. Please define ANDROID_SDK_ROOT"

# 3. Create an AVD named "compman"
echo no | avdmanager create avd -n compman \
  -k "system-images;android-35;google_apis;x86_64" \
  --device "pixel_6"
```

### Linux — Other distributions (manual)

```bash
# 1. Download and unpack Android command-line tools
mkdir -p ~/android-sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-*.zip -d ~/android-sdk/cmdline-tools
mv ~/android-sdk/cmdline-tools/cmdline-tools ~/android-sdk/cmdline-tools/latest
rm commandlinetools-linux-*.zip

# 2. Add to PATH (add these lines to ~/.bashrc or ~/.zshrc)
export ANDROID_SDK_ROOT=~/android-sdk
export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator

# 3. Install emulator, ADB, and the Android 35 system image
yes | sdkmanager --licenses
sdkmanager "platform-tools" "emulator" "system-images;android-35;google_apis;x86_64"

# 4. Create an AVD named "compman"
echo no | avdmanager create avd -n compman \
  -k "system-images;android-35;google_apis;x86_64" \
  --device "pixel_6"
```

### macOS

Same steps, with a different download URL and system image. Use `arm64-v8a` on Apple Silicon or `x86_64` on Intel.

```bash
# 1. Download and unpack Android command-line tools
mkdir -p ~/android-sdk/cmdline-tools
curl -O https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip
unzip commandlinetools-mac-*.zip -d ~/android-sdk/cmdline-tools
mv ~/android-sdk/cmdline-tools/cmdline-tools ~/android-sdk/cmdline-tools/latest
rm commandlinetools-mac-*.zip

# 2. Add to PATH (add to ~/.zshrc)
export ANDROID_SDK_ROOT=~/android-sdk
export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator

# 3. Install emulator, ADB, and system image
yes | sdkmanager --licenses
# Apple Silicon:
sdkmanager "platform-tools" "emulator" "system-images;android-35;google_apis;arm64-v8a"
# Intel Mac:
# sdkmanager "platform-tools" "emulator" "system-images;android-35;google_apis;x86_64"

# 4. Create an AVD named "compman"
# Apple Silicon:
echo no | avdmanager create avd -n compman \
  -k "system-images;android-35;google_apis;arm64-v8a" \
  --device "pixel_6"
# Intel Mac:
# echo no | avdmanager create avd -n compman \
#   -k "system-images;android-35;google_apis;x86_64" \
#   --device "pixel_6"
```

---

## Development Loop

The standard workflow is: **edit → build → install → test**.

```
┌─────────────────────────────┐     ┌──────────────────────────────┐
│  Docker container           │     │  Host                        │
│                             │     │                              │
│  edit source in lib/        │     │  emulator -avd compman       │
│       │                     │     │       │                      │
│  make build                 │     │       │ (running)            │
│       │                     │     │       │                      │
│  build/app/outputs/         │──▶  │  adb install app-debug.apk   │
│    flutter-apk/             │     │       │                      │
│    app-debug.apk            │     │  app updated in emulator     │
└─────────────────────────────┘     └──────────────────────────────┘
```

**Step by step:**

```bash
# Terminal 1 (host) — start the emulator once, keep it running
emulator -avd compman

# Terminal 2 — edit sources, then build and install
make build
make install
# make install runs: adb install -r build/app/outputs/flutter-apk/app-debug.apk
# -r replaces an existing installation without uninstalling (preserves app data)
```

Repeat `make build` + `make install` for each change. The Gradle build cache (in the `gradle_cache` Docker volume) makes incremental builds fast after the first one.

**Linux shortcut — `flutter run` with hot reload:**

On Linux, `--network=host` lets the container reach the host's ADB server directly, enabling hot reload:

```bash
# Terminal 1 (host): start emulator
emulator -avd compman

# Terminal 2: flutter run from inside the container
make flutter-run
# Press 'r' to hot reload, 'R' for hot restart, 'q' to quit
```

This does **not** work on macOS or Windows Docker Desktop — use the `make build` + `adb install` loop there instead.

---

## Option A — VS Code Dev Container (all platforms, with hot reload)

Open the project in VS Code with the Remote Containers extension. The Flutter extension inside the container can detect devices forwarded by VS Code's ADB bridge. Start the emulator on the host first, then use the device picker in the VS Code status bar or press `F5` to launch with hot reload.

---

## Option B — Physical Device (all platforms)

### 1. Prepare the device

1. On your Android phone, go to **Settings → About phone** and tap **Build number** seven times to unlock Developer Options.
2. Go to **Settings → Developer options** and enable **USB debugging**.

### 2. Connect via USB

```bash
# Connect the phone, then verify it is detected
adb devices
# Expected output:
#   List of devices attached
#   XXXXXXXX    device
```

If the device shows as `unauthorized`, check your phone for a prompt asking to trust the computer and tap **Allow**.

### 3. Build and install

```bash
make build
make install
```

Repeat for each change. Use `adb devices` to confirm the device is still connected if installation fails.

### 4. Wireless ADB (optional, Android 11+)

After the initial USB connection you can switch to wireless:

```bash
adb tcpip 5555
# Disconnect USB, then:
adb connect <device-ip>:5555
# Find device IP in Settings → About phone → Status → IP address
```
