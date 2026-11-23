#!/usr/bin/env python3
"""Static regressions for the Termux feedback patch. Run from repository root."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
r2 = (root/'core/ZenRealmCampaign2.gd').read_text()
realms = (root/'core/ZenAscendRealms.gd').read_text()
controller = (root/'ui/AscendController.gd').read_text()
chronicles = (root/'story/ZenChronicles.gd').read_text()
gate = (root/'core/ZenRealmStoryGate.gd').read_text()

limits = [22, 24, 26, 28, 30]
assert '"metric":"fast22"' in realms and '"metric":"fast26"' in realms
assert 'if moves <= 22: stats.fast22 += 1' in realms
assert 'if moves <= 26: stats.fast26 += 1' in realms
for threshold in limits[1:]:
    assert f'if moves <= {threshold}: stats.fast_wins' in r2, threshold
for chapter in ('abyss','ember','celestial','satori'):
    assert '"fast_wins":0' in r2
    assert f'"{chapter}_stats"' in r2
for chapter in ('record_abyss_match','record_ember_match','record_celestial_match','record_satori_match'):
    assert chapter+'(outcome,crossed,' in controller, chapter
assert 'move_count()' in controller
assert 'Realm2.SOURCE_ART[i]' in chronicles and 'assets/abyss_of_memories/gameplay.webp' in chronicles
assert 'Zen Chronicles · ' in controller
assert 'recent_saves: Array[String]' in gate and 'return maxi(old_count,recent_count)' in gate
assert 'func _realm_boss_result_height()' in controller
assert 'frame.anchor_top = 0.265' in controller and 'frame.anchor_bottom = 0.735' in controller
assert '_open_campaign_story_from_match.bind(story_chapter)' in controller
assert '"shadow_block","title":"Veil Tactician"' in realms
assert '"ember_master","title":"Ember Mastery"' in realms
print('PASS: five win-within-X tasks, legacy saves, campaign navigation and compact result UI')
