extends SceneTree
var checks := 0
var failures := 0
func check(v: bool, msg: String) -> void:
    checks += 1
    if not v:
        failures += 1
        printerr("UI FAIL: "+msg)
func find_button(node: Node, title: String) -> Button:
    if node is Button and node.text == title: return node
    for child in node.get_children():
        var found := find_button(child,title)
        if found != null: return found
    return null
func press_button(node: Node, title: String) -> bool:
    var b := find_button(node,title)
    if b == null: return false
    b.pressed.emit()
    return true
func _initialize() -> void:
    call_deferred("run")
func shot(name: String) -> void:
    if DisplayServer.get_name() == "headless":
        return # UI behavior tests can run headlessly; screenshots require a real render backend.
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://reports/"+name+".png")
func run() -> void:
    var controller: Script = load("res://ui/GameController.gd") as Script
    if controller == null:
        printerr("FATAL: GameController.gd could not be loaded. See GDScript parse errors above.")
        quit(1)
        return
    var compile_result: Error = controller.reload()
    if compile_result != OK or not controller.can_instantiate():
        printerr("FATAL: GameController.gd did not compile: ", error_string(compile_result))
        quit(1)
        return
    var main_scene = load("res://Main.tscn") as PackedScene
    if main_scene == null:
        printerr("FATAL: Main.tscn did not load")
        quit(1)
        return
    var game = main_scene.instantiate()
    if game.get_script() == null or not game.has_method("open_welcome"):
        printerr("FATAL: Main.tscn root has NO working GameController.gd! Loaded: ",game.get_class()," / ",game.get_script())
        game.free()
        quit(1)
        return
    root.add_child(game)
    await process_frame
    if game.ui == null or game.renderer == null:
        printerr("FATAL: Main scene missing UI or cube. Review runtime errors above.")
        quit(1)
        return
    # A first-time user must see onboarding, not a forced second-player match.
    game.open_welcome()
    check(game.popup != null,"welcome overlay opens")
    check(find_button(game.popup,"Mini-Tutorial starten") != null,"welcome has visual tutorial")
    check(find_button(game.popup,"Direkt gegen Zen-Bot spielen") != null,"welcome can start versus bot")
    check(press_button(game.popup,"Direkt gegen Zen-Bot spielen"),"welcome start button connected")
    check(game.popup == null and int(game.data.settings.mode) == 1 and int(game.data.settings.level) == 0,"first game is easy bot")
    check(game.board.move_count() == 0,"first match empty")
    await physics_frame
    await process_frame
    check(game.renderer.tiles.size() == 54,"54 renderable tiles")
    for f in range(6):
        game.renderer.focus_faces([f])
        await physics_frame
        await process_frame
        for c in range(f*9,f*9+9):
            var world = game.renderer.pivot.to_global(CubeGeometry.center(c,1.55))
            var screen = game.renderer.camera.unproject_position(world)
            check(game.renderer.pick(screen) == c,"ray picking for each face")
    game.renderer.reset_view()
    await shot("v3-01-zen-garden.png")
    var before: Basis = game.renderer.pivot.basis
    game.renderer.rotate_cube(Vector2(30,20))
    check(not before.is_equal_approx(game.renderer.pivot.basis),"cube still rotates")
    var z_before: float = game.renderer.camera.position.z
    game.renderer.zoom(0.90)
    check(game.renderer.camera.position.z < z_before,"pinch zoom logic")
    # Prevent a tiny gesture from accidentally placing a marker.
    game.data.settings.mode = 0
    game.data.settings.swap = false
    game.new_game()
    game.renderer.focus_faces([0])
    await physics_frame
    var pos: Vector2 = game.renderer.camera.unproject_position(game.renderer.pivot.to_global(CubeGeometry.center(4,1.55)))
    var touch = InputEventScreenTouch.new()
    touch.index = 0;touch.position = pos;touch.pressed = true
    game.input_control.handle(touch)
    touch.pressed = false
    game.input_control.handle(touch)
    check(game.board.cells[4] == 1,"single tap makes exactly one move")
    game.undo()
    check(game.board.move_count() == 0,"undo works")
    touch.pressed = true;game.input_control.handle(touch)
    var drag = InputEventScreenDrag.new()
    drag.index = 0;drag.position = pos+Vector2(40,0);drag.relative = Vector2(40,0)
    game.input_control.handle(drag)
    touch.position = drag.position;touch.pressed = false;game.input_control.handle(touch)
    check(game.board.move_count() == 0,"drag never commits a move")
    game.start_tutorial()
    game.tutorial.step = 2
    game.load_tutorial()
    check(game.preview.size() == 4,"3+1 tutorial shows exactly four cells")
    await shot("v3-02-tutorial-3plus1.png")
    game.on_cell(game.preview[3])
    check(game.board.winner == 1,"tutorial 3+1 completes win")
    await shot("v3-03-edge-win.png")
    game.tutorial.step = 3
    game.load_tutorial()
    check(game.preview.size() == 4,"2+2 tutorial shows four cells")
    game.on_cell(game.preview[3])
    check(game.board.winner == 1,"tutorial 2+2 completes win")
    game.end_tutorial()
    check(game.board.move_count() == 0,"tutorial restores original game")
    game.open_menu()
    await shot("v3-04-menu.png")
    check(find_button(game.popup,"Schnell starten  ·  gegen Zen-Bot") != null,"bot-first menu")
    check(press_button(game.popup,"Einstellungen"),"settings button connected")
    check(game.popup != null and find_button(game.popup,"Fertig") != null,"settings show")
    check(press_button(game.popup,"Fertig") and game.popup == null,"settings close")
    game.open_menu()
    check(press_button(game.popup,"Zwei Spieler lokal"),"local multiplayer option")
    check(int(game.data.settings.mode)==0,"local mode starts")
    game.place(4)
    check(press_button(game.ui,"Neue Partie"),"new-game button connected")
    check(game.popup != null,"new-game confirmation")
    check(press_button(game.popup,"Neu starten"),"confirmation works")
    check(game.board.move_count()==0 and game.popup == null,"new game really clears the board")
    game.data.settings.alternate = true
    game.data.settings.next_start = 0
    game.new_game()
    # Four X and three O, no incidental earlier win.
    var line = game.rules.lines[0]
    var others: Array = []
    for c in range(54):
        if not line.has(c): others.append(c)
    for i in range(4):
        game.place(line[i])
        if i<3: game.place(others[i])
    check(game.board.winner==1 and game.board.result_recorded,"4-cross-face local victory recorded")
    var played = game.data.stats.played
    game.undo()
    check(game.board.winner==1 and played==game.data.stats.played,"finished game immutable")
    game.new_game()
    check(game.board.current_owner()==1,"starter alternates")
    game.persist()
    var saved = SaveManager.load_data()
    check(int(saved.version)==3,"new save version")
    check(saved.game.cells.size()==54,"new save is valid")
    game.queue_free()
    await process_frame
    var result={"checks":checks,"failures":failures,"scope":"godot ui scene and signal tests; physical Android touches require device test"}
    FileAccess.open("res://reports/ui-tests.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
    print(JSON.stringify(result))
    quit(0 if failures == 0 else 1)
