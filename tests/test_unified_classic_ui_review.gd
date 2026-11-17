extends SceneTree
# A unified Sakura-Gold theme and postgame read-only 3x3 inspection.
# Uses the actual 54-cell CubeRenderer, real winning geometry, and live UI.
var failures: int = 0

func check(value: bool, message: String) -> void:
    if not value:
        failures += 1
        printerr("CLASSIC UI UNITY FAIL: ",message)

func find_button(node: Node, name: String) -> Button:
    if node is Button and node.name == name: return node
    for child in node.get_children():
        var hit: Button = find_button(child,name)
        if hit != null: return hit
    return null

func run() -> void:
    var path: String = SaveManager.PATH
    var had_save: bool = FileAccess.file_exists(path)
    var backup: PackedByteArray = FileAccess.get_file_as_bytes(path) if had_save else PackedByteArray()
    var data: Dictionary = SaveManager.defaults()
    data.settings.language = "en"
    data.settings.intro_seen = true
    data.settings.swap = false
    check(SaveManager.save_data(data),"seed English test save")
    var scene: PackedScene = load("res://Main.tscn") as PackedScene
    check(scene != null,"classic scene available")
    if scene == null:
        quit(1)
        return
    var game: Node = scene.instantiate()
    root.add_child(game)
    await process_frame
    var gold: Color = Color("#ddb166")
    for screen in ["open_menu","open_stats","open_settings"]:
        game.call(screen)
        var popup: PanelContainer = game.get("popup") as PanelContainer
        check(popup != null,screen + " opens in same layout")
        if popup != null:
            var panel: StyleBoxFlat = popup.get_theme_stylebox("panel") as StyleBoxFlat
            check(panel != null and panel.border_color.is_equal_approx(gold),screen + " shares Sakura-Gold border")
            check(popup.find_child("ZenGoldModalHeading",true,false) != null,screen + " uses same title")
            check(popup.find_child("ZenGoldDivider",true,false) != null,screen + " has gold divider")
        game.call("close_modal")

    game.call("start_mode",0) # Local Classic; no external bot or network.
    var rules: RulesEngine = game.get("rules") as RulesEngine
    var win: Array = rules.lines[0]
    var filler: Array = []
    for cell in range(54):
        if not win.has(cell): filler.append(cell)
    for i in range(4):
        game.call("place",int(win[i]))
        if i < 3: game.call("place",int(filler[i]))
    var board: BoardModel = game.get("board") as BoardModel
    check(int(board.winner) == 1,"legal four-in-a-row still wins")
    await process_frame
    var popup: PanelContainer = game.get("popup") as PanelContainer
    check(popup != null,"local multiplayer also shows result panel")
    var inspect: Button = find_button(popup,"InspectClassicFinishedBoard") if popup != null else null
    check(inspect != null,"Classic results offer Inspect board")
    var actual: Array = board.cells.duplicate()
    var moves: int = board.move_count()
    var renderer: CubeRenderer = game.get("renderer") as CubeRenderer
    var camera_at_end: Basis = renderer.pivot.basis
    if inspect != null: inspect.pressed.emit()
    check(game.get("popup") == null,"inspect closes results without replay")
    check(board.move_count() == moves,"inspection preserves move count")
    check(board.cells == actual,"inspection preserves all 54 cell values")
    var button: Button = game.get("classic_result_button") as Button
    var undo: Button = game.get("classic_undo_button") as Button
    check(button != null and button.visible,"finished games show Show result")
    check(undo != null and not undo.visible,"undo action is replaced at completion")

    renderer.rotate_cube(Vector2(52,33))
    check(not renderer.pivot.basis.is_equal_approx(camera_at_end),"real 3x3 cube rotates after finishing")
    var zoom_before: float = renderer.camera.position.z
    renderer.zoom(0.90)
    check(not is_equal_approx(renderer.camera.position.z,zoom_before),"real 3x3 cube zooms after finishing")
    game.call("on_cell",int(filler[25]))
    check(board.cells == actual,"postgame taps never place new symbols")

    if button != null: button.pressed.emit()
    check(game.get("popup") != null,"Show result reopens without changing board")
    check(board.cells == actual,"reopening preserves the completed match")
    game.call("close_modal")
    game.call("play_again_after_result")
    # new_game() intentionally replaces BoardModel rather than mutating the
    # archived completed board; inspect the new instance after replay.
    board = game.get("board") as BoardModel
    check(board.winner == 0 and board.move_count() == 0,"new match resets the Classic board")
    check(button != null and not button.visible,"replay removes Show result")
    check(undo != null and undo.visible,"replay restores undo")

    game.queue_free()
    await process_frame
    if had_save:
        var restore: FileAccess = FileAccess.open(path,FileAccess.WRITE)
        if restore != null:
            restore.store_buffer(backup)
            restore.close()
    elif FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("CLASSIC UI UNITY FAILURES=",failures)
    quit(0 if failures == 0 else 1)

func _initialize() -> void:
    call_deferred("run")
