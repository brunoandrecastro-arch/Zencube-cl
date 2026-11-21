#!/usr/bin/env python3
"""Guard cinematic Realm boss images and visible battle CTA without changing progression."""
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
code = (ROOT / "ui/AscendController.gd").read_text()
workflow = (ROOT / ".github/workflows/android.yml").read_text()
assert "func _realm_boss_intro_layout(parts: Dictionary) -> void:" in code
assert "frame.anchor_top = 0.035" in code and "frame.anchor_bottom = 0.965" in code
assert "get_viewport().get_visible_rect().size.y * 0.62,400.0,820.0" in code
assert 'launch.name = "RealmBossStartAction"' in code
for method, next_func, image in (
    ("_realm_story_present_intro","_realm_story_begin","_realm_story_art(body,stage,_realm_boss_portrait_height())"),
    ("_shadow_intro","_shadow_begin","_shadow_add_art(body,_realm_boss_portrait_height())"),
    ("_abyss_intro","_abyss_begin","_abyss_add_art(body,_realm_boss_portrait_height())"),
    ("_ember_intro","_ember_begin","_ember_add_art(body,_realm_boss_portrait_height())"),
):
    block = code.split("func " + method + "(",1)[1].split("func " + next_func + "(",1)[0]
    assert "_realm_boss_intro_layout(parts)" in block,method
    assert "_realm_boss_primary_action(parts," in block,method
    assert image in block,method
assert "STRETCH_KEEP_ASPECT_CENTERED" in code
assert "ZenCube-Chronicles-4.0.2.apk" in workflow
assert "python3 tests/test_realm_boss_portraits.py" in workflow
print("PASS: cinematic boss pictures in all four Realm entry points with pinned Play")
