#!/usr/bin/env python3
from pathlib import Path
import struct
import hashlib
P=Path(__file__).resolve().parents[1]
files=['zen_garden_scene.webp','zen_world_bamboo.webp','zen_world_temple.webp','zen_world_moon.webp','zen_world_heaven.webp']
sha=[]
for name in files:
    data=(P/'assets'/name).read_bytes()
    assert data[:4]==b'RIFF' and data[8:16]==b'WEBPVP8 ',name
    pos=data.index(b'\x9d\x01\x2a')+3
    dims=(int.from_bytes(data[pos:pos+2],'little')&16383,int.from_bytes(data[pos+2:pos+4],'little')&16383)
    assert dims==(1440,2560),(name,dims)
    sha.append(hashlib.sha256((P/'assets'/name).read_bytes()).hexdigest())
assert len(set(sha))==5
sizes=[];hashes=[]
for i in range(20):
    f=P/'assets'/'skins'/('skin_%02d.webp'%i)
    data=f.read_bytes()
    assert data[:4]==b'RIFF' and data[8:16]==b'WEBPVP8 ',i
    pos=data.index(b'\x9d\x01\x2a')+3
    dims=(int.from_bytes(data[pos:pos+2],'little')&16383,int.from_bytes(data[pos+2:pos+4],'little')&16383)
    assert dims==(512,512),(i,dims)
    sizes.append(f.stat().st_size)
    hashes.append(hashlib.sha256(f.read_bytes()).hexdigest())
assert len(set(hashes))==20
r=(P/'ui/CubeRenderer.gd').read_text()
for part in ['load_surface_textures()', 'mat.albedo_texture = surface_textures[skin_id]','BaseMaterial3D.TRANSPARENCY_ALPHA','glass_color.a = 0.55','Color("08788c")']:
    assert part in r,part
u=(P/'ui/GameController.gd').read_text()
assert 'material_thumb.texture = load("res://assets/skins/skin_%02d.webp" % i)' in u
c=(P/'core/ZenCollection.gd').read_text()
assert 'const MATERIALS = [' in c and c.count('const SKINS = [')==1
print('OK: 5 new 1440x2560 landscape images, 20 textured materials, glass transparency, X/O contrast, shop material previews')
