extends SceneTree
# End-of-match observation must keep the 96-cell board immutable while
# allowing rotate/zoom and reopening the result. Does not change real saves.
var errors: int = 0

func check(ok: bool, description: String) -> void:
    if not ok:
        errors += 1
        printerr("POST-MATCH REVIEW FAIL: ", description)

func _initialize() -> void:
    call_deferred("run")

func _touch(game: Node, index: int, position: Vector2, pressed: bool) -> void:
    var ev: InputEventScreenTouch = InputEventScreenTouch.new()
    ev.index = index
    ev.position = position
    ev.pressed = pressed
    game.call("cube_input",ev)

func _drag(game: Node, index: int, position: Vector2, relative: Vector2) -> void:
    var ev: InputEventScreenDrag = InputEventScreenDrag.new()
    ev.index = index
    ev.position = position
    ev.relative = relative
    game.call("cube_input",ev)

func run() -> void:
    var path: String = SaveManager.PATH
    var existed: bool = FileAccess.file_exists(path)
    var saved: PackedByteArray = FileAccess.get_file_as_bytes(path) if existed else PackedByteArray()
    var data: Dictionary = SaveManager.defaults()
    data.ascension.rank = 3
    data.ascension.completed = [true,true,true,false,false]
    data.ascend.help_seen = true
    data.settings.language = "de"
    check(SaveManager.save_data(data),"seed Zen Master entitlement")

    var scene: PackedScene = load("res://Ascend.tscn") as PackedScene
    check(scene != null,"Zen Ascend scene can load")
    if scene == null:
        quit(1)
        return
    var controller: Node = scene.instantiate()
    root.add_child(controller)
    await process_frame
    var cube: AscendRenderer = controller.get("cube") as AscendRenderer
    check(cube != null,"real 3D Ascend renderer exists")
    var board: Array = controller.get("cells")
    var winning: Array = ZenAscend.generate_lines()[0]
    board.fill(0)
    for i in range(4):
        board[int(winning[i])] = 2
    controller.set("cells",board)
    controller.set("result",2) # Bot won; same controls work for wins and draws.
    controller.set("recorded",true)
    controller.set("busy",false)
    controller.call("draw")
    var before: Array = board.duplicate()
    var leaves_before: int = int((controller.get("data") as Dictionary).economy.leaves)
    var button: Button = controller.get("result_review_button") as Button
    var rules_button: Button = controller.get("rules_button") as Button
    check(button != null and button.visible,"result reopen button appears at game end")
    check(rules_button != null and not rules_button.visible,"review replaces rules without extra screen space")
    check(cube.winner_cells.size() == 4,"finished 4-in-a-row highlighted")

    controller.call("show_match_result")
    var dialog: Node = controller.get("active_realm_dialog")
    var review: Button = dialog.find_child("InspectFinishedBoard",true,false) as Button
    check(review != null and review.text == "Spielfeld ansehen","inspect board action on loss popup")
    if review != null: review.pressed.emit()
    check(controller.get("active_realm_dialog") == null,"inspect closes overlay but keeps result")

    var initial_rotation: Basis = cube.pivot.basis
    _touch(controller,0,Vector2(270,340),true)
    _drag(controller,0,Vector2(360,400),Vector2(90,60))
    _touch(controller,0,Vector2(360,400),false)
    check(not cube.pivot.basis.is_equal_approx(initial_rotation),"touch swipe rotates cube after loss")
    check((controller.get("cells") as Array) == before,"rotation does not touch board")

    var old_zoom: float = cube.camera.position.z
    _touch(controller,0,Vector2(210,340),true)
    _touch(controller,1,Vector2(290,340),true)
    _drag(controller,1,Vector2(350,340),Vector2(60,0))
    _touch(controller,1,Vector2(350,340),false)
    _touch(controller,0,Vector2(210,340),false)
    check(absf(cube.camera.position.z-old_zoom) > 0.01,"two-finger zoom works after loss")
    check((controller.get("cells") as Array) == before,"zoom does not add a move")

    # Final positions are strictly read-only even if play() is invoked manually.
    controller.call("play",92)
    check((controller.get("cells") as Array) == before,"no marks may be placed after completion")
    button.pressed.emit()
    check(controller.get("active_realm_dialog") != null,"result can be reopened without replay")
    check(int((controller.get("data") as Dictionary).economy.leaves) == leaves_before,"review adds no leaves/rewards")
    var second: Node = controller.get("active_realm_dialog")
    controller.call("_review_finished_board",second)

    controller.set("result",1) # Same interaction must work after a human win.
    controller.call("draw")
    check(button.visible,"inspect button appears after victory")
    var win_rotation: Basis = cube.pivot.basis
    _touch(controller,0,Vector2(255,300),true)
    _drag(controller,0,Vector2(330,300),Vector2(75,0))
    _touch(controller,0,Vector2(330,300),false)
    check(not cube.pivot.basis.is_equal_approx(win_rotation),"touch swipe rotates cube after victory")

    # Boss story results retain their resume/retry dialogue after inspection.
    controller.set("realm_story_active",true)
    controller.set("realm_story_stage",3)
    controller.set("result",2)
    controller.call("_realm_story_result")
    var story_dialog: Node = controller.get("active_realm_dialog")
    var story_review: Button = story_dialog.find_child("InspectFinishedBoard",true,false) as Button
    check(story_review != null,"Ember boss loss also has inspect button")
    if story_review != null: story_review.pressed.emit()
    check(controller.get("active_realm_dialog") == null,"boss review closes dialogue")
    button.pressed.emit()
    check(controller.get("active_realm_dialog") != null,"boss result reopens with retry action")
    var open_dialog: Node = controller.get("active_realm_dialog")
    controller.call("_review_finished_board",open_dialog)
    controller.set("realm_story_active",false)
    controller.call("start_game",true)
    check(int(controller.get("result")) == 0 and not button.visible and rules_button.visible,"new match clears review and restores rules")

    controller.queue_free()
    await process_frame
    if existed:
        var restore: FileAccess = FileAccess.open(path,FileAccess.WRITE)
        if restore != null:
            restore.store_buffer(saved)
            restore.close()
    elif FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("POST-MATCH REVIEW FAILURES=",errors)
    quit(0 if errors == 0 else 1)
