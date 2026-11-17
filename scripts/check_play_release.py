#!/usr/bin/env python3
"""Fail closed on accidental package, entitlement, QA or compatibility changes."""
import configparser
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def check():
    presets = configparser.ConfigParser(interpolation=None)
    presets.read(ROOT / "export_presets.cfg", encoding="utf-8")
    section = next(s for s in presets if presets[s].get("name") == '"Android Play"')
    play, options = presets[section], presets[section + ".options"]
    expected = {
        "package/unique_name": '"com.zencube.game.play"',
        "package/name": '"ZenCube 3D"', "package/signed": "false",
        "version/name": '"2.4"', "gradle_build/target_sdk": '"36"',
        "gradle_build/min_sdk": '"24"', "gradle_build/export_format": "1",
        "gradle_build/use_gradle_build": "true",
        "architectures/arm64-v8a": "true", "architectures/x86_64": "true",
        "architectures/armeabi-v7a": "false", "architectures/x86": "false",
    }
    for key, value in expected.items():
        assert options.get(key) == value, f"Android Play: {key} must be {value}"
    assert int(options["version/code"]) > 23, "Must exceed last documented Alpha versionCode 23"
    assert play.get("custom_features") == '""', "No QA or test export features"
    settings = (ROOT / "project.godot").read_text()
    assert "realm_chronicles_qa" not in settings, "No QA project setting may be exported"
    mode = (ROOT / "core/ZenAscend.gd").read_text()
    assert "const TEST_UNLOCKED: bool = false" in mode
    access = mode.split("static func test_access_enabled() -> bool:", 1)[1].split("static func unlocked(", 1)[0]
    assert re.search(r"^    return false$", access, re.M)
    assert "return unlocked_for_release(data)" in mode
    audio = ROOT / "assets/realm_boss_music"
    rows = [row.split() for row in (audio / "checksums.sha256").read_text().splitlines() if row.strip()]
    assert len(rows) == 12 and len(list(audio.glob("*.ogg"))) == 12, "All 12 exclusive boss tracks are mandatory"
    for digest, name in rows:
        assert hashlib.sha256((audio / name).read_bytes()).hexdigest() == digest, name
    assert len(list((ROOT / "assets/realm_chronicles").glob("boss_*.json"))) == 12
    print("PASS: Android Play 2.4, existing package, API 24–36, 64-bit ABIs, normal unlocks, no QA settings, 12 original boss tracks")
    print("CONSOLE GATE: versionCode must still be checked against ALL currently used Play codes before signing/upload.")


if __name__ == "__main__":
    check()
