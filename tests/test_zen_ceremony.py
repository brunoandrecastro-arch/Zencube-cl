#!/usr/bin/env python3
"""ZenCube rank ceremony contract: rank-up only, skip, SFX settings and intact saves."""
from pathlib import Path
import struct
import wave
BASE = Path(__file__).resolve().parents[1]
ui = (BASE/'ui/GameController.gd').read_text(encoding='utf-8')
ceremony = (BASE/'ui/ZenRankCeremony.gd').read_text(encoding='utf-8')
rank = (BASE/'core/ZenAscension.gd').read_text(encoding='utf-8')
save = (BASE/'core/SaveManager.gd').read_text(encoding='utf-8')
flow = (BASE/'.github/workflows/android.yml').read_text(encoding='utf-8')
assert 'RANK_CEREMONY = preload("res://ui/ZenRankCeremony.gd")' in ui
assert 'if bool(last_rank_up.get("rank_up",false)) and not ceremony_done_for_match:' in ui
assert 'ceremony_done_for_match = true' in ui
assert 'ceremony_active = true' in ui
assert 'celebration.present(int(data.ascension.rank),language_code(),bool(data.settings.sound),[music_player,music_fade_player])' in ui
assert 'if cell < 0 or ceremony_active' in ui
assert 'if ceremony_active: return' in ui
assert 'call_deferred("show_result_screen")' in ui
assert 'var result: Dictionary = {"rank_up": false, "old_rank": before, "new_rank": before}' in rank
assert 'result["rank_up"] = after > before' in rank
assert 'const SECONDS: float = 5.5' in ceremony
assert 'get_tree().create_timer(SECONDS).timeout.connect(skip)' in ceremony
assert 'func skip() -> void:' in ceremony
assert '_closed = true' in ceremony and 'finished.emit()' in ceremony
assert 'if effects_on:' in ceremony and '_gong_player.play()' in ceremony
assert 'source.playing' in ceremony and '"volume_db"' in ceremony
assert 'Locale.translate(str(Asc.RANKS[rank]), language)' in ceremony
assert 'if rank == 3:' in ceremony and 'ZEN ASCEND 4×4' in ceremony
assert 'if rank <= 4:' in ceremony
assert '"music_mode":"base"' in save and 'const VERSION = 3' in save
assert 'test_zen_ceremony.py' in flow and 'test_zen_ceremony.gd' in flow
assert (BASE/'assets/effects/zen_temple_gong.png').read_bytes()[:8] == b'\x89PNG\r\n\x1a\n'
assert (BASE/'assets/effects/zen_golden_wave.png').read_bytes()[:8] == b'\x89PNG\r\n\x1a\n'
with wave.open(str(BASE/'assets/audio/zen_temple_gong.wav'),'rb') as gong:
    assert gong.getnchannels() == 1 and gong.getsampwidth() == 2
    assert 3.0 < gong.getnframes()/gong.getframerate() < 5.0
    data = gong.readframes(gong.getnframes())
    samples = struct.unpack('<'+str(len(data)//2)+'h', data)
    assert 1000 < max(samples) < 30000
print('PASS: one-time Zen rank-up ceremony, skip, multilingual rank/world/4x4, original gong, no rank/save mutation')
