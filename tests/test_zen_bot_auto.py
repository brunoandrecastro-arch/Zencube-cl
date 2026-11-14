#!/usr/bin/env python3
"""Verify new Zen bot rank defaults and four high-resolution realm backgrounds.
No external Python packages required in Termux or GitHub CI.
"""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
ui=(ROOT/'ui/GameController.gd').read_text(encoding='utf-8')
ascend=(ROOT/'ui/AscendController.gd').read_text(encoding='utf-8')
helper=(ROOT/'core/ZenBotAutoLevel.gd').read_text(encoding='utf-8')
rank=(ROOT/'core/ZenAscension.gd').read_text(encoding='utf-8')
save=(ROOT/'core/SaveManager.gd').read_text(encoding='utf-8')
mode=(ROOT/'core/ZenAscend.gd').read_text(encoding='utf-8')
assert 'popup.anchor_top = 0.52 if special else 0.56' in ui
assert 'popup.anchor_bottom = 0.97' in ui
assert 'var completed_bot_level: int = -1' in ui
assert 'completed_bot_level = clampi(int(data.settings.level),0,4)' in ui
assert 'completed_bot_level = -1' in ui
assert 'if board != null and board.winner != 0 and completed_bot_level >= 0:' in ui
assert 'BotAuto.apply_after_rank_up(data,last_rank_up)' in ui
assert 'if not bool(result.get("rank_up", false)):' in helper
assert 'data.settings["level"] = level_for_rank(rank)' in helper
assert 'return clampi(rank, 0, 4)' in helper
realms=(ROOT/'core/ZenAscendRealms.gd').read_text(encoding='utf-8')
assert 'const REALM_BOT_LEVELS: Array[int] = [1, 2, 3, 4]' in realms
assert 'bot_level = Realms.fixed_bot_level(match_realm)' in ascend
assert 'var fixed_level: int = Realms.fixed_bot_level(realm_index())' in ascend
assert 'BotAuto.level_for_rank(int(data.ascension.rank))' not in ascend
assert 'ZenCollection.reward_bot(data,bot_level)' in ascend
assert 'ZenCollection.reward_loss(data)' in ascend
assert 'const TARGETS = [3, 5, 7, 3, 5]' in rank
assert 'const VERSION = 3' in save
assert 'const CELLS: int = 96' in mode and 'const PRICE: int = 850' in mode
assert 'const TEST_UNLOCKED: bool = false' in mode
assert 'return unlocked_for_release(data)' in mode
assert 'res://assets/realms/shadow_realm.webp' in (ROOT/'core/ZenAscendRealms.gd').read_text()

def webp_dimensions(path: Path):
    data=path.read_bytes()
    assert data[:4] == b'RIFF' and data[8:12] == b'WEBP', path
    marker=b'\x9d\x01\x2a'
    index=data.find(marker)
    assert index!=-1, 'Expected lossy VP8 WebP image'+str(path)
    width=int.from_bytes(data[index+3:index+5],'little')&0x3fff
    height=int.from_bytes(data[index+5:index+7],'little')&0x3fff
    return width,height

for name in ('shadow_realm','ember_temple','celestial_realm','satori_realm'):
    path=ROOT/'assets'/'realms'/f'{name}.webp'
    assert path.is_file(),path
    assert webp_dimensions(path)==(1440,2560),(name,webp_dimensions(path))
    assert path.stat().st_size>100_000,name
print('PASS: Classic rank defaults and fixed 4x4 realm bot tiers; unlocks/stats and HD Realm assets preserved')
