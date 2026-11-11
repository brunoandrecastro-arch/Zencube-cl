#!/usr/bin/env python3
"""RC6: enforce locked Play release vs free internal debug APK."""
from pathlib import Path
import re
ROOT = Path(__file__).resolve().parents[1]
mode = (ROOT/'core/ZenAscend.gd').read_text(encoding='utf-8')
ui = (ROOT/'ui/GameController.gd').read_text(encoding='utf-8')
presets = (ROOT/'export_presets.cfg').read_text(encoding='utf-8')
workflow = (ROOT/'.github/workflows/android.yml').read_text(encoding='utf-8')
build = (ROOT/'scripts/build_android.sh').read_text(encoding='utf-8')
# A release build must never pick up the internal test feature tag.
configs = re.findall(r'(?m)^\[preset\.\d+\]\n(.*?)(?=^\[preset\.\d+(?:\.options)?\]|\Z)', presets, re.S | re.M)
assert len(configs) == 2, 'expected exactly 2 Android export profiles'
assert 'name="Android"' in configs[0] and 'custom_features="zencube_ascend_test"' in configs[0], 'debug APK preset needs internal tag'
assert 'name="Android Play"' in configs[1] and 'custom_features=""' in configs[1], 'Play release must not enable test flag'
assert '--export-debug Android ' in build, 'GitHub test APK must use Android debug preset'
assert 'OS.has_feature("zencube_ascend_test")' in mode
assert 'OS.has_feature("debug")' in mode
assert 'not OS.has_feature("release")' in mode
assert 'return TEST_UNLOCKED or unlocked_for_release(data)' not in mode, 'unsafe always-on test bypass remains'
assert 'return test_access_enabled() or unlocked_for_release(data)' in mode
assert 'if ZMode.test_access_enabled():' in ui, 'test banner must only show for true debug entitlement'
assert 'if ZMode.unlocked(data):' in ui and 'if not Mode.unlocked(data):' in (ROOT/'ui/AscendController.gd').read_text(), 'both access paths must be gated'
assert 'get("rank",0)) >= 3' in mode, 'release entitlement must begin at Zen Master'
assert 'get("ascend_owned",false)' in mode, 'permanent store purchase retained'
assert 'const PRICE: int = 750' in mode and 'data.economy.leaves -= PRICE' in mode
assert 'if unlocked_for_release(data): return false' in mode, 'do not charge already unlocked players'
assert 'test_rc6_release_gate.py' in workflow
# Truth table for the intended independent build flags and permanent rights.
def allowed(tag, debug, release, rank=0, bought=False):
    return bool(tag and debug and not release) or bought or rank >= 3
assert allowed(True, True, False, 0)  # exported test APK
assert not allowed(False, True, False, 0)  # normal debug without tag
assert not allowed(False, False, True, 0)  # Play Store beginner
assert not allowed(True, False, True, 0)  # wrong tag must not unlock release
assert not allowed(True, True, True, 0)  # release flag overrides debug
assert not allowed(False, False, True, 2)  # Zen Adept still locked
assert allowed(False, False, True, 3)  # Zen Master
assert allowed(False, False, True, 0, bought=True)  # store purchase
print('RC6 PASS: debug APK test access, production locked until rank 3 or 750-leaf purchase')
