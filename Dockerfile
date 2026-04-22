# syntax=docker/dockerfile:1
#
# Compman Mobile — Development Image
# ====================================
# Contains Flutter SDK + Android SDK. Project sources are NOT baked in —
# they are mounted at /app at runtime via Docker volumes.
#
# To update SDK versions, change the ARG defaults below and rebuild:
#   docker compose build --no-cache
#
# Version references:
#   Flutter releases:      https://docs.flutter.dev/release/archive
#   Android cmdline-tools: https://developer.android.com/studio#command-line-tools-only

#   Android platforms:     https://developer.android.com/tools/releases/platforms


ARG FLUTTER_VERSION=3.41.7
ARG ANDROID_PLATFORM=36
ARG ANDROID_PLATFORM_COMPAT=35
ARG ANDROID_BUILD_TOOLS=35.0.0
# Numeric ID from the cmdline-tools download URL on developer.android.com
ARG ANDROID_CMDLINE_TOOLS=14742923
ARG ANDROID_NDK_VERSION=28.2.13676358
ARG ANDROID_CMAKE_VERSION=3.22.1
# Host user/group IDs — set in .env (copy from sample.env) so container files
# are owned by the host developer rather than root.
ARG HOST_UID=1000
ARG HOST_GID=1000

FROM ubuntu:24.04


ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    FLUTTER_HOME=/opt/flutter \
    PUB_CACHE=/opt/pub-cache

ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$FLUTTER_HOME/bin

# --- System dependencies ------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git unzip xz-utils zip ca-certificates \
    libglu1-mesa openjdk-21-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

# --- Android SDK --------------------------------------------------------------
ARG FLUTTER_VERSION
ARG ANDROID_PLATFORM
ARG ANDROID_PLATFORM_COMPAT
ARG ANDROID_BUILD_TOOLS
ARG ANDROID_CMDLINE_TOOLS
ARG ANDROID_NDK_VERSION
ARG ANDROID_CMAKE_VERSION
RUN mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools" \
    && wget -q \
       "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip" \
       -O /tmp/cmdtools.zip \
    && unzip -q /tmp/cmdtools.zip -d "$ANDROID_SDK_ROOT/cmdline-tools" \
    && mv "$ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools" \
          "$ANDROID_SDK_ROOT/cmdline-tools/latest" \
    && rm /tmp/cmdtools.zip \
    && yes | sdkmanager --licenses > /dev/null \
    && sdkmanager \
         "platforms;android-${ANDROID_PLATFORM}" \
         "platforms;android-${ANDROID_PLATFORM_COMPAT}" \
         "build-tools;${ANDROID_BUILD_TOOLS}" \
         "platform-tools" \
         "ndk;${ANDROID_NDK_VERSION}" \
         "cmake;${ANDROID_CMAKE_VERSION}"

# --- Flutter SDK --------------------------------------------------------------
RUN wget -q \
       "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
       -O /tmp/flutter.tar.xz \
    && tar -xf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && flutter config --no-analytics \
    && flutter config --android-sdk "$ANDROID_SDK_ROOT" \
    && flutter precache --android \
    && yes | flutter doctor --android-licenses > /dev/null || true \
    && mkdir -p "$PUB_CACHE"

WORKDIR /app

# --- Developer user -----------------------------------------------------------
# Re-declare ARGs: Docker ARG values declared before FROM are not in scope
# after FROM, so we must re-declare them here to use their values.
ARG HOST_UID
ARG HOST_GID
RUN if getent group "${HOST_GID}" > /dev/null 2>&1; then \
        groupmod -n dev "$(getent group ${HOST_GID} | cut -d: -f1)"; \
    else \
        groupadd --gid "${HOST_GID}" dev; \
    fi \
    && if getent passwd "${HOST_UID}" > /dev/null 2>&1; then \
        usermod -l dev -d /home/dev -m "$(getent passwd ${HOST_UID} | cut -d: -f1)"; \
    else \
        useradd --uid "${HOST_UID}" --gid "${HOST_GID}" --create-home dev; \
    fi \
    && mkdir -p "$FLUTTER_HOME/packages/flutter_tools/.dart_tool" \
                /home/dev/.gradle \
                /home/dev/.android \
    && chown -R dev:dev "$PUB_CACHE" \
                        "$FLUTTER_HOME/bin/cache" \
                        "$FLUTTER_HOME/packages/flutter_tools/.dart_tool" \
    && chown dev:dev /home/dev/.gradle /home/dev/.android
USER dev

# Configure Flutter for the dev user so every container starts pre-initialised
# (avoids "Building flutter tool..." and the analytics banner on every run).
RUN flutter config --no-analytics \
    && flutter config --android-sdk "$ANDROID_SDK_ROOT"

CMD ["bash"]
