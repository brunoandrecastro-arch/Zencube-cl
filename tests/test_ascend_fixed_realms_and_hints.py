#!/usr/bin/env python3
"""ZenCube fixed 4x4 Realms / menu / secret achievements smoke checks."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
ui=(root/'ui/AscendController.gd').read_text(encoding='utf-8')
realm=(root/'core/ZenAscendRealms.gd').read_text(encoding='utf-8')
ach=(root/'core/ZenAscendAchievements.gd').read_text(encoding='utf-8')
shop=(root/'ui/GameController.gd').read_text(encoding='utf-8')
assert 'const REALM_BOT_LEVELS: Array[int] = [1, 2, 3, 4]' in realm
assert 'bot_level = Realms.fixed_bot_level(match_realm)' in ui
assert 'var fixed_level: int = Realms.fixed_bot_level(realm_index())' in ui
assert 'for i in range(5):' not in ui.split('func show_mode_picker() -> void:',1)[1].split('func _start_realm_match',1)[0]
assert 'Zen Ascend Bot · ' in ui
assert 'menu_button: Button = action(header_row,"☰",show_ascend_menu)' in ui
assert 'action(footer,Z("Hauptmenü")' not in ui
assert 'func realm_quote() -> String:' in ui and 'quote_label.text = realm_quote()' in ui
finish=ui.split('func finish() -> void:',1)[1].split('func _show_next_unlock()',1)[0]
assert 'Realms.count(data,match_realm) == 8' in finish
assert 'auto_transitions' in finish
assert 'previously_open' not in finish
assert 'HINT_PRICE: int = 50' in ach
assert 'purchased_hints' in ach
assert 'if not exists or earned(data,key) or hint_owned(data,key): return false' in ach
assert 'shop_tab == 3' in shop and 'store_hint_section(box)' in shop
assert 'if revealed:' in ui
assert 'str(secret.quote)' in ui.split('if revealed:',1)[1]
assert 'str(secret.condition)' in ui.split('if revealed:',1)[1]
detail = ui.split('func _show_achievement_details(', 1)[1].split('func show_match_result()', 1)[0]
revealed = detail.split('    if revealed:', 1)[1].split('    else:', 1)[0]
hidden = detail.split('    else:', 1)[1].split('    action(body,_achievements_label()', 1)[0]
assert 'How to unlock: ' in revealed
assert 'How to unlock: ' not in hidden
assert 'Unlock condition hidden' in hidden
assert 'const VERSION = 3' in (root/'core/SaveManager.gd').read_text()
assert 'ZenCollection.reward_loss(data)' in ui
print('PASS: fixed bot 1/2/3/4, 8/8 auto transitions, secret paid hints, premium menu, quotes, legacy safety')
