#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
unzip -oq ZenCube_Abyss_Media_Pages.zip -d .
unzip -oq ZenCube_Abyss_Media_Boss_Audio.zip -d .
python3 tests/test_shadow_remake_media.py --extract
unzip -oq ZenCube_2.0_Realm_Artwork.zip -d .
python3 tests/test_campaign2_arenas.py --extract
unzip -oq ZenCube_Ember_Media.zip -d .
python3 tests/test_celestial_media.py --extract
python3 scripts/hd_realm_thumbnails.py
