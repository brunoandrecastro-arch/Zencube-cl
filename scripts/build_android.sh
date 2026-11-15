#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${GODOT:=godot}"
: "${ANDROID_SDK_ROOT:?Set ANDROID_SDK_ROOT to your Android SDK}"
: "${JAVA_HOME:?Set JAVA_HOME to OpenJDK 17}"
# Download Godot 4.5.1 and matching official export templates before running.
# This template export needs platform-tools + build-tools;35.0.0 + platforms;android-35.
export XDG_CONFIG_HOME="${ZENCUBE_BUILD_CONFIG:-$PWD/build/editor-config}"
config_dir="$XDG_CONFIG_HOME/godot"
mkdir -p "$config_dir" build
# An isolated editor configuration leaves existing user preferences untouched.
cat > "$config_dir/editor_settings-4.5.tres" <<SETTINGS
[gd_resource type="EditorSettings" format=3]
[resource]
export/android/android_sdk_path = "$ANDROID_SDK_ROOT"
export/android/java_sdk_path = "$JAVA_HOME"
SETTINGS
if [[ "${ZENCUBE_UNSIGNED_DEBUG:-false}" == true ]]; then
  # The campaign PR exports a debug artifact without any signing step.
  preset_backup="$(mktemp)"
  cp export_presets.cfg "$preset_backup"
  trap 'mv "$preset_backup" export_presets.cfg' EXIT
  sed -i 's/^package\/signed=true$/package\/signed=false/' export_presets.cfg
else
  key_path="${ZENCUBE_DEBUG_KEYSTORE:-$HOME/.android/zencube-debug.keystore}"
  mkdir -p "$(dirname "$key_path")"
  if [[ ! -f "$key_path" ]]; then
    "$JAVA_HOME/bin/keytool" -genkeypair -keystore "$key_path" -storepass android -alias androiddebugkey -keypass android -dname 'CN=Android Debug,O=Android,C=US' -keyalg RSA -keysize 2048 -validity 10000
  fi
  cat >> "$config_dir/editor_settings-4.5.tres" <<SETTINGS
export/android/debug_keystore = "$key_path"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
SETTINGS
fi
"$GODOT" --headless --editor --import --quit
"$GODOT" --headless --path . --script tests/test_engine.gd
"$GODOT" --headless --path . --export-debug Android build/ZenCube-3D.apk
if [[ "${ZENCUBE_UNSIGNED_DEBUG:-false}" == true ]]; then
  unzip -tq build/ZenCube-3D.apk
  if "$ANDROID_SDK_ROOT/build-tools/35.0.0/apksigner" verify build/ZenCube-3D.apk >/dev/null 2>&1; then
    echo 'The unsigned campaign artifact unexpectedly has a verified signature.' >&2
    exit 1
  fi
else
  "$ANDROID_SDK_ROOT/build-tools/35.0.0/apksigner" verify --verbose build/ZenCube-3D.apk
fi
