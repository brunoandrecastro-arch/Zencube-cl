#!/usr/bin/env python3
"""Derived menu artwork only. Source images and archives remain byte-identical."""
from pathlib import Path
from PIL import Image
root = Path("assets/hd_menu_previews")
root.mkdir(parents=True, exist_ok=True)
paths = [
    "assets/realms/shadow_realm.webp",
    "assets/abyss_of_memories/gameplay.webp",
    "assets/ember_campaign/realm.webp",
    "assets/realms/ember_temple.webp",
    "assets/realms/celestial_realm.webp",
    "assets/satori_campaign/realm.webp",
    "assets/shattered_moon/realm.webp",
    "assets/sky_garden/realm.webp",
]
for source in paths:
    path = Path(source)
    if not path.is_file():
        raise SystemExit(f"Missing source for menu preview: {path}")
    dest = root / (source.rsplit('.',1)[0].replace('/','_') + '.webp')
    with Image.open(path) as original:
        image = original.convert("RGB")
        image.thumbnail((960,960), Image.Resampling.LANCZOS)
        image.save(dest, "WEBP", quality=90, method=6)
    print(dest, dest.stat().st_size)
