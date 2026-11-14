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
assert 'for required_realm in range(realm):' in model
assert 'if count(data,required_realm) < 8: return false' in model
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
assert 'Realms.count(data,match_realm) == 8' in ui
assert 'var journey: ZenRealmTravelCeremony = RealmPortal.new()' in ui
assert 'func _show_manual_realm_journey(from_realm: int, to_realm: int) -> void:' in ui
assert 'call_deferred("_show_manual_realm_journey",from_realm,number)' in ui
assert 'shader.code = PORTAL_SHADER' in portal and 'shader_parameter/reveal' in portal
assert 'PORTAL_SOUND = preload("res://assets/audio/zen_realm_breakthrough.wav")' in portal
assert 'if sound_enabled: _player.play()' in portal and 'finished.emit()' in portal
assert 'test_zen_realm_portal.gd' in workflow
assert 'const VERSION = 3' in (root/'core/SaveManager.gd').read_text()
print('PASS: strict 8/8 gates, 32 achievable tasks, cinematic portal, manual travel, preserved saves')
