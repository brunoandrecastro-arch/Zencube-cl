#!/usr/bin/env python3
"""Modify only generated Godot Texture2D import sidecars; leave art/audio untouched."""
import json, re, sys
from pathlib import Path
ROOT = Path.cwd()
STATE = ROOT / 'build/hd-import-state.json'

def destination(text):
    paths = set(re.findall(r'"res://(\.godot/imported/[^"\n]+\.ctex)"', text))
    assert len(paths) == 1, paths
    return ROOT / next(iter(paths))

def eligible(path):
    rel = path.relative_to(ROOT).as_posix().lower()
    if not rel.endswith(('.png.import', '.webp.import', '.jpg.import', '.jpeg.import')):
        return False
    if any(x in rel for x in ('/skins/', '/icons/', '/materials/', '/textures/', '/cards/')):
        return False
    return ((rel.startswith('story/act') and '/pages/' in rel)
            or (rel.startswith('assets/') and any(x in rel for x in ('/pages/', '/arenas/', '/bosses/'))))

mode = sys.argv[1]
if mode == 'prepare':
    records = []
    for directory in ('assets', 'story'):
        for sidecar in sorted((ROOT/directory).rglob('*.import')):
            if not eligible(sidecar): continue
            text = sidecar.read_text()
            if 'importer="texture"' not in text or not re.search(r'^compress/mode=0$', text, re.M): continue
            if not re.search(r'^compress/lossy_quality=', text, re.M): continue
            dest = destination(text)
            assert dest.is_file(), str(dest)
            quality = '0.92' if '/pages/' in sidecar.as_posix() else '0.94'
            new = re.sub(r'^compress/mode=0$', 'compress/mode=1', text, flags=re.M)
            new = re.sub(r'^compress/lossy_quality=.*$', 'compress/lossy_quality='+quality, new, flags=re.M)
            new = re.sub(r'^detect_3d/compress_to=.*$', 'detect_3d/compress_to=0', new, flags=re.M)
            records.append({'sidecar': str(sidecar.relative_to(ROOT)), 'before': dest.stat().st_size})
            sidecar.write_text(new)
            dest.unlink()  # missing import output forces a fresh import
            dest.with_suffix('.md5').unlink(missing_ok=True)
    assert len(records) >= 40, 'Too few selected textures; check extracted media'
    STATE.parent.mkdir(exist_ok=True)
    STATE.write_text(json.dumps(records))
    print('Selected', len(records), '2D textures; original source files unchanged')
elif mode == 'verify':
    records = json.loads(STATE.read_text())
    for row in records:
        p = ROOT/row['sidecar']; text = p.read_text()
        assert re.search(r'^compress/mode=1$', text, re.M), str(p)
        dest = destination(text)
        assert dest.is_file(), str(dest)
        row['after'] = dest.stat().st_size
    STATE.write_text(json.dumps(records))
    before = sum(r['before'] for r in records); after = sum(r['after'] for r in records)
    print(f'Imported textures: {before:,} -> {after:,} bytes')
    assert after < before, 'Optimization did not reduce selected texture bytes'
elif mode == 'exclude':
    p = ROOT/'export_presets.cfg'; text=p.read_text()
    old='exclude_filter="tests/*,reports/*,build/*,.github/*,legacy_reports_120/*"'
    assert text.count(old)==1
    new=old[:-1]+',docs/*,play_store/*,scripts/*,*.bak,*.zip,.zencube_backups/*"'
    p.write_text(text.replace(old,new,1))
else:
    raise SystemExit('Expected prepare, verify or exclude')
