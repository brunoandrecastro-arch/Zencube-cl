#!/usr/bin/env python3
"""Do not ship low-resolution Celestial / Satori card art in a Google Play AAB."""
from pathlib import Path
import hashlib, sys
root=Path(__file__).resolve().parents[1]
names=("wind_scribe","bridge_sentinel","sky_archivist","lotus_witness","halo_keeper","fully_aware")
missing=[]
for name in names:
    file=root/"assets"/"realm_chronicles"/("boss_"+name+"_hd.webp")
    if not file.is_file():
        missing.append(file.relative_to(root).as_posix())
        continue
    payload=file.read_bytes()
    assert len(payload)>50_000, f"Low detail WebP: {file.name}"
    assert payload[:4]==b"RIFF" and payload[8:12]==b"WEBP", f"Invalid WebP: {file.name}"
    print(file.name,len(payload),hashlib.sha256(payload).hexdigest())
if "--release" in sys.argv and missing:
    raise SystemExit("Release blocked: install all six original HD boss images:\n"+"\n".join(missing))
print("HD ART:", "6/6 installed" if not missing else str(6-len(missing))+"/6 installed (draft)")
