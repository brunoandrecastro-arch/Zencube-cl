#!/usr/bin/env python3
"""Validate the unsigned Godot Android App Bundle before making it available."""

import configparser
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile


ROOT = Path(__file__).resolve().parents[1]
ANDROID = "{http://schemas.android.com/apk/res/android}"
ASSET_BASE = "assetPackInstallTime/assets/"


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def bundletool(*args):
    java = Path(os.environ["JAVA_HOME"]) / "bin" / "java"
    return subprocess.check_output(
        [java, "-jar", os.environ["BUNDLETOOL_JAR"], *args], text=True
    )


def check_manifest(bundle):
    bundletool("validate", f"--bundle={bundle}")
    manifest = ET.fromstring(bundletool("dump", "manifest", f"--bundle={bundle}"))
    presets = configparser.ConfigParser(interpolation=None)
    presets.read(ROOT / "export_presets.cfg", encoding="utf-8")
    play = next(section for section in presets if presets[section].get("name") == '"Android Play"')
    options = presets[play + ".options"]
    expected = {
        "package": json.loads(options["package/unique_name"]),
        ANDROID + "versionCode": options["version/code"],
        ANDROID + "versionName": json.loads(options["version/name"]),
    }
    require(expected["package"] == "com.zencube.game.play", "Play export must update the existing com.zencube.game.play app")
    for key, value in expected.items():
        require(manifest.get(key) == value, f"Unexpected manifest value for {key}")
    permissions = {node.get(ANDROID + "name") for node in manifest if node.tag.startswith("uses-permission")}
    require(permissions == {"android.permission.VIBRATE"}, f"Unexpected Android permissions: {permissions}")
    require(presets[play]["custom_features"] == '""', "QA feature present in Play export")
    sdk = manifest.find("uses-sdk")
    require(sdk is not None and sdk.get(ANDROID + "targetSdkVersion") == "36", "Expected target SDK 36")
    require(sdk.get(ANDROID + "minSdkVersion") == "26", "Expected minimum SDK 26")
    app = manifest.find("application")
    require(app is not None and app.get(ANDROID + "debuggable", "false") == "false", "App is debuggable")
    config = bundletool("dump", "config", f"--bundle={bundle}")
    require("PAGE_ALIGNMENT_16K" in config, "Bundle misses 16 KB page alignment")
    print(f"{expected['package']} {expected[ANDROID + 'versionName']} ({expected[ANDROID + 'versionCode']}), target SDK 36, 16 KB.")


def check_native_libraries(archive, entries):
    native = sorted(name for name in entries if name.startswith("base/lib/") and name.endswith(".so"))
    require({name.split("/")[2] for name in native} == {"arm64-v8a", "x86_64"}, "Unexpected native ABIs")
    for name in native:
        with archive.open(name) as library:
            header = library.read(64)
            require(header[:6] == b"\x7fELF\x02\x01", f"Expected little-endian 64-bit ELF in {name}")
            offset = struct.unpack_from("<Q", header, 32)[0]
            entry_size, count = struct.unpack_from("<HH", header, 54)
            library.seek(offset)
            alignments = []
            for _ in range(count):
                segment = library.read(entry_size)
                if struct.unpack_from("<I", segment)[0] == 1:  # PT_LOAD
                    alignments.append(struct.unpack_from("<Q", segment, 48)[0])
            require(alignments and min(alignments) >= 16384, f"ELF segments are not 16 KB aligned in {name}")


