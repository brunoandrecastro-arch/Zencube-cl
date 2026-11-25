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
shadow_test="${ZENCUBE_SHADOW_TEST:-false}"
realm2_test="${ZENCUBE_REALM_2_0_TEST:-false}"
celestial_test="${ZENCUBE_CELESTIAL_TEST:-false}"
release_gates="${ZENCUBE_RELEASE_GATES:-false}"
menu_preview="${ZENCUBE_MENU_PREVIEW:-false}"
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
if [[ "$shadow_test" == true ]]; then
  campaign_test=true
  campaign_package="com.zencube.game.shadow"
  campaign_label="ZenCube Shadow Test"
fi
if [[ "$realm2_test" == true ]]; then
  campaign_test=true
  campaign_package="com.zencube.game.realm2"
  campaign_label="ZenCube 2.0 Realm"
fi
if [[ "$celestial_test" == true && "$realm2_test" == true ]]; then
  campaign_label="ZenCube 3D 3.0"
  if [[ "${GITHUB_HEAD_REF:-}" == "feature/zen-act1-integration-20261120" || "${GITHUB_REF_NAME:-}" == "feature/zen-act1-integration-20261120" ]]; then
    campaign_label="ZenCube Chronicles 4.0"
  fi
fi
if [[ "$menu_preview" == true ]]; then
  campaign_test=true
  release_gates=true
  campaign_package="com.zencube.game.menupreview"
  campaign_label="ZenCube Menu Test"
  if [[ "${ZENCUBE_HD_VARIANT:-}" == optimized ]]; then
    campaign_package="com.zencube.game.hdoptimized"
    campaign_label="Zen Cube 3D HD Optimized"
  fi
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
  # Production-like 4.0.1 preview: preserve media extraction but never
  # embed QA feature flags that bypass Zen-Meister / shop ownership.
  if [[ "$realm2_test" == true ]]; then
    if [[ "$release_gates" != true ]]; then
      # Legacy, separately signed QA builds retain their preview access.
      sed -i '0,/custom_features=""/s//custom_features="zencube_realm_2_0_test,zencube_shadow_test,zencube_abyss_test"/' export_presets.cfg
      if [[ "$celestial_test" == true ]]; then
        sed -i '0,/zencube_realm_2_0_test,zencube_shadow_test,zencube_abyss_test/s//zencube_realm_2_0_test,zencube_shadow_test,zencube_abyss_test,zencube_celestial_qa/' export_presets.cfg
      fi
    fi
    if [[ "$celestial_test" == true ]]; then
      sed -i '/^\[preset\.0\.options\]$/,/^\[/ { s|^version/code=.*|version/code=30|; s|^version/name=.*|version/name="3.0"|; }' export_presets.cfg
      if [[ "${GITHUB_HEAD_REF:-}" == "feature/zen-act1-integration-20261120" || "${GITHUB_REF_NAME:-}" == "feature/zen-act1-integration-20261120" ]]; then
        sed -i '/^\[preset\.0\.options\]$/,/^\[/ { s|^version/code=.*|version/code=44|; s|^version/name=.*|version/name="4.0.4"|; }' export_presets.cfg
      fi
    fi
  elif [[ "$shadow_test" == true ]]; then
    # Both chapters are testable in this separate Campaign 2.0 build.
    sed -i '0,/custom_features=""/s//custom_features="zencube_shadow_test,zencube_abyss_test"/' export_presets.cfg
  elif [[ "$abyss_test" == true ]]; then
    sed -i '0,/custom_features=""/s//custom_features="zencube_abyss_test"/' export_presets.cfg
  fi
  if [[ "$menu_preview" == true ]]; then
    sed -i '/^\[preset\.0\.options\]$/,/^\[/ { s|^version/code=.*|version/code=45|; s|^version/name=.*|version/name="4.0.5-test"|; }' export_presets.cfg
  fi
fi

# Android production-gated previews obey the same persistent ownership checks as Play.
if [[ "$release_gates" == true ]]; then
  if grep -Eq 'custom_features="[^"]+"' export_presets.cfg; then
    echo 'ERROR: release-gated preview must not contain QA feature flags' >&2
    exit 1
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
