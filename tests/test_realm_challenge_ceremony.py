#!/usr/bin/env python3
"""Realm Challenge has an ACTUAL cinematic celebration, not only a choir sound."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
game = (root/"ui/AscendController.gd").read_text()
fx = (root/"ui/ZenUnlockCeremony.gd").read_text()
shadow = (root/"story/ZenShadowCampaign.gd").read_text()
flow = (root/".github/workflows/android.yml").read_text()
finish = game.split("func finish() -> void:",1)[1].split("func _show_next_unlock()",1)[0]
assert 'if campaign_awards.is_empty():' in finish and 'call_deferred("_campaign_practice_show_next_award")' in finish
assert 'func _campaign_practice_show_next_award() -> void:' in game
award_flow = game.split("func _campaign_practice_show_next_award() -> void:",1)[1].split("func _campaign_practice_result()",1)[0]
for needle in ['Realm2.task_description(practice_chapter,task_index,lang())','campaign_award_index += 1',
               'campaign_practice_active and result != 0 and match_generation == saved_match_generation',
               'celebration.present("challenge",Abyss.battle_backdrop() if practice_chapter==1 else Realm2.SOURCE_ART[practice_chapter]']:
    assert needle in award_flow,needle
result = game.split("func _campaign_practice_result() -> void:",1)[1].split("func _enter_campaign_final_guardian()",1)[0]
assert 'zen_achievement_choir.wav' not in result, "do not play a second choir"
assert 'kind == "challenge"' in fx
assert "RealmChallengeCeremonyHeading" in fx and "ZenUnlockContinue" in fx
assert "const PORTRAIT_ROOT" in shadow and "ResourceLoader.exists(approved_portrait)" in shadow
for character in ("mist_guardian","mirror_novice","veil_monk"):
    assert character in shadow
# Regular 4x4 Zen Ascend challenges need the same full-screen celebration
# that Campaign 2.0 challenge rewards already receive.
normal = game.split("last_realm_awards = Realms.record_bot_match(",1)[1].split("for secret in Achievements.claim_after_match(",1)[0]
assert 'for earned_task_id in last_realm_awards.get("new_tasks",[])' in normal
assert 'queued_unlocks.append({"kind":"challenge","realm":match_realm' in normal
assert 'new_challenge_names.size() > 1' not in normal, "Never batch simultaneous rewards"
assert 'Realms.task_description(task,lang())' in normal
queue = game.split("func _show_next_unlock() -> void:",1)[1].split("func show_fully_aware(",1)[0]
assert 'unlock.name = "ZenAscendChallengeEarnedCeremony"' in queue
assert 'str(item.quote),bool(data.settings.get("sound",true)),[world_music],lang())' in queue
assert 'func show_match_result() -> void:' in game, "Existing match result must remain intact"
assert "test_realm_challenge_ceremony.gd" in flow
assert "ZenCube-Chronicles-4.0.4.apk" in flow
print("PASS: automatic Realm Challenge full-screen celebration, one-shot choir, Shadow portrait slots")
