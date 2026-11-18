#!/usr/bin/env python3
"""Safe, standard-library Campaign 2.0 boss-arena QA; no release changes."""
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SHADOW = ("mist_guardian", "mirror_novice", "veil_monk")
ABYSS = ("memory_thief", "weeping_blade", "forgotten_shogun")
PATHS = [f"assets/shadow_campaign/arenas/{boss}.webp" for boss in SHADOW]
PATHS += [f"assets/abyss_of_memories/arenas/{boss}.webp" for boss in ABYSS]
shadow = (ROOT / "story/ZenShadowCampaign.gd").read_text(encoding="utf-8")
abyss = (ROOT / "story/ZenAbyssCampaign.gd").read_text(encoding="utf-8")
controller = (ROOT / "ui/AscendController.gd").read_text(encoding="utf-8")
assert 'ASSET_ROOT + "arenas/" + BOSS_IDS[index] + ".webp"' in shadow
assert 'ASSET_ROOT + "arenas/%s.webp" % BOSS_IDS[index]' in abyss
assert 'Abyss.battle_backdrop(abyss_index)' in controller
assert 'Shadow.battle_backdrop(shadow_index)' in controller
archive = ROOT / "ZenCube_Campaign2_Boss_Arenas.zip"
if not archive.exists():
    print("CAMPAIGN2 ARENAS: original gameplay unchanged; 6-HD-art ZIP is not committed yet.")
else:
    with zipfile.ZipFile(archive) as z:
        names = set(z.namelist())
        for name in PATHS:
            assert name in names, f"Missing arena in ZIP: {name}"
            payload = z.read(name)
            assert len(payload) >= 75_000, f"Suspiciously small arena: {name}"
            assert payload[:4] == b"RIFF" and payload[8:12] == b"WEBP", f"Not WebP: {name}"
            print(f"OK {name}: {len(payload):,} bytes")
    for name in PATHS:
        p = ROOT / name
        if p.exists():
            assert p.stat().st_size >= 75_000, f"Extracted arena too small: {name}"
    print("CAMPAIGN2 ARENAS: 6 boss-specific WebPs verified.")
