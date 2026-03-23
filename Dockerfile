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

ARG FLUTTER_VERSION=3.27.4
ARG ANDROID_PLATFORM=35
ARG ANDROID_BUILD_TOOLS=35.0.0
# Numeric ID from the cmdline-tools download URL on developer.android.com
ARG ANDROID_CMDLINE_TOOLS=11076708

FROM ubuntu:24.04

ARG FLUTTER_VERSION
ARG ANDROID_PLATFORM
ARG ANDROID_BUILD_TOOLS
ARG ANDROID_CMDLINE_TOOLS

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
         "build-tools;${ANDROID_BUILD_TOOLS}" \
         "platform-tools"

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

CMD ["bash"]
