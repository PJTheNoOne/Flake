#!/usr/bin/env bash
# Bootstrap for the `android` (Arch) box. Usage: android.sh <container-home>
# Packages (JDK, node, ...) come from additional_packages in distrobox.ini;
# this script does what a package manager can't: the Android SDK itself.
set -u
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=common.sh
. "$here/common.sh"

resolve_user "${1:?usage: android.sh <container-home>}" || exit 0

# ---- knobs: bump these when a project's compileSdk / buildTools change -------
PLATFORMS="android-35"
BUILD_TOOLS="35.0.0"
JDK_NAME="java-17-openjdk"       # `archlinux-java status` name; keep in sync with the .ini package
# ------------------------------------------------------------------------------

ANDROID_HOME="$USER_HOME/Android/Sdk"
JAVA_HOME="/usr/lib/jvm/$JDK_NAME"
sdkmanager_bin="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

sdk() {
  as_user env JAVA_HOME="$JAVA_HOME" ANDROID_HOME="$ANDROID_HOME" \
    "$sdkmanager_bin" --sdk_root="$ANDROID_HOME" "$@"
}

# 1. Default `java` -> the JDK Gradle/AGP expect.
if command -v archlinux-java >/dev/null 2>&1 && [ "$(archlinux-java get 2>/dev/null)" != "$JDK_NAME" ]; then
  archlinux-java set "$JDK_NAME" || warn "could not select $JDK_NAME"
fi

# 2. Command-line tools (the bit that gives you sdkmanager).
if [ ! -x "$sdkmanager_bin" ]; then
  log "downloading Android command-line tools"
  zip=$(curl -fsSL https://dl.google.com/android/repository/repository2-3.xml \
        | grep -o 'commandlinetools-linux-[0-9]*_latest\.zip' | sort -u | sort -t- -k3 -n | tail -1)
  if [ -z "$zip" ]; then
    warn "could not work out the latest cmdline-tools zip (offline?). Will retry next start."
  else
    tmp=$(mktemp -d)
    if curl -fsSL -o "$tmp/$zip" "https://dl.google.com/android/repository/$zip" \
       && unzip -q "$tmp/$zip" -d "$tmp/x" \
       && mkdir -p "$ANDROID_HOME/cmdline-tools" \
       && mv "$tmp/x/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"; then
      chown -R "$USER_UID:$USER_GID" "$USER_HOME/Android"
    else
      warn "cmdline-tools download/unpack failed"
    fi
    rm -rf "$tmp"
  fi
fi

# 3. Licences + SDK packages (skipped once the marker for this exact list exists).
if [ -x "$sdkmanager_bin" ]; then
  want="platform-tools platforms;$PLATFORMS build-tools;$BUILD_TOOLS"
  marker="$ANDROID_HOME/.provisioned-$(printf '%s' "$want" | md5sum | cut -c1-12)"
  if [ ! -e "$marker" ]; then
    log "accepting licences and installing: $want"
    yes | sdk --licenses >/dev/null 2>&1
    if sdk "platform-tools" "platforms;$PLATFORMS" "build-tools;$BUILD_TOOLS"; then
      as_user touch "$marker"
    else
      warn "sdkmanager install failed; will retry next start"
    fi
  fi

  # 4. Put the tools on PATH for *every* kind of shell (VS Code attach, `distrobox enter -- cmd`, pi).
  #    One adb only: the SDK's. AGP's installDebug uses it, so a second adb would fight it.
  for t in sdkmanager avdmanager; do ln -sf "$ANDROID_HOME/cmdline-tools/latest/bin/$t" "/usr/local/bin/$t"; done
  for t in adb fastboot; do
    [ -x "$ANDROID_HOME/platform-tools/$t" ] && ln -sf "$ANDROID_HOME/platform-tools/$t" "/usr/local/bin/$t"
  done
fi

# 5. pi
npm_global pi @mariozechner/pi-coding-agent

log "android box ready"
