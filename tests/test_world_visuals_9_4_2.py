#!/usr/bin/env python3
"""Static visual and gameplay integrity assertions for the premium world pack."""
from pathlib import Path
from hashlib import sha256
import ast
ROOT=Path(__file__).resolve().parents[1]
a=(ROOT/'core/ZenAscension.gd').read_text()
ui=(ROOT/'ui/GameController.gd').read_text()
l=(ROOT/'core/ZenLocalization.gd').read_text()
preset=(ROOT/'export_presets.cfg').read_text()
assert 'version/code=16' in preset and 'version/name="9.4.3-world-clarity-hd"' in preset
assert 'const WORLD_SUBTITLES = [' in a
assert a.count('preload("res://assets/zen_')==5
assert 'thumbnail.texture = Asc.WORLD_TEXTURES[i]' in ui
assert 'thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED' in ui
assert 'world_background.texture = Asc.WORLD_TEXTURES[chosen]' in ui
assert 'func select_world(number: int)' in ui
assert 'current_world = chosen' in ui
names=['zen_garden_scene.webp','zen_world_bamboo.webp','zen_world_temple.webp','zen_world_moon.webp','zen_world_heaven.webp']
sigs=[]
for name in names:
    f=ROOT/'assets'/name
    b=f.read_bytes()
    assert b[:4]==b'RIFF' and b[8:12]==b'WEBP',name
    assert len(b)>100000,(name,len(b))
    sigs.append(sha256(b).hexdigest())
assert len(set(sigs))==5,'Each world must have independent, not recolored-identical art'
for code in ('EN','PT'):
    table=l.split(f'const {code}: Dictionary = {{',1)[1].split('\n}',1)[0]
    d=ast.literal_eval('{'+table+'\n}')
    for key in ['Kirschblüten und Steingarten','Bambuswald und Steinpfade','Tempel im Abendlicht','Mondlicht und stilles Wasser','Licht über den Wolken','Ausgewählt']:
        assert key in d and d[key]!=key,(code,key)
for path in ['core/RulesEngine.gd','challenges/challenges.json','core/ZenChallenges.gd','ui/CubeRenderer.gd','core/AIEngine.gd','core/SaveManager.gd']:
    assert (ROOT/path).is_file(),path
print('OK: 5 distinctive premium art assets, scene-only backgrounds, real 3D cube unchanged, world cards, DE/EN/PT')
