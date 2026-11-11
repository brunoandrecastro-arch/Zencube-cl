#!/usr/bin/env python3
"""RC5 smoke check: seven licensed-source audio IDs retained, creative titles and rank 3 gate."""
from pathlib import Path
import ast, re
ROOT = Path(__file__).resolve().parents[1]
ui = (ROOT/'ui/GameController.gd').read_text(encoding='utf-8')
mode = (ROOT/'core/ZenAscend.gd').read_text(encoding='utf-8')
ai = (ROOT/'core/AIEngine.gd').read_text(encoding='utf-8')
locale = (ROOT/'core/ZenLocalization.gd').read_text(encoding='utf-8')
expected = [
    'Whispers of the Ancient Forest',
    'Echoes of a Forgotten Dream',
    'The Path of Serenity',
    'Where the Waters Sleep',
    'Spirit of the Jade River',
    'A Thousand Silent Skies',
    'Tales Beneath the Golden Sun',
]
m = re.search(r'^const NEW_MUSIC_TITLES = (\[.*\])$', ui, re.M)
assert m is not None, 'missing music title array'
assert ast.literal_eval(m.group(1)) == expected, 'unexpected song order; old purchases depend on numeric IDs'
assert '[7, 0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13]' in ui
assert '"music_track":7' in (ROOT/'core/SaveManager.gd').read_text(), 'Cyberwave track ID 7 must remain default'
assert 'if shop_tab == 1:' in ui and 'store_music_section(box)' in ui
for code in ('EN', 'PT'):
    body = locale.split(f'const {code}: Dictionary = {{', 1)[1].split('\n}', 1)[0]
    dictionary = ast.literal_eval('{'+body+'\n}')
    raw_keys = re.findall(r'^\s*"([^"\n]+)"\s*:', body, re.M)
    assert len(set(raw_keys)) == len(raw_keys), code + ' duplicate translation keys'
    for title in expected:
        assert dictionary[title] == title, f'{code} changed soundtrack title: {title}'
    assert dictionary['Überarbeitete Bot-Stufen: Mittel fairer, Meister anspruchsvoll und schlagbar.']
assert 'const TEST_UNLOCKED: bool = true' in mode, 'internal test must remain playable without grind'
assert 'static func unlocked_for_release(data: Dictionary)' in mode
assert 'get("rank",0)) >= 3' in mode, 'production unlock must start at Zen Meister rank (3)'
assert 'if unlocked_for_release(data): return false' in mode, 'already earned mode must not charge leaves'
assert 'rank_after == 3' in ui and 'Zen Ascend freigeschaltet!' in ui
assert 'var block_probability: float = [0.70, 0.66, 0.88, 0.91, 1.0][level]' in ai
assert 'level == 1 and rng.randf() < 0.62' in ai
assert 'level == 3 and rng.randf() < 0.24' in ai
assert 'if placed <= 3 or rng.randf() < block_probability: return blocks[0]' in ai
assert 'func search(' in ai and '[0, 0, 2, 4, 5][level]' in ai, 'original advanced bot structure must remain'
print('RC5 PASS: seven fantasy titles, consistent DE/EN/PT, stable music ID, Zen Meister release unlock, test access and friendly bot tiers')
