#!/usr/bin/env python3
"""Non-Godot validation. A real Godot scene test also runs in CI."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
game = (root/'ui/GameController.gd').read_text(encoding='utf8')
ascend = (root/'ui/AscendController.gd').read_text(encoding='utf8')
gong = (root/'ui/ZenRankCeremony.gd').read_text(encoding='utf8')
fully = (root/'ui/ZenFullyAwareCeremony.gd').read_text(encoding='utf8')
realm_audio = (root/'core/ZenRealmMusic.gd').read_text(encoding='utf8')
old_policy = (root/'core/ZenMusicPolicy.gd').read_text(encoding='utf8')
save = (root/'core/SaveManager.gd').read_text(encoding='utf8')
ci = (root/'.github/workflows/android.yml').read_text(encoding='utf8')
assert 'func prepare_rank_music() -> void:' in game
assert 'func restore_rank_music() -> void:' in game
assert 'restore_rank_music()' in game and 'prepare_rank_music()' in game
assert 'music_player.volume_db = -2.0' in game
assert 'if music_fade_player != null and music_fade_player.playing:' in game
assert 'var target_db: float = -2.0 if _music_levels.is_empty() else source.volume_db' in gong
assert 'const SECONDS: float = 5.5' in gong, 'do not change original gong ceremony'
assert 'GONG_AUDIO = preload("res://assets/audio/zen_temple_gong.wav")' in gong
assert 'const REALM_SONGS: Array[String]' in realm_audio
assert 'stream.loop = true' in realm_audio
assert 'if MusicPolicy.mode(data) == "base":' in ascend
assert 'RealmMusic.stream_for(realm_index())' in ascend
assert 'return WorldMusic.stream_for(selected)' in ascend
assert 'func sync_realm_music(initial: bool = false) -> void:' in ascend
assert 'sync_realm_music()' in ascend
assert 'last_realm_awards.get("realm_completed", false)' in ascend
assert 'Realms.current_title(data,3) == "Fully Aware"' in ascend
assert 'fully_aware_ceremony_seen' in ascend
assert 'SaveManager.save_data(data)' in ascend
assert 'call_deferred("show_fully_aware",last_realm_awards.duplicate(true))' in ascend
# Rewards now appear in the premium result after the Satori ceremony.
ceremony = ascend.split('func show_fully_aware(awards: Dictionary) -> void:',1)[1].split('func _dialog(',1)[0]
assert 'celebration.finished.connect(func():' in ceremony
assert 'call_deferred("show_match_result")' in ceremony
result = ascend.split('func show_match_result() -> void:',1)[1].split('func _replay_after_result(',1)[0]
assert 'last_match_leaf_reward + int(last_realm_awards.get("leaves",0))' in result
assert 'last_realm_awards.get("new_tasks",[])' in result
assert 'class_name ZenFullyAwareCeremony' in fully
assert 'if _closed: return' in fully and 'signal finished' in fully
assert 'DISPLAY_SECONDS: float = 7.5' in fully
assert 'FULLY AWARE' in fully
assert 'GONG = preload("res://assets/audio/zen_temple_gong.wav")' in fully
assert 'const WORLD_TRACKS: Array[int] = [7, 9, 11, 8, 12]' in old_policy
assert 'const VERSION = 3' in save
assert 'test_realm_audio_ceremony.py' in ci and 'test_realm_audio_ceremony.gd' in ci
assert 'const CELLS: int = 96' in (root/'core/ZenAscend.gd').read_text(encoding='utf8')
assert 'const PRICE: int = 850' in (root/'core/ZenAscend.gd').read_text(encoding='utf8')
for name in ('shadow_realm','ember_temple','celestial_realm','satori_realm'):
    f=root/'assets'/'realm_music'/f'{name}.ogg'
    assert f.is_file() and f.stat().st_size > 1_000_000, f
    assert f.read_bytes()[:4] == b'OggS', f
    assert f'res://assets/realm_music/{name}.ogg' in realm_audio
print('PASS: 4 looping Realm files, Base/manual override, one-time Satori ceremony, restored Gong music and stable saves')
