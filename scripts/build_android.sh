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
"$GODOT" --headless --editor --import --quit
"$GODOT" --headless --path . --script tests/test_engine.gd

campaign_test="${ZENCUBE_CAMPAIGN_TEST:-false}"
realm_test="${ZENCUBE_REALM_CHRONICLES_TEST:-false}"
abyss_test="${ZENCUBE_ABYSS_TEST:-false}"
campaign_package="com.zencube.game.campaign"
campaign_label="ZenCube Campaign Test"
if [[ "$realm_test" == true ]]; then
  campaign_test=true
  campaign_package="com.zencube.game.realmchronicles"
  campaign_label="ZenCube 3D Preview"
fi
if [[ "$abyss_test" == true ]]; then
  campaign_test=true
  campaign_package="com.zencube.game.abyss"
  campaign_label="ZenCube Abyss Test"
fi
if [[ "$campaign_test" == true ]]; then
  # Override the Android debug preset for this export only.
  preset_backup="$(mktemp)"
  cp -p export_presets.cfg "$preset_backup"
  trap 'mv -f -- "$preset_backup" export_presets.cfg' EXIT
  sed -i "/^\[preset\.0\.options\]$/,/^\[/ {
    s|^package/unique_name=.*|package/unique_name=\"$campaign_package\"|
    s|^package/name=.*|package/name=\"$campaign_label\"|
  }" export_presets.cfg
  # A private export-only feature permits the player to TEST this campaign
  # even before Zen Master; it does not modify the 4x4 production gates.
  if [[ "$abyss_test" == true ]]; then
    sed -i '0,/custom_features=""/s//custom_features="zencube_abyss_test"/' export_presets.cfg
  fi
fi

# Android previews use the very same access gates as the future Play release.
# No QA or chapter-skip setting may be embedded in the shipped APK.
if grep -q 'config/realm_chronicles_qa=true' project.godot; then
  echo 'ERROR: QA chapter override must not be exported to Android' >&2
  exit 1
fi

apk_path=build/ZenCube-3D.apk
android_build_tools="$ANDROID_SDK_ROOT/build-tools/35.0.0"
"$GODOT" --headless --path . --export-debug Android "$apk_path"
"$android_build_tools/apksigner" verify --verbose "$apk_path"
if [[ "$campaign_test" == true ]]; then
  badging="$("$android_build_tools/aapt2" dump badging "$apk_path")"
  grep -F "package: name='$campaign_package' " <<< "$badging"
  grep -Fx "application-label:'$campaign_label'" <<< "$badging"
fi
