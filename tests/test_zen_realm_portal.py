#!/usr/bin/env python3
"""Strict model/UI/portal checks, no saved game mutation."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
model=(root/'core/ZenAscendRealms.gd').read_text(encoding='utf8')
ui=(root/'ui/AscendController.gd').read_text(encoding='utf8')
portal=(root/'ui/ZenRealmTravelCeremony.gd').read_text(encoding='utf8')
workflow=(root/'.github/workflows/android.yml').read_text(encoding='utf8')
assert 'const REALM_BOT_LEVELS: Array[int] = [1, 2, 3, 4]' in model
assert 'for prior in range(realm):' in model
assert 'count(data,prior) < 8 or not StoryGate.defeated_all(prior)' in model
assert '>= 5 or count(data,0) >= 4' not in model
assert '>= 7 or count(data,1) >= 5' not in model
assert '>= 10 and total_count(data) >= 12' not in model
assert model.count('"id":') == 32
# Stat requirements must be achievable at a fixed Realm bot level.
for realm, forbidden in [('shadow_hard','hard_win'),('ember_master','master_win'),('celestial_grand','grand_win')]:
    entry = next(s for s in model.splitlines() if '"id":"'+realm+'"' in s)
    assert '"metric":"'+forbidden+'"' not in entry, (realm, forbidden)
assert '"metric":"face_wins"' in next(s for s in model.splitlines() if '"id":"shadow_hard"' in s)
assert '"metric":"block_wins"' in next(s for s in model.splitlines() if '"id":"ember_master"' in s)
assert '"metric":"edge_wins","need":2' in next(s for s in model.splitlines() if '"id":"celestial_grand"' in s)
assert 'while match_realm > 0 and not Realms.unlocked(data,match_realm)' in ui
assert 'Realms.ready_for_breakthrough(data,match_realm)' in ui
assert 'var journey: ZenRealmTravelCeremony = RealmPortal.new()' in ui
assert 'func _show_manual_realm_journey(from_realm: int, to_realm: int, breakthrough: bool = false) -> void:' in ui
assert 'call_deferred("_show_manual_realm_journey",transition_from,number,first_open)' in ui
assert 'shader.code = PORTAL_SHADER' in portal and 'shader_parameter/reveal' in portal
assert 'PORTAL_SOUND = preload("res://assets/audio/zen_realm_breakthrough.wav")' in portal
assert 'MIRROR_SOUND = preload("res://assets/audio/zen_mirror_shatter.wav")' in portal
assert 'class MirrorGlassShatter:' in portal and 'class GlassCrackWeb:' in portal
assert 'var shard: Polygon2D = Polygon2D.new()' in portal
assert 'glass.build_glass(previous_texture,get_viewport().get_visible_rect().size)' in portal
assert 'tween_property(glass,"break_progress",1.0,1.55)' in portal
assert '_player.stream = MIRROR_SOUND if breakthrough else PORTAL_SOUND' in portal
assert 'get_tree().create_timer(0.38).timeout.connect' in portal
assert 'if sound_enabled:' in portal and '_player.play()' in portal and 'finished.emit()' in portal
assert (root/'assets/audio/zen_mirror_shatter.wav').is_file(), 'glass-break audio must be in APK source'
assert 'test_zen_realm_portal.gd' in workflow
assert 'const VERSION = 3' in (root/'core/SaveManager.gd').read_text()
print('PASS: combined 8/8 + 3/3 gates, 32 achievable tasks, cinematic portal, manual travel, preserved saves')
