#!/usr/bin/env python3
"""ZenCube 9.4.3: HD world assets and game-facing unlock/result clarity."""
from pathlib import Path
import ast
BASE=Path(__file__).resolve().parents[1]
ui=(BASE/'ui/GameController.gd').read_text()
r=(BASE/'ui/CubeRenderer.gd').read_text()
l=(BASE/'core/ZenLocalization.gd').read_text()
assert 'func world_unlock_info(world: int) -> String' in ui
assert 'var exam: int = world - 1' in ui
assert 'var needed: int = Asc.target(exam)' in ui
assert 'var done: int = Asc.progress(data, exam)' in ui
assert 'label(world_unlock_info(i), info' in ui
assert 'button("Rang & Fortschritt", box, open_ascension' in ui
assert 'Der Zen-Wächter ist die letzte Rangprüfung' in ui
assert 'You won as' not in ui and 'label("X gewinnt" if board.winner == 1 else "O gewinnt"' not in ui
assert 'label(summary, box' in ui
assert 'var winning_symbol:' in ui
assert 'viewport.size = Vector2i(960,960)' in ui
assert 'status.text = T("Du hast gewonnen!")' in ui
assert 'Neue Welt freigeschaltet: %s' in ui
assert 'var border_ring = MeshInstance3D.new()' in r
assert 'material(Color("fff0d1"),true)' in r
assert 'var peach = Color("16515a")' in r
assert 'Color("b68165")' in r
for name in ['zen_garden_scene.webp','zen_world_bamboo.webp','zen_world_temple.webp','zen_world_moon.webp','zen_world_heaven.webp']:
    pic=BASE/'assets'/name
    data=pic.read_bytes()
    assert data[:4]==b'RIFF' and data[8:16]==b'WEBPVP8 ', name
    at=data.index(b'\x9d\x01\x2a')+3
    width=int.from_bytes(data[at:at+2],'little')&0x3fff
    height=int.from_bytes(data[at+2:at+4],'little')&0x3fff
    assert (width,height)==(1440,2560),(name,width,height)
for code in ['EN','PT']:
    body=l.split(f'const {code}: Dictionary = {{',1)[1].split('\n}',1)[0]
    entries=ast.literal_eval('{'+body+'\n}')
    for key in ["Welten ändern nur das Aussehen. Dein Rang steigt durch Siege gegen den Zen-Bot.","Freischaltung: ","Rang & Fortschritt","Du hast als %s gewonnen.","Zen-Bot gewinnt mit %s."]:
        assert key in entries and entries[key] and entries[key]!=key,(code,key)
print('OK: 5x 1440x2560 worlds, unlock conditions, DE/EN/PT, correct result copy, contrast rings')
