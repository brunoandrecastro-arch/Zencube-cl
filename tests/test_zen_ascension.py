#!/usr/bin/env python3
"""9.4 static regression: five bots, worlds, progression, and save compatibility."""
from pathlib import Path
import ast, json, re
root=Path(__file__).resolve().parents[1]
ui=(root/'ui/GameController.gd').read_text()
ai=(root/'core/AIEngine.gd').read_text()
save=(root/'core/SaveManager.gd').read_text()
prog=(root/'core/ZenAscension.gd').read_text()
loc=(root/'core/ZenLocalization.gd').read_text()
assert 'const VERSION = 3' in save, 'MUST preserve old save version'
assert '"ai_wins":[0,0,0,0,0]' in save and '"ai_losses":[0,0,0,0,0]' in save
assert '"ascension":{"completed":[false,false,false,false,false]' in save
assert 'var branch_width: int = 8' in ai and '[0, 0, 2, 4, 5][level]' in ai
assert 'range(5)' in ui and 'func open_ascension()' in ui and 'func open_worlds()' in ui
assert 'Asc.clear_level(data, difficulty)' in ui and 'Asc.level_unlocked(data,i)' in ui
assert 'clampi(level,0,4)' in ui
assert 'zen_ambient_music.pcm' in ui
assert 'assets/*.pcm' in (root/'export_presets.cfg').read_text()
assert 'version/code=13' in (root/'export_presets.cfg').read_text()
for path in ('core/RulesEngine.gd','core/ZenChallenges.gd','challenges/challenges.json','ui/CubeRenderer.gd'):
 assert (root/path).is_file()
for code in ('EN','PT'):
 body=loc.split(f'const {code}: Dictionary = {{',1)[1].split('\n}',1)[0]
 d=ast.literal_eval('{'+body+'\n}')
 for key in ('Zen-Aufstieg','Zen-Rang','Welten','Meister','Zen-Wächter','Bergtempel','Himmelsgarten','Zen-Bot · Großmeister','Neuer Zen-Rang freigeschaltet!'):
  assert d.get(key),(code,key)
for name in ('bamboo','temple','moon','heaven'):
 f=root/f'assets/zen_world_{name}.webp';assert f.is_file()
 assert f.stat().st_size>120000 and f.read_bytes()[:4]==b'RIFF'
assert len(re.findall(r'preload\("res://assets/zen_',prog))==5
print('OK: ZenCube 9.4 five bot tiers, five worlds, five saved rank tiers, DE/EN/PT localization')
