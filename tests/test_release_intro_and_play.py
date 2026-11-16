#!/usr/bin/env python3
"""Release intro QA: the actual cube is shown at first launch; Play hides debug skips."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
ui=(root/"ui/GameController.gd").read_text(encoding="utf-8")
mode=(root/"core/ZenAscend.gd").read_text(encoding="utf-8")
story=(root/"story/ZenRealmChronicles.gd").read_text(encoding="utf-8")
p=(root/"export_presets.cfg").read_text(encoding="utf-8")
build=(root/"scripts/build_play_aab.sh").read_text(encoding="utf-8")
assert 'func _zen_onboarding_hero(parent: VBoxContainer, selected_language: String = "") -> void:' in ui
assert 'live_cube.texture = viewport.get_texture()' in ui, "real Godot rendered cube, not a static wallpaper"
assert 'live_cube.mouse_filter = Control.MOUSE_FILTER_IGNORE' in ui
assert '千里の道も一歩から' in ui
for t in ("Senri no michi mo ippo kara","Jeder große Weg beginnt mit einem einzigen Schritt.",
          "Every great journey begins with a single step.","Toda a grande jornada começa com um único passo."):
    assert t in ui, t
intro=ui.split('func open_language_choice()',1)[1].split('func _ready()',1)[0]
assert intro.index('_zen_onboarding_hero(box)') < intro.index('button("Deutsch"')
welcome=ui.split("func open_welcome()",1)[1].split("func add_rule_example(",1)[0]
assert '_zen_onboarding_hero(box,language_code())' in welcome
assert welcome.index('button("Mini-Tutorial starten"') < welcome.index('add_rule_example(')
assert 'return OS.has_feature("debug") and bool(ProjectSettings.get_setting("application/config/realm_chronicles_qa",false))' in mode
assert 'return OS.has_feature("debug") and bool(ProjectSettings.get_setting("application/config/realm_chronicles_qa",false))' in story
assert "realm_chronicles_qa" not in (root/"project.godot").read_text(encoding="utf-8")
assert 'package/unique_name="com.zencube.game.play"' in p.split("[preset.1.options]",1)[1]
assert "assert \"realm_chronicles_qa\" not in project" in build
print("PASS: live 3D start, JP quote + 3 languages, release gate, no QA shortcut in Play")
