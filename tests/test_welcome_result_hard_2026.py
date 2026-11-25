#!/usr/bin/env python3
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
ui = (ROOT/'ui/GameController.gd').read_text(encoding='utf-8')
ai = (ROOT/'core/AIEngine.gd').read_text(encoding='utf-8')
assert 'func allow_welcome_scroll(node: Node)' in ui
assert 'welcome_scroll.scroll_deadzone = 0' in ui
assert 'welcome_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS' in ui
welcome = ui.split('func open_welcome() -> void:',1)[1].split('func add_rule_example(',1)[0]
assert welcome.index('button("Mini-Tutorial starten"') < welcome.index('add_rule_example(box,"3 + 1",3)')
assert welcome.index('button("Zum Hauptmenü"') < welcome.index('add_rule_example(box,"3 + 1",3)')
startup = ui.split('func _ready() -> void:',1)[1].split('func theme_style(',1)[0]
assert 'open_welcome()' not in startup, 'Long help is available on demand, not forced at launch'
assert 'open_menu()' in startup
assert 'var tagline = label("Ein ruhiges Strategiespiel' not in ui
result = ui.split('func show_result_screen() -> void:',1)[1].split('func play_again_after_result()',1)[0]
assert 'Entdecke neue Wege.' not in result
assert 'var detail_label' not in result
assert '_hd_result_shell(outcome_title, subtitle)' in result
assert 'premium_button("Noch eine Partie"' in result
assert 'premium_button("Hauptmenü"' in result
assert '[0.70, 0.66, 0.75, 0.91, 1.0][level]' in ai
assert 'if level == 2 and rng.randf() < 0.38' in ai
assert 'return soft_choice(order, [], 6)' in ai
print('OK: Touch-scroll intro, immediate start buttons, compact result, softer Classic Hard')

assert 'popup.name = "HDResultScreen"' in ui
assert 'hero.name = "HDLiveResultCube"' in ui
assert 'hero.texture = viewport.get_texture()' in ui
assert 'column.hide()' in ui.split(
    'func _hd_result_shell(', 1
)[1].split('\nfunc ', 1)[0]
