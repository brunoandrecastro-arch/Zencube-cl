#!/usr/bin/env python3
"""Static protection for Music Shop RC2; real Godot behavior tested separately."""
from pathlib import Path
import array, math, ast
R=Path(__file__).resolve().parents[1]
ui=(R/'ui/GameController.gd').read_text()
coll=(R/'core/ZenCollection.gd').read_text()
loc=(R/'core/ZenLocalization.gd').read_text()
flow=(R/'.github/workflows/android.yml').read_text()
save=(R/'core/SaveManager.gd').read_text()
assert 'const MUSIC_PRICES: Dictionary = {5: 120, 6: 180}' in coll
for key in ['music_price(', 'music_unlocked(', 'buy_music(', 'owned_music', 'wallet["owned_music"] = music_owned', 'if price <= 0 or int(data.economy.leaves) < price: return false']:
 assert key in coll, key
assert 'if data.get("economy") is Dictionary: base.economy.merge(data.economy, true)' in save
assert 'var music_names: Array' in ui and 'tracks.add_item(display, i)' in ui and 'if not Collection.music_unlocked(data, i):' in ui, 'settings show Base + owned tracks'
assert 'func store_music_section(' in ui and 'func store_select_music(' in ui
assert 'store_music_section(box)' in ui and 'change_shop_tab(1)' in ui
assert 'if not Collection.music_unlocked(data, index):' in ui
assert 'Collection.buy_music(data, track)' in ui
assert 'data.settings.music = true' in ui
assert 'clampi(index, 0, 13)' in ui
assert 'clampi(int(data.settings.get("music_track", 7)), 0, 13)' in ui
assert 'version/code=21' in (R/'export_presets.cfg').read_text()
assert 'test_music_shop_1_0_rc2.gd' in flow
for lang in ['EN','PT']:
 body=loc.split(f'const {lang}: Dictionary = {{',1)[1].split('\n}',1)[0]
 translations=ast.literal_eval('{'+body+'\n}')
 for k in ['Nebelpfad','Stein und Wasser','Regentropfen im Zen-Garten','Sternenlicht am Tempel','Freischaltbare Musik','Musik freischalten für 🍃 %d','Musik auswählen']:
  assert k in translations and translations[k] != k,(lang,k)
for name in ['zen_ambient_music.pcm','zen_bamboo_music.pcm','zen_moon_music.pcm','zen_flute_music.pcm','zen_koto_music.pcm','zen_regentropfen_music.pcm','zen_sternenlicht_music.pcm']:
 f=R/'assets'/name
 b=f.read_bytes()
 assert len(b)>500000 and len(b)%2==0,(name,len(b))
 a=array.array('h');a.frombytes(b); small=a[::20]
 db=20*math.log10(math.sqrt(sum(v*v for v in small)/len(small))/32768)
 assert -27 < db < -9,(name,db)
assert 'assets/*.pcm' in (R/'export_presets.cfg').read_text()
print('OK: 7 music tracks, 2 earned-leaf unlocks, translation, persistence and robust selection')
