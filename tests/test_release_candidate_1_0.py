#!/usr/bin/env python3
"""Release candidate static checks: Play metadata, icon, 5 loops, language availability."""
from pathlib import Path
import struct, wave, math, re, array, hashlib
R=Path(__file__).resolve().parents[1]
ui=(R/'ui/GameController.gd').read_text();loc=(R/'core/ZenLocalization.gd').read_text();exp=(R/'export_presets.cfg').read_text()
assert 'package/unique_name="com.zencube.game"' in exp, 'Never change app ID'
assert 'version/code=20' in exp and 'version/name="1.0.0-rc1"' in exp
assert 'name="Android Play"' in exp and 'gradle_build/target_sdk=36' in exp
assert 'gradle_build/export_format=1' in exp and 'gradle_build/use_gradle_build=true' in exp
assert 'config/icon="res://icon.svg"' in (R/'project.godot').read_text()
assert 'config/name="ZenCube 3D"' in (R/'project.godot').read_text()
assert 'clampi(index, 0, 4)' in ui
assert 'clampi(int(data.settings.get("music_track", 0)), 0, 4)' in ui
for track,name in enumerate(['zen_ambient_music.pcm','zen_bamboo_music.pcm','zen_moon_music.pcm','zen_flute_music.pcm','zen_koto_music.pcm']):
 path=R/'assets'/name
 b=path.read_bytes()
 assert len(b)>=300_000 and len(b)%2==0,(track,name,len(b))
 assert name in ui,(track,name)
 x=array.array('h'); x.frombytes(b)
 rms=math.sqrt(sum(v*v for v in x[::20])/len(x[::20]))/32768
 db=20*math.log10(rms)
 assert -27<db<-9,(name,db)
for key in ('Shakuhachi – Nebelpfad','Koto – Sternengarten'):
 for lang in ('EN','PT'):
  section=loc.split(f'const {lang}: Dictionary = {{',1)[1].split('\n}',1)[0]
  assert '"'+key+'"' in section, (lang,key)
for filename,size in [('zencube_launcher_192.png',192),('zencube_adaptive_background_432.png',432),('zencube_adaptive_foreground_432.png',432),('zencube_adaptive_monochrome_432.png',432)]:
 b=(R/'assets/icons'/filename).read_bytes();assert b[:8]==b'\x89PNG\r\n\x1a\n'
 dims=struct.unpack('>II',b[16:24]);assert dims==(size,size),(filename,dims)
assert 'ZenCube 3D: Calm Strategy' in (R/'play_store/STORE_LISTING_EN_DE.md').read_text()
assert len('ZenCube 3D: Calm Strategy')<=30
assert (R/'play_store/zencube_store_icon_512.png').exists()
assert (R/'play_store/zencube_feature_1024x500.png').exists()
print('OK: 5 selectable original music tracks, minimal launcher/adaptive icons, Play version, bilingual listing & API36 export preset')
