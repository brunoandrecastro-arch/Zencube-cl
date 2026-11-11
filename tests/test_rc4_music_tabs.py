#!/usr/bin/env python3
"""ZenCube RC4: new MP3 soundtrack, persistent purchases, two shop tabs."""
from pathlib import Path
import ast, re
R=Path(__file__).resolve().parents[1]
ui=(R/'ui/GameController.gd').read_text(encoding='utf-8')
c=(R/'core/ZenCollection.gd').read_text(encoding='utf-8')
save=(R/'core/SaveManager.gd').read_text(encoding='utf-8')
l=(R/'core/ZenLocalization.gd').read_text(encoding='utf-8')
for name in ['cyberwave_main','zen_piano','velario_zen','nature_wonder','calm_spirit','zen_of_nature','sitar_story']:
    p=R/'assets/music'/f'{name}.mp3'
    b=p.read_bytes()
    assert len(b)>500000 and b[:3]==b'ID3' or len(b)>500000 and b[0]==255 and (b[1]&224)==224, p
    assert f'assets/music/{name}.mp3' in ui, name
assert '"music_track":7' in save, 'Cyberwave must be default for new players'
assert 'NEW_MUSIC_PRICES' in c and 'if (track >= 0 and track <= 4) or track == 7: return true' in c
assert 'music_price(track) > 0 and not music_owned.has(track)' in c
assert 'music_price(track) > 0 and data.economy.owned_music.has(track)' in c
assert 'func change_shop_tab(index: int)' in ui
assert 'if shop_tab == 1:' in ui and 'store_music_section(box)' in ui
assert 'music_preview_player.play()' in ui and 'create_timer(12.0)' in ui
assert 'func music_stream(track: int) -> AudioStream:' in ui
assert 'if not Collection.music_unlocked(data, index)' in ui
assert 'return make_zen_music_stream(track)' in ui, 'preserve legacy music'
assert 'clampi(index, 0, 13)' in ui
assert 'var music_names: Array' in ui
assert 'zen_ambient_music.pcm' in ui and 'zen_sternenlicht_music.pcm' in ui
assert 'if data.get("economy") is Dictionary: base.economy.merge(data.economy, true)' in save
assert 'store_select_music(track_id)' in ui
for lang in ('EN','PT'):
    sub=l.split(f'const {lang}: Dictionary = {{',1)[1].split('\n}',1)[0]
    translations=ast.literal_eval('{'+sub+'\n}')
    for key in ['Skins','Musik','▶ Probe hören (12 Sek.)','Hauptmusik · Kostenlos','Whispers of the Ancient Forest','Tales Beneath the Golden Sun']:
        assert key in translations and (translations[key] == key if key in {'Whispers of the Ancient Forest','Tales Beneath the Golden Sun'} else translations[key] != key),(lang,key)
    # A GDScript parse error would occur on duplicate localization keys.
    raw_keys=re.findall(r'^\s*"([^"\n]+)"\s*:',sub,re.M)
    assert len(raw_keys)==len(set(raw_keys)),(lang,'duplicate keys')
flow=(R/'.github/workflows/android.yml').read_text()
assert 'test_rc4_music_tabs.py' in flow and 'test_rc4_music_tabs.gd' in flow
print('OK: RC4 two tabs, 7 new MP3 files, new free main, 6 Zen Leaf unlocks, preview and old saves')
