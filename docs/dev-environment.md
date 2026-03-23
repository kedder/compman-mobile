# Development Environment

This document covers how to set up and use the Dockerised development environment for Compman Mobile.

---

## Philosophy

All SDKs (Flutter, Dart, Android) live **inside a Docker container**. Nothing project-related is installed on the host machine. The project directory is bind-mounted into the container so changes are reflected instantly.

```
Host filesystem         Docker container
──────────────          ────────────────────────────────────────
<project dir>  ──────▶  /app                  ← live mount
                        /opt/flutter          ← Flutter SDK
                        /opt/android-sdk      ← Android SDK
                        /opt/pub-cache        ← Dart pub cache (volume)
                        /home/dev/.gradle     ← Gradle cache (volume)
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

# 2. Configure your host user identity
cp sample.env .env
# Edit .env: set HOST_UID=$(id -u) and HOST_GID=$(id -g)

# 3. Build the Docker image (one-time, takes a few minutes)
make build-image

# 4. Install Dart dependencies
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

> **Build performance note** — After the first `make build` warms the Gradle build cache
> (stored in the `gradle_cache` volume), subsequent builds skip unchanged tasks automatically
> thanks to `org.gradle.caching=true` in `android/gradle.properties`.

---

## Running on a Device or Emulator

See **[docs/dev-running.md](dev-running.md)** for full instructions: emulator setup (Debian/Ubuntu, other Linux, macOS), the build-install development loop, hot reload, VS Code Dev Container, and running on a physical device.

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
# 2. Rebuild from scratch (also re-runs flutter config as the dev user)
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

This is solved by the `.env` user-identity setup above. After running `make build-image` with a correct `.env`, files created inside the container are owned by your host user.

If you cloned the repo before setting up `.env` and have root-owned files, fix them once and then rebuild:
```bash
sudo chown -R $(id -u):$(id -g) .
cp sample.env .env   # fill in HOST_UID / HOST_GID
make build-image
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
