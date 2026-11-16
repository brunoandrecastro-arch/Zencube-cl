#!/usr/bin/env python3
"""Reject a disguised QA build as a production-like ZenCube user preview."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
mode=(R/'core/ZenAscend.gd').read_text()
story=(R/'story/ZenRealmChronicles.gd').read_text()
realms=(R/'core/ZenAscendRealms.gd').read_text()
game=(R/'ui/GameController.gd').read_text()
ascend=(R/'ui/AscendController.gd').read_text()
book=(R/'story/ZenChronicles.gd').read_text()
workflow=(R/'.github/workflows/android.yml').read_text()
build=(R/'scripts/build_android.sh').read_text()
assert 'return OS.has_feature("debug") and bool(ProjectSettings.get_setting("application/config/realm_chronicles_qa",false))' in mode
assert 'return OS.has_feature("debug") and bool(ProjectSettings.get_setting("application/config/realm_chronicles_qa",false))' in story
assert 'return unlocked_for_release(data) or test_access_enabled()' in mode
assert 'get("rank",0)) >= 3' in mode and 'get("ascend_owned",false)' in mode
assert 'if not ZMode.unlocked(data): return' in game
assert 'if not Mode.unlocked(data):' in ascend
assert 'if RealmStory.qa_mode():' in ascend
assert 'if RealmStory.qa_mode() and chapter > 0:' in book
assert 'if qa_mode(): return true' in story
assert 'return ZenAscendRealms.unlocked(data,chapter(stage))' in story
assert 'if count(data,prior) < 8 or not StoryGate.defeated_all(prior):' in realms
assert "com.zencube.game.enduserpreview" in build
assert 'ZENCUBE_ENDUSER_PREVIEW' in workflow
assert "application/config/realm_chronicles_qa" not in (R/'project.godot').read_text()
assert "ZENCUBE_REALM_CHRONICLES_TEST: ${{ github.head_ref == 'feature/zen-ascend-realm-chronicles' || github.ref_name == 'feature/zen-ascend-realm-chronicles' }}" in workflow
assert "ZENCUBE_ENDUSER_PREVIEW: ${{ startsWith(github.head_ref, 'release/play-candidate-') || startsWith(github.ref_name, 'release/play-candidate-') }}" in workflow
assert 'if [[ "$realm_test" == true && "$enduser_preview" == true ]]' in build
print('PASS: End-user APK has 4x4 entitlement, strict chapter gates, no QA shortcuts')
