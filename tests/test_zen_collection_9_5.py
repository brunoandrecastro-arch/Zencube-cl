#!/usr/bin/env python3
"""ZenCube 9.5: independent static checks for 20 visual skins, economy and 3 music tracks.
Godot tests also exercise gameplay and purchasing. Not a substitute for a device test.
"""
from pathlib import Path
import ast, re, math, struct
R=Path(__file__).resolve().parents[1]
s=(R/'core/ZenCollection.gd').read_text()
ui=(R/'ui/GameController.gd').read_text()
r=(R/'ui/CubeRenderer.gd').read_text()
save=(R/'core/SaveManager.gd').read_text()
workflow=(R/'.github/workflows/android.yml').read_text()
translations=(R/'core/ZenLocalization.gd').read_text()
assert s.count('const SKINS = [') == 1
assert s.count('\n]\n\nstatic func ensure(data: Dictionary) -> void:') == 1, 'Unclosed SKINS array in ZenCollection.gd'
extract=s.split('const SKINS = [',1)[1].split('\n]\n',1)[0]
records=re.findall(r'^\s*(\{.*\}),?\s*$',extract,re.M)
skins=[ast.literal_eval(record) for record in records]
assert len(skins)==20, len(skins)
assert len({skin['name'] for skin in skins})==20
assert len({tuple(skin['faces']) for skin in skins})==20
assert skins[0]['price']==0 and skins[0]['name']=='Klassischer Zen'
assert all(skins[i]['price'] > skins[i-1]['price'] for i in range(1,20))
for skin in skins:
    assert len(skin['faces'])==6
    for item in skin['faces']+[skin['core'],skin['x'],skin['o']]:
        assert re.fullmatch('[0-9a-f]{6}',item),item
    assert 0<=skin['metal']<=1 and 0<skin['rough']<=1
assert 'const BOT_REWARDS = [8, 15, 25, 40, 65]' in s
assert 'const CHALLENGE_REWARDS = [6, 10, 15, 25, 40]' in s
assert 'static func migrate_previous_rewards' in s
assert 'if bool(data.economy.migrated): return 0' in s
assert 'if skin < 1 or skin >= SKINS.size() or data.economy.owned.has(skin): return false' in s
assert 'var was_solved: bool = challenges.solved.has(str(challenge_index + 1))' in ui
assert 'if not was_solved:' in ui
assert 'if board.result_recorded: return' in ui
assert 'last_leaf_reward = Collection.reward_bot(data, difficulty)' in ui
assert 'renderer.apply_skin(skin)' in ui
assert 'renderer.apply_skin(int(data.economy.equipped))' in ui
assert 'var color = face_color(CubeGeometry.face(c))' in r
assert not any(line.startswith(' ') for line in r.splitlines()), 'CubeRenderer.gd mixes space indentation with existing tabs'
assert 'face_material(color)' in r
assert 'material(Color("fff0d1"),true)' in r
assert '"economy":{"leaves":0,"owned":[0],"equipped":0,"migrated":false}' in save
assert 'const VERSION = 3' in save, 'Migration must preserve existing saves'
assert 'if data.get("economy") is Dictionary: base.economy.merge(data.economy, true)' in save
assert 'include_filter="assets/*.pcm,challenges/*.json"' in (R/'export_presets.cfg').read_text()
assert 'version/code=18' in (R/'export_presets.cfg').read_text()
assert 'ZenCube 9.5 earned currency and 20 skins' in workflow
for name in ['zen_ambient_music.pcm','zen_bamboo_music.pcm','zen_moon_music.pcm']:
    audio=(R/'assets'/name).read_bytes()
    assert len(audio)>300_000 and len(audio)%2==0
    # Check reasonable playback loudness on original and new files.
    raw=struct.unpack('<'+str(len(audio)//2)+'h',audio)
    rms=math.sqrt(sum(v*v for v in raw)/len(raw))
    db=20*math.log10(rms/32768)
    assert -27<db<-8,(name,db)
for code in ['EN','PT']:
    translations_section=translations.split(f'const {code}: Dictionary = {{',1)[1].split('\n}',1)[0]
    t=ast.literal_eval('{'+translations_section+'\n}')
    for skin in skins: assert skin['name'] in t, (code,skin['name'])
    for key in ['Zen-Shop','Kaufen für 🍃 %d','Musiktitel','Mondlicht am Teich']:
        assert key in t and t[key], (code,key)
print('OK: 20 independent palette/material skins, 3 music tracks, earned-only currency, saved progress, DE/EN/PT')
