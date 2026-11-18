#!/usr/bin/env python3
"""Check the seven supplied arena textures byte-for-byte; no placeholder substitutions."""
from pathlib import Path
import hashlib
import zipfile

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {
    "assets/shadow_campaign/arenas/mist_guardian.webp": "94d5a7c1103b37bae4bc78b64ad19c5e32234e17c42426f82787b5b72d452266",
    "assets/shadow_campaign/arenas/mirror_novice.webp": "fdb80c3f73c165b54165039a178e5c53564375719c79f573142db07cb2281987",
    "assets/shadow_campaign/arenas/veil_monk.webp": "bf7256880a369e3ab4820a0b245348e565a2dcf3702fda254b6bc13acb91b370",
    "assets/abyss_of_memories/arenas/memory_thief.webp": "512537cbe74efef39877224bd9d972f6c483c5d0360b759c1fcd6027e7382514",
    "assets/abyss_of_memories/arenas/weeping_blade.webp": "68166afa9ef538fef8e05dda1b8ac9c19de96a2f1f6ab5773ec3821bd17ef24b",
    "assets/abyss_of_memories/arenas/forgotten_shogun.webp": "0a046501922e2ac1213f9f8d6590ab023d09032d02616c35fad6dc530ae57df2",
    "assets/abyss_of_memories/gameplay.webp": "3e79ab7e68509c03a78b4bb8755bd7e312e0c4a9137c8fb83786f382c889ba9e"
}
archive = ROOT / "ZenCube_Campaign2_Final_Arenas.zip"
shadow = (ROOT / "story/ZenShadowCampaign.gd").read_text(encoding="utf-8")
abyss = (ROOT / "story/ZenAbyssCampaign.gd").read_text(encoding="utf-8")
controller = (ROOT / "ui/AscendController.gd").read_text(encoding="utf-8")
menu = (ROOT / "story/ZenRealmChallengeMenu.gd").read_text(encoding="utf-8")
assert 'ASSET_ROOT + "arenas/" + BOSS_IDS[index] + ".webp"' in shadow
assert 'ASSET_ROOT + "arenas/%s.webp" % BOSS_IDS[index]' in abyss
assert 'ASSET_ROOT + "gameplay.webp"' in abyss
assert 'Abyss.battle_backdrop(abyss_index)' in controller
assert 'Shadow.battle_backdrop(shadow_index)' in controller
assert 'Abyss.battle_backdrop()' in controller
assert 'res://assets/abyss_of_memories/gameplay.webp' in menu
if archive.exists():
    with zipfile.ZipFile(archive) as z:
        assert sorted(z.namelist()) == sorted(EXPECTED)
        assert z.testzip() is None
        for name, digest in EXPECTED.items():
            data = z.read(name)
            assert data[:4] == b"RIFF" and data[8:12] == b"WEBP", name
            assert hashlib.sha256(data).hexdigest() == digest, name
            assert (ROOT / name).read_bytes() == data, name
            print("OK:", name)
else:
    print("No final arena archive in this checkout; source mapping only.")
