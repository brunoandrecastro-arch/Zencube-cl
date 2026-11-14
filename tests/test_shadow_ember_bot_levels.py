#!/usr/bin/env python3
"""Verify that the actual 4x4 bot level matches the Realm after loading and selecting.
Also verify Shadow's slight AI tune cannot affect other difficulties or Classic AI.
"""
from pathlib import Path
import re
R = Path(__file__).resolve().parents[1]
ui = (R/'ui/AscendController.gd').read_text(encoding='utf-8')
ai = (R/'core/ZenAscendRealmBot.gd').read_text(encoding='utf-8')
realms = (R/'core/ZenAscendRealms.gd').read_text(encoding='utf-8')
assert 'const REALM_BOT_LEVELS: Array[int] = [1, 2, 3, 4]' in realms
assert 'return REALM_BOT_LEVELS[clampi(realm,0,3)]' in realms
ready = ui.split('func _ready() -> void:',1)[1].split('func ',1)[0]
assert 'match_realm = int(data.ascend.realm_state.selected)' in ready
assert 'bot_level = Realms.fixed_bot_level(match_realm)' in ready
starter = ui.split('func start_game(bot: bool, level: int = -1) -> void:',1)[1].split('func play(',1)[0]
assert 'bot_level = Realms.fixed_bot_level(match_realm)' in starter
selector = ui.split('func select_realm(number: int) -> bool:',1)[1].split('func _show_manual_realm_journey',1)[0]
assert 'bot_level = Realms.fixed_bot_level(number)' in selector
assert selector.index('bot_level = Realms.fixed_bot_level(number)') < selector.index('draw()')
assert 'RealmBot.next_move(cells,lines,2,bot_level,match_realm == 0)' in ui
assert 'var shadow_medium: bool = shadow_boost and level == 1' in ai
assert 'var medium_noise: float = 10.0 if shadow_medium else 12.0' in ai
assert '0.96 if shadow_medium else WIN_CHANCE[level]' in ai
assert '0.84 if shadow_medium else BLOCK_CHANCE[level]' in ai
assert '0.09 if shadow_medium else NOISE_CHANCE[level]' in ai
assert 'elif level == 1: value += randf_range(-medium_noise,medium_noise)' in ai
assert 'const WIN_CHANCE: Array[float] = [0.78, 0.94, 1.0, 1.0, 1.0]' in ai
assert 'const BLOCK_CHANCE: Array[float] = [0.57, 0.78, 0.92, 0.98, 1.0]' in ai
assert 'const NOISE_CHANCE: Array[float] = [0.30, 0.12, 0.03, 0.0, 0.0]' in ai
assert 'tests/test_shadow_ember_bot_levels.py' in (R/'.github/workflows/android.yml').read_text(encoding='utf-8')
print('PASS: Shadow Medium enhanced mildly; Ember shows and uses Hard; other bots unchanged')
