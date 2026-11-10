#!/usr/bin/env python3
"""ZenCube 9.6.1: real texture resolution, audio, mobile scroll and persistent IDs."""
from pathlib import Path
import struct, math, ast, hashlib, array
BASE=Path(__file__).resolve().parents[1]
ui=(BASE/'ui/GameController.gd').read_text()
renderer=(BASE/'ui/CubeRenderer.gd').read_text()
collection=(BASE/'core/ZenCollection.gd').read_text()
loc=(BASE/'core/ZenLocalization.gd').read_text()
workflow=(BASE/'.github/workflows/android.yml').read_text()

skin_hashes=[]
for i in range(20):
    data=(BASE/'assets/skins'/('skin_%02d.webp'%i)).read_bytes()
    assert data[:4]==b'RIFF' and data[8:16]==b'WEBPVP8 ',i
    offset=data.index(b'\x9d\x01\x2a')+3
    dims=(int.from_bytes(data[offset:offset+2],'little')&0x3fff,int.from_bytes(data[offset+2:offset+4],'little')&0x3fff)
    assert dims==(1024,1024),(i,dims)
    skin_hashes.append(hashlib.sha256(data).hexdigest())
assert len(set(skin_hashes))==20
assert 'var brightness: float = color.get_luminance()' in renderer
assert 'var x_main: Color' in renderer and 'var o_main: Color' in renderer
assert 'mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC' in renderer
assert 'var shop_page: int = 0' in ui
assert 'func change_shop_page(delta: int) -> void' in ui
assert 'range(shop_page * 5, mini((shop_page + 1) * 5, Collection.SKINS.size()))' in ui
assert 'scroll.scroll_deadzone = 12' in ui
assert 'skin_button.mouse_filter = Control.MOUSE_FILTER_PASS' in ui
assert 'skin_button.add_theme_color_override("font_disabled_color", Color("42372d"))' in ui
assert 'for title in ["Zen-Garten (Original)", "Klangschalen – Stiller Tempel", "Handpan – Sanfter Rhythmus", "Shakuhachi – Nebelpfad", "Koto – Sternengarten"]:' in ui
assert 'const SKINS = [' in collection and collection.count('"price":')==20
assert 'version/code=20' in (BASE/'export_presets.cfg').read_text()
assert 'version/name="1.0.0-rc1"' in (BASE/'export_presets.cfg').read_text()
assert 'Verify 9.6.1 high-resolution surfaces' in workflow

waves=[]
for name in ['zen_bamboo_music.pcm','zen_moon_music.pcm']:
    data=(BASE/'assets'/name).read_bytes()
    assert len(data)==16000*64*2,(name,len(data))
    samples=array.array('h')
    samples.frombytes(data)
    rms=math.sqrt(sum(v*v for v in samples)/len(samples))/32768
    assert -26 < 20*math.log10(rms) < -15,(name,rms)
    assert max(abs(v) for v in samples)<32767,name
    assert len(set(samples[::50]))>100,('audio must contain textured audio',name)
    waves.append(data)
assert waves[0]!=waves[1]
assert (BASE/'assets'/'zen_ambient_music.pcm').exists(), 'Original zen soundtrack not modified'
for lang in ('EN','PT'):
    data=loc.split(f'const {lang}: Dictionary = {{',1)[1].split('\n}',1)[0]
    entries=ast.literal_eval('{'+data+'\n}')
    for key in ['Klangschalen – Stiller Tempel','Handpan – Sanfter Rhythmus','Vorherige Skins','Weitere Skins','Seite %d von 4']:
        assert entries.get(key) and entries[key]!=key,(lang,key)
print('OK: 20 crisp 1024px materials, 2 original 64s audio tracks, 5-card swipe-friendly store, contrast and three languages')
