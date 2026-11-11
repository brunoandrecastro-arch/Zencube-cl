#!/usr/bin/env python3
"""ZenCube 9.3 UI regression: source contracts, not a substitute for Godot tests."""
from pathlib import Path
import ast
p=Path(__file__).resolve().parents[1]
ui=(p/'ui/GameController.gd').read_text()
save=(p/'core/SaveManager.gd').read_text()
loc=(p/'core/ZenLocalization.gd').read_text()
exp=(p/'export_presets.cfg').read_text()
for phrase in ('func premium_button(', 'func open_play_menu()', 'func show_result_screen()',
    'popup.anchor_top = 0.51', 'func vibrate_on_move()', 'Input.vibrate_handheld(22)',
    'call_deferred("show_result_screen")', 'premium_button("Spielen", box, open_play_menu',
    'premium_button("Noch eine Partie", box,', 'premium_button("Hauptmenü", box, open_menu)'):
    assert phrase in ui, phrase
assert '"haptics":true' in save and 'const VERSION = 3' in save
assert 'permissions/vibrate=true' in exp
assert 'version/code=21' in exp and 'version/name="1.0.0-rc2-music-shop"' in exp
for code in ('EN','PT'):
    src=loc.split('const '+code+': Dictionary = {',1)[1].split('\n}',1)[0]
    entries=ast.literal_eval('{'+src+'\n}')
    for key in ('Hauptmenü','Spielmodus','Zen erreicht!','Noch eine Partie',
                'Vibration bei Spielzügen','Vier in einer Reihe. Über die Kante.'):
        assert entries.get(key), (code,key)
print('OK: premium menu, result flow, haptics and three-language copy in source')
