extends SceneTree
# Verify the isolated UI Test without altering real game progression.
const ThemeTest = preload("res://ui/ZenUiTestTheme.gd")
var failures: int = 0

func check(condition: bool, description: String) -> void:
    if not condition:
        failures += 1
        printerr("UI TEST FAIL: ", description)

func _initialize() -> void:
    call_deferred("run")

func _find(root_node: Node, node_name: String) -> Node:
    if root_node.name == node_name: return root_node
    for child in root_node.get_children():
        var match: Node = _find(child, node_name)
        if match != null: return match
    return null

func _buttons(node: Node, found: Array) -> void:
    if node is Button: found.append(node)
    for child in node.get_children(): _buttons(child, found)

func run() -> void:
    var old_save: PackedByteArray = PackedByteArray()
    var save_existed: bool = FileAccess.file_exists(SaveManager.PATH)
    if save_existed: old_save = FileAccess.get_file_as_bytes(SaveManager.PATH)

    var line: Array = ThemeTest.winning_example()
    check(line.size() == 4, "exactly four winning squares")
    var face_counts: Dictionary = {}
    for cell in line:
        var face_id: int = CubeGeometry.face(int(cell))
        face_counts[face_id] = int(face_counts.get(face_id, 0)) + 1
    check(face_counts.size() == 2, "winning line spans two faces")
    check(face_counts.get(0, 0) == 2 and face_counts.get(3, 0) == 2, "real front/right 2+2 win")
    check(RulesEngine.new().lines.has(line), "win is one of 108 real rules")
    var game_scene: PackedScene = load("res://Main.tscn") as PackedScene
    check(game_scene != null, "main game scene loads")
    if game_scene == null:
        quit(1)
        return
    var game: Node = game_scene.instantiate()
    root.add_child(game)
    await process_frame
    var baseline: Dictionary = game.board.snapshot()
    # A truly fresh install already opens language selection in _ready().
    # Let the old overlay leave the tree before opening a second one; otherwise
    # Godot renames the second sibling while the queued-for-free one still exists.
    game.close_modal()
    await process_frame
    game.open_language_choice()
    check(game.popup != null and game.popup.name == "UiTestLanguageOverlay", "language screen is new UI Test overlay")
    var title: Node = _find(game.popup, "UiTestTitle")
    check(title is Label and (title as Label).text == "ZenCube 3D", "Sakura gold brand")
    var scene_preview: Node = _find(game.popup, "UiTestCubeRenderer")
    check(scene_preview is CubeRenderer, "preview uses actual Godot CubeRenderer")
    if scene_preview is CubeRenderer:
        check((scene_preview as CubeRenderer).tiles.size() == 54, "3x3 on all six sides")
        check(int((scene_preview as CubeRenderer).skin_id) == 0, "original classic stone skin")
    var area: Node = _find(game.popup, "UiTestPreviewStage")
    check(area != null and area.get_meta("winning_line", []) == line, "real 2+2 victory displayed")
    var buttons: Array = []
    _buttons(game.popup, buttons)
    var language_count: int = 0
    for b in buttons:
        if str(b.text).contains("Deutsch") or str(b.text).contains("English") or str(b.text).contains("Português"):
            check(b.pressed.is_connected(Callable(game, "choose_language").bind("de")) or b.pressed.is_connected(Callable(game, "choose_language").bind("en")) or b.pressed.is_connected(Callable(game, "choose_language").bind("pt")), "language button has callback")
            language_count += 1
    check(language_count == 3, "three native language buttons")
    check(game.board.snapshot() == baseline, "showing preview cannot modify game board")
    game.data.settings.intro_seen = true
    game.choose_language("pt")
    check(game.language_code() == "pt", "language interaction changes saved language")
    check(game.board.snapshot() == baseline, "language switch retains current game")
    game.queue_free()
    await process_frame
    if save_existed:
        var file: FileAccess = FileAccess.open(SaveManager.PATH, FileAccess.WRITE)
        if file != null:
            file.store_buffer(old_save)
            file.close()
    elif FileAccess.file_exists(SaveManager.PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.PATH))
    print("ZEN UI TEST FAILURES=", failures)
    quit(0 if failures == 0 else 1)
