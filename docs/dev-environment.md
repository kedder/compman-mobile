# Development Environment

This document covers how to set up and use the Dockerised development environment for Compman Mobile.

---

## Philosophy

All SDKs (Flutter, Dart, Android) live **inside a Docker container**. Nothing project-related is installed on the host machine. The project directory is bind-mounted into the container so changes are reflected instantly.

```
Host filesystem         Docker container
──────────────          ────────────────────────────────────────
~/projects/             /app                  ← live mount
  compman-mobile/ ──▶   /opt/flutter          ← Flutter SDK
                        /opt/android-sdk      ← Android SDK
                        /opt/pub-cache        ← Dart pub cache (volume)
                        /root/.gradle         ← Gradle cache (volume)
```

There are **two ways** to use the container, depending on your workflow:

| Mode | How | Best for |
|---|---|---|
| **Makefile** | `make test` from host terminal | Running individual tasks; AI agents on the host |
| **Dev Container** | VS Code Remote Containers / Copilot CLI inside container | Full development; AI agents with direct tool access |

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) with the Compose plugin (`docker compose version`)
- GNU `make` (`make --version`)
- That's it — Flutter and Android SDK are in the container

---

## First-Time Setup

```bash
# 1. Clone the repo
git clone <repo-url> compman-mobile
cd compman-mobile

# 2. Build the Docker image (one-time, takes a few minutes)
make build-image

# 3. Install Dart dependencies
make deps
```

After this, every `make` target is ready to use.

---

## Common Commands

```bash
make deps            # flutter pub get
make codegen         # run build_runner once (freezed, json_serializable)
make codegen-watch   # run build_runner in watch mode (Ctrl-C to stop)
make test            # flutter test
make test-coverage   # flutter test --coverage → coverage/lcov.info
make analyze         # flutter analyze
make format          # dart format lib test
make build           # flutter build apk --debug
make build-release   # flutter build apk --release
make clean           # flutter clean
make doctor          # flutter doctor -v
make shell           # interactive bash shell inside the container
make help            # full target list with descriptions
```

All targets start a fresh container (`--rm`), run the command, then exit. Dart and Gradle caches are persisted in named Docker volumes so subsequent runs are fast.

---

## Running on a Device (`flutter run`)

`flutter run` requires an ADB connection to a physical device or emulator and is **not** part of the Makefile workflow. There are two options:

### Option A — VS Code Dev Container (recommended)

Open the project in VS Code with the Remote Containers extension. The Flutter extension inside the container can detect devices forwarded by VS Code's ADB bridge. Use the device picker in the status bar or `F5` to launch.

### Option B — ADB over WiFi (Linux hosts only)

```bash
# On the host, connect the device via USB and enable TCP ADB:
adb tcpip 5555
adb connect <device-ip>:5555

# Then run flutter inside the container (needs host network):
docker compose run --rm --network=host dev flutter run
```

This works on Linux where `--network=host` gives the container access to the host's ADB TCP socket. It does **not** work on macOS or Windows Docker Desktop.

---

## Dev Container (VS Code / AI Agents)

The `.devcontainer/devcontainer.json` configures a container for VS Code Remote Containers and AI coding agents (Copilot CLI, Claude Dev, etc.) that operate **from inside** the container.

When inside the dev container, all tools are available directly — no `make` wrappers needed:

```bash
flutter test
flutter analyze
dart run build_runner build --delete-conflicting-outputs
flutter build apk
```

### Opening in VS Code

1. Install the [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension
2. Open the project folder
3. VS Code prompts: **"Reopen in Container"** — click it
4. First open runs `flutter pub get` automatically

### AI Agent Usage

Agents running inside the dev container (e.g., via `gh copilot` or Claude Dev in container mode) have direct access to all Flutter/Dart/Android tools. They should use the native commands listed above. The `Makefile` remains useful for discoverability (`make help`).

---

## Updating SDK Versions

All version pins are in `Dockerfile` as `ARG` defaults at the top of the file.

| ARG | Description | Where to find latest |
|---|---|---|
| `FLUTTER_VERSION` | Flutter stable release | [docs.flutter.dev/release/archive](https://docs.flutter.dev/release/archive) |
| `ANDROID_PLATFORM` | Android API level | [developer.android.com/tools/releases/platforms](https://developer.android.com/tools/releases/platforms) |
| `ANDROID_BUILD_TOOLS` | Android build-tools version | Same page as above |
| `ANDROID_CMDLINE_TOOLS` | Numeric ID in the cmdline-tools download URL | [developer.android.com/studio#command-line-tools-only](https://developer.android.com/studio#command-line-tools-only) |

To update:

```bash
# 1. Edit Dockerfile ARG defaults
# 2. Rebuild from scratch
make build-image  # (docker compose build --no-cache internally)
# 3. Re-install dependencies
make deps
```

---

## Troubleshooting

### `make` command not found
Install GNU make: `sudo apt install make` (Linux) or via Homebrew: `brew install make` (macOS).

### Docker image out of date
After changing `Dockerfile` or upgrading SDK versions, force a full rebuild:
```bash
docker compose build --no-cache
```

### Permission errors on mounted files
The container runs as root. If files created inside the container are owned by root on the host, run:
```bash
sudo chown -R $(id -u):$(id -g) .
```

### Pub cache or Gradle cache is stale
Remove the named volumes and re-run:
```bash
docker volume rm compman-mobile_pub_cache compman-mobile_gradle_cache
make deps
```

### `flutter doctor` warnings about Android licenses
```bash
make shell
# inside the container:
yes | flutter doctor --android-licenses
```
