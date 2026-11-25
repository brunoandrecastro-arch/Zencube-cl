#!/usr/bin/env python3
"""Guard cinematic Realm boss images and visible battle CTA without changing progression."""
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
code = (ROOT / "ui/AscendController.gd").read_text()
workflow = (ROOT / ".github/workflows/android.yml").read_text()
assert "func _realm_boss_intro_layout(parts: Dictionary) -> void:" in code
assert "frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)" in code
assert "get_viewport().get_visible_rect().size.y * 0.46,180.0,520.0" in code
assert 'portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL' in code
assert 'ScrollContainer.SCROLL_MODE_DISABLED if' in code
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
    assert "_hd_beta_boss_fit(parts, true)" in block,method
    assert image in block,method
assert "STRETCH_KEEP_ASPECT_CENTERED" in code
assert "func _realm_boss_result_layout(parts: Dictionary)" in code
assert "func _realm_boss_result_height() -> float:\n    return _realm_boss_portrait_height()" in code
assert "scene_art.custom_minimum_size.y = _realm_boss_result_height()" in code
for fn, end, art in (
    ("_realm_story_result","_realm_story_retry","_realm_story_art(body,realm_story_stage,_realm_boss_result_height(),true)"),
    ("_shadow_result","_shadow_retry","_shadow_add_art(body,_realm_boss_result_height(),true)"),
    ("_abyss_result","_abyss_retry","_abyss_add_art(body,_realm_boss_result_height(),true)"),
    ("_ember_result","_ember_retry","_ember_add_art(body,_realm_boss_result_height(),true)"),
):
    section = code.split("func " + fn + "(",1)[1].split("func " + end + "(",1)[0]
    assert "_realm_boss_result_layout(parts)" in section, fn
    assert "_realm_boss_result_action(parts," in section, fn
    assert "_hd_beta_boss_fit(parts, false)" in section, fn
    assert art in section, fn
import re
assert re.search(r"ZenCube-Chronicles-\d+(?:\.\d+)*\.apk", workflow), "A versioned Chronicles APK artifact must be uploaded"
assert "python3 tests/test_realm_boss_portraits.py" in workflow
print("PASS: cinematic boss pictures in all four Realm entry points with pinned Play")
