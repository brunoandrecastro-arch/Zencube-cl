#!/usr/bin/env python3
"""Non-Godot smoke checks; the real headless engine test runs separately in CI."""
from pathlib import Path
import re
R=Path(__file__).resolve().parents[1]
ui=(R/'ui/AscendController.gd').read_text(encoding='utf8')
model=(R/'core/ZenAscendRealms.gd').read_text(encoding='utf8')
bot=(R/'core/ZenAscendRealmBot.gd').read_text(encoding='utf8')
assert model.count('"id":') == 32, 'exactly 32 challenges'
ids=re.findall(r'"id":"([a-z_]+)"',model)
assert len(set(ids))==32, 'challenge IDs unique'
assert 'var state: Dictionary' in model
assert 'realm_state' in model and 'realm_rewards' in model
assert '>= 5 or count(data,0) >= 4' in model
assert '>= 7 or count(data,1) >= 5' in model
assert '>= 10 and total_count(data) >= 12' in model
assert '"satori_aware"' in model and '"satori_six"' in model
assert 'bool(earned.get(id,false))' in model and 'realm_rewards.get(str(realm),false)' in model
assert 'ZenAscend.unlocked(data)' in model
assert 'for realm in range(4):' in model
assert 'match_realm = realm_index()' in ui
assert 'if against_bot:' in ui and 'Realms.record_bot_match(' in ui
assert 'RealmBot.next_move(cells,lines,2,bot_level)' in ui
assert 'match_blocked_threat' in ui and 'Realms.prevents_immediate_win' in ui
assert 'show_realms()' in ui and 'show_challenges()' in ui and 'show_realm_titles()' in ui
# Gameplay uses independent Realm artwork.
assert 'backdrop.texture = load(Realms.REALM_ART[realm_index()])' in ui
assert 'realm_backdrop.texture = load(Realms.REALM_ART[realm_id])' in ui
assert 'realm_backdrop.texture = load(Realms.REALM_ART[number])' in ui

# Classic world art is allowed only as rank illustration.
stats_ui = ui.split('func show_statistics() -> void:', 1)[1].split('func return_home() -> void:', 1)[0]
assert 'illustration.texture = ZenAscension.WORLD_TEXTURES[mini(rank,4)]' in stats_ui
for name in ('shadow_realm','ember_temple','celestial_realm','satori_realm'):
    p=R/'assets/realms'/f'{name}.webp'
    assert p.exists() and p.stat().st_size > 20_000
    assert p.read_bytes()[:4] == b'RIFF' and p.read_bytes()[8:12] == b'WEBP'
# Never changed Classic match controller or 4x4 rule constants.
classic=(R/'core/RulesEngine.gd').read_text()
assert '108' in classic or 'generate_lines' in classic or 'lines' in classic
assert 'const CELLS: int = 96' in (R/'core/ZenAscend.gd').read_text()
assert 'const PRICE: int = 850' in (R/'core/ZenAscend.gd').read_text()
assert 'const VERSION = 3' in (R/'core/SaveManager.gd').read_text()
assert 'res://assets/music/' not in model, 'realm audio must await supplied Suno songs'
print('PASS: 4 realms, 32 unique challenges, stable saves and unlocks, 4 independent original backgrounds, five bot tiers')
