ZenCube UI Loader Hotfix / Godot CI 2026-11-08

What has been seen in GitHub Actions: the Godot engine rules tests and 108-lines tests pass, but Main.tscn loads as Node3D without a functioning GameController script. The previous UI test calls open_welcome(), fails, and times out after 180 seconds.

Changes:
1. Refactor ambiguous one-line multi-statement callbacks in GameController.gd into explicitly indented functions.
2. Add a headless preflight in tests/test_scene_load.gd to verify the actual main scene loads and exposes open_welcome().
3. Guard tests/test_ui.gd against missing script and fail immediately with an actionable error rather than hanging.
4. Shorten UI-test timeout to 65s; preserve the previously fixed Android SDK setup step.

Status: Python four-in-a-row tests pass (108 lines). Godot runtime / Android APK has NOT been built in this environment. If the new preflight fails, inspect its exact GDScript parse error in Actions; do not bypass the test just to produce an unplayable APK.
