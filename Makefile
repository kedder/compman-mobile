# Compman Mobile — Development Makefile
# ========================================
# All targets run inside the Docker development container.
# Prerequisites: Docker (with Compose plugin), GNU make
#
# Quick reference:
#   make deps          Install/update Dart dependencies
#   make codegen       Run code generation (freezed, json_serializable, launcher icons)
#   make test          Run all tests
#   make analyze       Static analysis
#   make format        Format source files
#   make build         Build debug APK
#   make build-aab     Build release AAB signed with upload key  (needs signing vars in .env)
#   make install       Install debug APK on connected device/emulator  (host adb)
#   make shell         Open interactive shell in container
#
# Run `make help` for the full list.

COMPOSE := docker compose
RUN     := $(COMPOSE) run --rm dev

.PHONY: help build-image deps codegen codegen-watch \
        test test-coverage \
        analyze format format-check \
        build build-release build-aab install \
        flutter-run \
        clean doctor shell

.DEFAULT_GOAL := help

# ── Image management ──────────────────────────────────────────────────────────

build-image: ## Build (or rebuild) the Docker development image
	$(COMPOSE) build

# ── Dependencies ──────────────────────────────────────────────────────────────

deps: ## Install / update Dart dependencies  (flutter pub get)
	$(RUN) flutter pub get

# ── Code generation ───────────────────────────────────────────────────────────

codegen: ## Run code generation once  (freezed, json_serializable, launcher icons, etc.)
	$(RUN) dart run flutter_launcher_icons
	$(RUN) dart run build_runner build --delete-conflicting-outputs

codegen-watch: ## Run code generation in watch mode  (keeps running; Ctrl-C to stop)
	$(COMPOSE) run --rm -it dev dart run build_runner watch --delete-conflicting-outputs

# ── Testing ───────────────────────────────────────────────────────────────────

test: ## Run all unit and widget tests
	$(RUN) flutter test

test-coverage: ## Run tests with coverage report  (output: coverage/lcov.info)
	$(RUN) flutter test --coverage

# ── Code quality ──────────────────────────────────────────────────────────────

analyze: ## Run static analysis  (flutter analyze)
	$(RUN) flutter analyze

format: ## Format all Dart source files in-place
	$(RUN) dart format lib test

format-check: ## Check formatting without applying changes  (CI-friendly, exits 1 on diff)
	$(RUN) dart format --output=none --set-exit-if-changed lib test

# ── Build ─────────────────────────────────────────────────────────────────────

build: ## Build a debug APK  (output: build/app/outputs/flutter-apk/)
	$(RUN) flutter build apk --debug

build-release: ## Build a release APK signed with the upload key
	$(RUN) flutter build apk --release

build-aab: ## Build a release AAB for Play Store upload  (requires UPLOAD_STORE_PASSWORD etc. in .env)
	$(RUN) flutter build appbundle --release

install: ## Install the debug APK on a connected device/emulator  (runs adb on the host, not in Docker)
	adb install -r build/app/outputs/flutter-apk/app-debug.apk

flutter-run: ## Run app on a host emulator/device with hot reload  (Linux only — requires emulator running on host)
	$(COMPOSE) run --rm -it flutter-run flutter run

# ── Maintenance ───────────────────────────────────────────────────────────────

clean: ## Remove build artefacts  (flutter clean)
	$(RUN) flutter clean

doctor: ## Run flutter doctor inside the container
	$(RUN) flutter doctor -v

# ── Interactive shell ─────────────────────────────────────────────────────────

shell: ## Open an interactive shell inside the dev container
	$(COMPOSE) run --rm -it dev bash

# ── Help ──────────────────────────────────────────────────────────────────────

help: ## Show this help message
	@echo ""
	@echo "Compman Mobile — development commands"
	@echo "All targets run inside the Docker dev container."
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "  %-18s %s\n", "TARGET", "DESCRIPTION\n"} \
	      /^[a-zA-Z_-]+:.*?##/ { printf "  %-18s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "  NOTE: 'flutter run' is intentionally absent."
	@echo "        See docs/dev-environment.md for running on a device."
	@echo ""
