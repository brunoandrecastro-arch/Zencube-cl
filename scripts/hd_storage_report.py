#!/usr/bin/env python3
import json, sys, os, zipfile
from collections import defaultdict
from pathlib import Path
if sys.argv[1] == 'compare':
    folder=Path(sys.argv[2])
    a=json.loads((folder/'hd-size-baseline.json').read_text())
    b=json.loads((folder/'hd-size-optimized.json').read_text())
    assert a['commit']==b['commit'], 'Different commits cannot be compared'
    delta=a['apk_bytes']-b['apk_bytes']; pct=100*delta/a['apk_bytes']
    lines=['# Zen Cube 3D HD – Storage comparison', '',
           f"Baseline APK: {a['apk_bytes']/1e6:.2f} MB ({a['apk_bytes']:,} bytes)",
           f"Optimized APK: {b['apk_bytes']/1e6:.2f} MB ({b['apk_bytes']:,} bytes)",
           f'Saved: {delta/1e6:.2f} MB ({pct:.2f}%)', '',
           '| APK category | Baseline MB | Optimized MB |', '|---|---:|---:|']
    for k in sorted(set(a['categories'])|set(b['categories'])):
        lines.append(f"| {k} | {a['categories'].get(k,0)/1e6:.2f} | {b['categories'].get(k,0)/1e6:.2f} |")
    lines += ['', 'Sizes are actual APK file sizes, not installed disk or RAM usage.', 'Audio files and original images were not modified.']
    out='\n'.join(lines)+'\n'; print(out)
    (folder/'comparison.md').write_text(out)
    if os.environ.get('GITHUB_STEP_SUMMARY'):
        with open(os.environ['GITHUB_STEP_SUMMARY'],'a') as f: f.write(out)
    raise SystemExit(0)
p=Path(sys.argv[1]); variant=sys.argv[2]; groups=defaultdict(int)
with zipfile.ZipFile(p) as z:
    for i in z.infolist():
        n=i.filename.lower()
        if n.endswith('.ctex'): group='Godot textures'
        elif n.endswith(('.oggvorbisstr','.mp3str','.sample','.wav','.pcm','.ogg','.mp3')): group='Audio'
        elif n.startswith('lib/'): group='Native libraries'
        elif n.endswith(('.png','.webp','.jpg','.jpeg')): group='Raw images'
        elif n.endswith('.zip'): group='ZIP archives'
        else: group='Other'
        groups[group]+=i.compress_size
r={'variant':variant,'commit':os.environ.get('GITHUB_SHA','local'),'apk_bytes':p.stat().st_size,'categories':dict(groups)}
state=Path('build/hd-import-state.json')
if state.exists():
    rows=json.loads(state.read_text()); r['changed_textures']=len(rows); r['texture_before_bytes']=sum(x['before'] for x in rows); r['texture_after_bytes']=sum(x['after'] for x in rows)
Path(f'build/hd-size-{variant}.json').write_text(json.dumps(r,indent=2))
print(json.dumps(r,indent=2))
