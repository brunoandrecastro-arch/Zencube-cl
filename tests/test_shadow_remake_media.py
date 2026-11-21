#!/usr/bin/env python3
"""Strict Shadow Realm remake archive contract: 30 individually verified lossless WebP pages."""
import hashlib
import io
import pathlib
import sys
import zipfile

ARCHIVE = pathlib.Path("ZenCube_Shadow_Remake_Game_Media.zip")
SHA256 = "97a954a890bf337fdfb3f7d1c9bac8c1267c524acc9b6816b3d28184e98334ab"
PATHS = [f"assets/shadow_campaign/pages/page_{i:02d}.webp" for i in range(1,31)]

def run(extract: bool) -> None:
    assert ARCHIVE.is_file(), "Final remake media missing. Upload ZenCube_Shadow_Remake_Game_Media.zip via Termux before build."
    assert hashlib.sha256(ARCHIVE.read_bytes()).hexdigest() == SHA256, "Shadow media SHA256 mismatch: reject unverified or outdated pack"
    with zipfile.ZipFile(ARCHIVE) as z:
        assert z.testzip() is None, "Corrupt Shadow media ZIP"
        assert z.namelist() == PATHS, "Exactly 30 ordered remake pages required, without extras"
        seen = set()
        for i, name in enumerate(PATHS, 1):
            info = z.getinfo(name)
            assert info.file_size >= 100_000, f"Invalid media size: {name}"
            data = z.read(name)
            assert data[:4] == b"RIFF" and data[8:12] == b"WEBP", f"Not a WebP: {name}"
            assert data[12:16] == b"VP8L", f"Expected LOSSLESS WebP: {name}"
            digest = hashlib.sha256(data).hexdigest()
            assert digest not in seen, "Duplicate page"
            seen.add(digest)
            if extract:
                dest = pathlib.Path(name)
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_bytes(data)
    if extract:
        assert all(pathlib.Path(n).is_file() for n in PATHS)
    print("Shadow remake PASS: 30 unique native-size, lossless pages and verified archive")

if __name__ == "__main__":
    run("--extract" in sys.argv)
