#!/usr/bin/env python3
# 4x4 is locked for every build unless rank >=3 or bought for 750 leaves.
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
mode = (root/"core/ZenAscend.gd").read_text(encoding="utf8")
ui = (root/"ui/GameController.gd").read_text(encoding="utf8")
ascend = (root/"ui/AscendController.gd").read_text(encoding="utf8")
preset = (root/"export_presets.cfg").read_text(encoding="utf8")
build = (root/"scripts/build_android.sh").read_text(encoding="utf8")
workflow = (root/".github/workflows/android.yml").read_text(encoding="utf8")
parts = re.findall(r"(?m)^\[preset\.\d+\]\n(.*?)(?=^\[preset\.\d+(?:\.options)?\]|\Z)", preset, re.S | re.M)
assert len(parts)==2, "Exactly two export profiles needed"
assert 'name="Android"' in parts[0] and 'custom_features=""' in parts[0]
assert 'name="Android Play"' in parts[1] and 'custom_features=""' in parts[1]
assert "zencube_ascend_test" not in preset
assert "--export-debug Android " in build
assert 'const TEST_UNLOCKED: bool = false' in mode
assert 'static func test_access_enabled() -> bool:' in mode
assert 'return false' in mode
assert "OS.has_feature" not in mode
assert 'static func unlocked(data: Dictionary) -> bool:\n    return unlocked_for_release(data)' in mode
assert 'get("rank",0)) >= 3' in mode
assert 'get("ascend_owned",false)' in mode
assert 'const PRICE: int = 750' in mode and 'data.economy.leaves -= PRICE' in mode
assert 'if unlocked_for_release(data): return false' in mode, "No double charge"
assert 'if ZMode.unlocked(data):' in ui and 'if not ZMode.unlocked(data): return' in ui
assert 'if not Mode.unlocked(data):' in ascend
assert 'if ZMode.test_access_enabled():' not in ui
assert 'if ZMode.TEST_UNLOCKED else' not in ui
assert "test_rc6_release_gate.py" in workflow
def allowed(rank=0, bought=False): return rank >= 3 or bought
assert not allowed(0) and not allowed(1) and not allowed(2)
assert allowed(3) and allowed(4) and allowed(0, True)
print("PASS: both builds lock Zen Ascend 4x4 until rank 3 or permanent 750-leaf purchase")
