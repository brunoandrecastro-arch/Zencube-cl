#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

: "${GODOT:=godot}"
: "${JAVA_HOME:?Set JAVA_HOME to OpenJDK 17 or newer}"
: "${BUNDLETOOL_JAR:?Set BUNDLETOOL_JAR to bundletool-all-1.18.3.jar}"
android_sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:?Set ANDROID_HOME to the Android SDK}}"
templates="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/4.5.1.stable"
if [[ ! -x "$JAVA_HOME/bin/javac" || ! -x "$JAVA_HOME/bin/jar" ]]; then
  echo 'A complete Java JDK (including javac and jar), not only a Java runtime, is required.' >&2
  exit 1
fi
if [[ "$("$GODOT" --version)" != 4.5.1.stable.* ]]; then
  echo 'Godot 4.5.1 stable is required.' >&2
  exit 1
fi
if [[ ! -f "$templates/android_source.zip" || ! -f "$android_sdk/platforms/android-36/android.jar" ]]; then
  echo 'Install the Godot 4.5.1 Android export templates and Android SDK Platform 36.' >&2
  exit 1
fi

mkdir -p build
exec 9>build/.play-build.lock
flock -n 9 || { echo 'An Android App Bundle build is already running.' >&2; exit 1; }
work_dir=$(mktemp -d "$PWD/build/play-output.XXXXXXXX")
trap 'rm -rf -- "$work_dir"' EXIT

# Match the layout that Godot creates when installing its default Gradle template.
gradle_dir=build/play-android/build
mkdir -p "$gradle_dir"
unzip -qo "$templates/android_source.zip" -d "$gradle_dir"
touch "$gradle_dir/.gdignore"
printf '%s\n' '4.5.1.stable' > build/play-android/.build_version
chmod +x "$gradle_dir/gradlew"

# Godot 4.5.1 ships with API 35 tooling. Keep its engine and native libraries.
sed -i -e "s/androidGradlePlugin: '8.6.1'/androidGradlePlugin: '8.10.1'/" \
  -e 's/compileSdk         : 35,/compileSdk         : 36,/' "$gradle_dir/config.gradle"
grep -Fq "androidGradlePlugin: '8.10.1'" "$gradle_dir/config.gradle"
grep -Fq 'compileSdk         : 36,' "$gradle_dir/config.gradle"
printf '\ndistributionSha256Sum=%s\n' 'f397b287023acdba1e9f6fc5ea72d22dd63669d59ed4a289a29b1a76eee151c6' \
  >> "$gradle_dir/gradle/wrapper/gradle-wrapper.properties"

export XDG_CONFIG_HOME="$work_dir/editor-config"
mkdir -p "$XDG_CONFIG_HOME/godot"
cat > "$XDG_CONFIG_HOME/godot/editor_settings-4.5.tres" <<SETTINGS
[gd_resource type="EditorSettings" format=3]
[resource]
export/android/android_sdk_path = "$android_sdk"
export/android/java_sdk_path = "$JAVA_HOME"
SETTINGS

# Use precisely the optimized import settings from successful build #510.
# Original artwork, audio and video bytes are never recompressed here.
bash scripts/prepare_play_media.sh
"$GODOT" --headless --editor --import --quit
if [[ ! -f build/hd-import-state.json ]]; then
  python3 scripts/hd_storage_imports.py prepare
  "$GODOT" --headless --editor --import --quit
fi
python3 scripts/hd_storage_imports.py verify

# A release export is forbidden unless every regression passes on this tree.
python3 scripts/test_play_release.py
"$GODOT" --headless --path . --export-release 'Android Play' "$work_dir/ZenCube-3D-6.0-HD-unsigned.aab"
python3 scripts/verify_play_bundle.py "$work_dir/ZenCube-3D-6.0-HD-unsigned.aab"
mv -f -- "$work_dir/ZenCube-3D-6.0-HD-unsigned.aab" build/ZenCube-3D-6.0-HD-unsigned.aab
sha256sum build/ZenCube-3D-6.0-HD-unsigned.aab > build/ZenCube-3D-6.0-HD-unsigned.aab.sha256
stat -c 'AAB size: %s bytes' build/ZenCube-3D-6.0-HD-unsigned.aab
printf '\n%s\n' 'Unsigned release bundle ready: build/ZenCube-3D-6.0-HD-unsigned.aab'
