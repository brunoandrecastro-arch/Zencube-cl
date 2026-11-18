#!/usr/bin/env python3
"""Verify the exact approved arena payload and fail before export if missing."""
import argparse
import hashlib
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / "ZenCube_Campaign2_Final_Arenas.zip"
EXPECTED = {
    "assets/shadow_campaign/arenas/mist_guardian.webp": "2b23993dcfeea6c12afdc26ac1372e3792c97519fa53aa2f58f890f6f4e03ae4",
    "assets/shadow_campaign/arenas/mirror_novice.webp": "2c926f26e2c9c9cd061b9a1de4b7c51a549c9f3c9a8fc84f1db4ca28f1d9be39",
    "assets/shadow_campaign/arenas/veil_monk.webp": "26186f48c87878d119767578e7897df27787c6b73ab743e0acf58939ff926794",
    "assets/abyss_of_memories/arenas/memory_thief.webp": "1f55ec3bd3c4321e3f8fcb04996e3990fda3fed4b3ac3bf91cd4d287e09e1dd4",
    "assets/abyss_of_memories/arenas/weeping_blade.webp": "66f8aed3cd14ce38a018dfb2864f06fd63434206b9b7c225de1475168bedcf6a",
    "assets/abyss_of_memories/arenas/forgotten_shogun.webp": "613d28e9b26ee40c6ff11d46c1802da475da93fea81b2f4d404b549ae3c6db23",
    "assets/abyss_of_memories/gameplay.webp": "4709702f1cfc70d29736db8ee54d7142d9a6333010a59b811675dfd6200fdd3f",
}
p = argparse.ArgumentParser()
p.add_argument("--extract", action="store_true")
p.add_argument("--apk", type=Path)
a = p.parse_args()
assert PACK.is_file(), f"Missing approved arena pack: {PACK.name}"
with zipfile.ZipFile(PACK) as archive:
    assert sorted(archive.namelist()) == sorted(EXPECTED), "Unexpected/missing entries in arena ZIP"
    assert archive.testzip() is None
    for path, digest in EXPECTED.items():
        data = archive.read(path)
        assert data[:4] == b"RIFF" and data[8:12] == b"WEBP", path
        assert hashlib.sha256(data).hexdigest() == digest, path
        target = ROOT / path
        if a.extract:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        assert target.read_bytes() == data, path
        print("Verified:", path)
if a.apk:
    with zipfile.ZipFile(a.apk) as apk:
        names = set(apk.namelist())
        for path in EXPECTED:
            assert "assets/" + path + ".import" in names or "assets/" + path in names, path
            print("APK texture:", path)
