#!/usr/bin/env python3
"""Fail-closed checks for the ZenCube Chronicles 4.0.1 locked update."""
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
build = (ROOT / "scripts/build_android.sh").read_text()
workflow = (ROOT / ".github/workflows/android.yml").read_text()
mode = (ROOT / "core/ZenAscend.gd").read_text()
ascend_scene = (ROOT / "ui/AscendController.gd").read_text()
ui = (ROOT / "ui/GameController.gd").read_text()
presets = (ROOT / "export_presets.cfg").read_text()
assert 'ZENCUBE_RELEASE_GATES: ${{ github.head_ref' in workflow
assert 'release_gates="${ZENCUBE_RELEASE_GATES:-false}"' in build
block = build.split('if [[ "$realm2_test" == true ]]; then', 1)[1].split('elif [[ "$shadow_test" == true ]]', 1)[0]
assert 'if [[ "$release_gates" != true ]]; then' in block
assert 'zencube_celestial_qa' in block
assert 'custom_features="zencube_realm_2_0_test,zencube_shadow_test,zencube_abyss_test"' in block
assert "version/code=41" in block and 'version/name="4.0.1"' in block
assert "if grep -Eq 'custom_features=\"[^\"]+\"' export_presets.cfg;" in build
assert 'custom_features=""' in presets and 'zencube_celestial_qa' not in presets
assert 'return unlocked_for_release(data)' in mode
assert 'get("ascend_owned",false)' in mode and 'get("rank",0)) >= 3' in mode
assert 'const PRICE: int = 850' in mode
assert 'if not Mode.unlocked(data)' in ascend_scene
assert 'if not ZMode.unlocked(data): return' in ui
assert 'ZenCube-Chronicles-4.0.1.apk' in workflow
assert 'python3 tests/test_zen_ascend_locked_update.py' in workflow
assert 'tests/test_zen_ascend_locked_update.gd' in workflow
print("PASS: 4.0.1 export removes QA unlock flags and preserves permanent rank/shop gate")
