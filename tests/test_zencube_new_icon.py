#!/usr/bin/env python3
"""Approved launcher and Android 13 themed icon: fail closed on stale branding."""
from pathlib import Path
from hashlib import sha256
from struct import unpack
ROOT=Path(__file__).resolve().parents[1]
FILES={
    "assets/icons/zencube_launcher_192.png":(192,192,"e3b849d70048088c194fc6d0025270c294e58b0809f88a38612b75d65ed2ef76"),
    "assets/icons/zencube_adaptive_foreground_432.png":(432,432,"c3d81148c8b91ff2df1f5f16d4972224d8a6e97f6bcbe2d9fff1e15a605c2f42"),
    "assets/icons/zencube_adaptive_background_432.png":(432,432,"5fd2531e5b326764530df0dc27e2ec603aabc512dc924cc08140ef81c4d47805"),
    "assets/icons/zencube_adaptive_monochrome_432.png":(432,432,"1c81afa61fcd7e6598a05a71427b3eceda51a5bc5048269ddea35a9711e3cc8a"),
}
for p,(w,h,expected) in FILES.items():
    path=ROOT/p
    assert path.is_file(),f"Approved new icon not yet uploaded via Termux: {p}"
    data=path.read_bytes()
    assert data.startswith(b'\x89PNG\r\n\x1a\n'),f"Invalid PNG: {p}"
    assert unpack(">II",data[16:24])==(w,h),f"Wrong dimensions: {p}"
    assert sha256(data).hexdigest()==expected,f"Icon art mismatch: {p}"
presets=(ROOT/"export_presets.cfg").read_text()
for name in FILES:
    assert presets.count('res://'+name)>=2,f"Both Android export presets must use {name}"
print("APP ICON OK: approved Kuze/Shadow Kuze, legacy & adaptive/monochrome launcher paths")
