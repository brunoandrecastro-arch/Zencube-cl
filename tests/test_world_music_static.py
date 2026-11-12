#!/usr/bin/env python3
"""Fast static check of the implemented integration, independent of Godot SDK."""
from pathlib import Path
import re
R = Path(__file__).resolve().parents[1]
main = (R/'ui/GameController.gd').read_text(encoding='utf8')
save = (R/'core/SaveManager.gd').read_text(encoding='utf8')
ascend = (R/'ui/AscendController.gd').read_text(encoding='utf8')
policy = (R/'core/ZenMusicPolicy.gd').read_text(encoding='utf8')
player = (R/'core/ZenWorldMusic.gd').read_text(encoding='utf8')
assert 'const WORLD_TRACKS: Array[int] = [7, 9, 11, 8, 12]' in policy
assert '"music_mode":"base"' in save
assert 'base.settings["music_mode"] = "manual"' in save
assert 'if data.get("economy") is Dictionary: base.economy.merge(data.economy, true)' in save
assert 'MusicPolicy.base_label(language_code())' in main
assert 'tracks.add_item(display, i)' in main and 'select_music_track(tracks.get_item_id(index))' in main, 'settings selector must retain real numeric track IDs'
assert 'var track_choices: Array[int] = [0, 1, 2, 5, 6, 8, 9, 10, 11, 12, 13]' in main
assert 'var display_order: Array = [5, 6, 8, 9, 10, 11, 12, 13]' in main, 'only payable tracks belong in the shop'
assert 'MusicPolicy.selected_track(data)' in main and 'sync_music() # Auto-World theme' in main
assert 'data.settings["music_mode"] = "base"' in main
assert 'data.settings["music_mode"] = "manual"' in main
assert 'var chosen: bool = MusicPolicy.mode(data) == "manual"' in main
assert 'var music_fade_player: AudioStreamPlayer' in main
assert 'music_transition.tween_property(music_fade_player, "volume_db", -54.0, 1.8)' in main
assert 'start_world_music()' in ascend
assert 'WorldMusic.stream_for(selected)' in ascend and 'RealmMusic.stream_for(realm_index())' in ascend
assert 'sync_realm_music()' in ascend and 'MusicPolicy.mode(data) == "base"' in ascend
assert 'if not Mode.unlocked(data):' in ascend
assert 'if not Collection.music_unlocked(data, index):' in main
assert 'return make_zen_music_stream(track)' in main
assert 'imported.loop = true' in main and 'mp3.loop = true' in player
assert 'const NEW_MUSIC_TITLES = ["Whispers of the Ancient Forest"' in main
for name in ['cyberwave_main', 'zen_piano', 'velario_zen', 'nature_wonder', 'calm_spirit', 'zen_of_nature', 'sitar_story']:
    assert f'assets/music/{name}.mp3' in main
    assert (R/'assets/music'/f'{name}.mp3').stat().st_size > 500_000
assert 'func select_base_music() -> void' in main
assert 'clampi(index, 0, 13)' in main
assert '"ascend":{}' in save
assert 'const PRICE: int = 750' in (R/'core/ZenAscend.gd').read_text()
print('PASS: Base/manual policy, 5 World tracks, seven stable IDs, 2-player fades, Ascend, purchases and save migration')