def check_game_assets(archive, entries):
    assets = {name.removeprefix(ASSET_BASE) for name in entries if name.startswith(ASSET_BASE)}
    for path in ("assets.sparsepck", "_cl_", "project.binary", "story/ZenChronicles.gdc", "story/ZenJourney.gdc", "ui/ZenHomeMenu.gdc"):
        require(path in assets, f"Missing game resource: {path}")
    video_path = "assets/video/moon_shadow_3x3_to_4x4.ogv"
    require(video_path in assets, "The approved Act IV video is missing from the release bundle")
    require(archive.read(ASSET_BASE + video_path) == (ROOT / video_path).read_bytes(), "Act IV video bytes changed in export")
    print("Campaign home, journey navigation and original Act IV video included.")
    for scene in ("Main.tscn", "Ascend.tscn"):
        check_remap(archive, assets, scene, ".remap")

    raw_files = sorted({
        *(ROOT / "story").glob("*.json"),
        *(ROOT / "challenges").glob("*.json"),
        *(ROOT / "assets").glob("*.pcm"),
    })
    for source in raw_files:
        relative = source.relative_to(ROOT).as_posix()
        require(relative in assets, f"Missing game data: {relative}")
        require(archive.read(ASSET_BASE + relative) == source.read_bytes(), f"Game data changed in export: {relative}")

    story = json.loads(archive.read(ASSET_BASE + "story/chronicles.json"))
    chapters = story["chapters"]
    require(len(chapters) == 5 and all(len(chapter["pages"]) == 4 for chapter in chapters), "Expected five chapters of four pages")
    pages = {page["image"].removeprefix("res://") for chapter in chapters for page in chapter["pages"]}
    require(len(pages) == 20, "Expected twenty distinct webcomic pages")
    imported_sources = {
        path.relative_to(ROOT).as_posix()
        for path in (ROOT / "assets").rglob("*")
        if path.is_file() and path.suffix in {".png", ".webp", ".wav", ".ogg", ".mp3"}
    }
    for relative in sorted(pages | imported_sources):
        check_remap(archive, assets, relative, ".import")
    for act in range(1, 5):
        act_root = Path(f"story/act{act:02d}")
        chapter_pages = sorted((ROOT / act_root / "pages").glob("*.png"))
        required = [f"zen_chronicles_ch01_act{act:02d}_{i:02d}.png" for i in range(1, 13)]
        require([p.name for p in chapter_pages] == required, f"Act {act}: incomplete 12-page Manhwa source")
        for image in chapter_pages:
            check_remap(archive, assets, image.relative_to(ROOT).as_posix(), ".import")
    for json_file in sorted((ROOT / "story").rglob("*.json")) + sorted((ROOT / "assets/realm_chronicles").glob("*.json")):
        relative = json_file.relative_to(ROOT).as_posix()
        require(relative in assets and archive.read(ASSET_BASE + relative) == json_file.read_bytes(), f"Missing or changed data: {relative}")
    for scene in ("ZenShatteredMoonCampaign","ZenShatteredMoonReader","ZenSkyGardenCampaign","ZenSkyGardenReader"):
        require("story/" + scene + ".gdc" in assets, f"Missing gameplay script: {scene}")
    for folder in ("tests/", "reports/", "docs/", "play_store/", "scripts/", "build/", ".zencube_backups/"):
        require(not any(name.startswith(folder) for name in assets), f"Development content in bundle: {folder}")
    for boss in ("mist_guardian", "mirror_novice", "veil_monk"):
        check_remap(archive, assets, f"assets/shadow_campaign/portraits/{boss}.webp", ".import")
    for realm in ("shadow_campaign", "abyss_of_memories", "ember_campaign", "celestial_campaign", "satori_campaign", "shattered_moon", "sky_garden"):
        for page in range(1, 31):
            check_remap(archive, assets, f"assets/{realm}/pages/page_{page:02d}.webp", ".import")
    print("Extended Manhwa check: 48 Act I-IV pages, 180 Realm pages and 30 Sky Garden pages, plus the Shadow portraits.")

    print(f"Assets verified: {len(pages)} comic pages, {len(imported_sources)} other images/audio files, {len(raw_files)} data files.")


def check_remap(archive, assets, relative, suffix):
    mapping = relative + suffix
    require(mapping in assets, f"Missing resource map: {relative}")
    content = archive.read(ASSET_BASE + mapping).decode()
    imported = re.findall(r'^path(?:\.[\w]+)?="res://([^"]+)"', content, re.M)
    require(any(path in assets for path in imported), f"Missing imported asset: {relative}")


def main():
    bundle = Path(sys.argv[1]).resolve()
    check_manifest(bundle)
    with zipfile.ZipFile(bundle) as archive:
        entries = set(archive.namelist())
        require(not any(re.fullmatch(r"META-INF/[^/]+\.(SF|RSA|DSA|EC)", name, re.I) for name in entries), "Bundle must be unsigned")
        check_native_libraries(archive, entries)
        check_game_assets(archive, entries)
    with bundle.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    print(f"Unsigned release bundle. SHA-256 {digest}")


if __name__ == "__main__":
    main()
