extends SceneTree

const Tower = preload("res://core/ZenTower.gd")
var failures: int = 0

func check(ok: bool, message: String) -> void:
    if ok:
        print("PASS: ",message)
    else:
        failures += 1
        printerr("FAIL: ",message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var data := SaveManager.defaults()
    var state := Tower.ensure(data)

    check(Tower.new_run(data),"New run")
    check(int(state.lives)==5,"Five lives")
    check(Tower.begin_floor(data),"First board")
    check(state.game.cells.size()==54,"54 cells")
    check(not Tower.begin_floor(data),"No duplicate board")

    var rules := RulesEngine.new()
    var line: Array = rules.lines[0]

    for stage in [15,30,45,60,75,90,100]:
        state.floor = stage
        state.game = {}
        check(Tower.begin_floor(data),"Begin boss "+str(stage))

        var board := BoardModel.new()
        board.swap_enabled = false

        for j in range(3):
            board.cells[int(line[j])] = 1

        state.game = board.snapshot()

        check(Tower.play(data,int(line[3]),1),"Winning move")
        var result := Tower.settle(data)

        check(int(result.get("winner",0))==1,"First round victory")
        check(int(result.get("life_bonus",0))==0,"No bonus before series win")
        check(int(state.floor)==stage,"Stay for second round")
        check(Tower.settle(data).is_empty(),"No duplicate round result")
        check(Tower.begin_floor(data),"Second boss round")
        board = BoardModel.new()
        board.swap_enabled = false
        for j in range(3):
            board.cells[int(line[j])] = 1
        state.game = board.snapshot()
        check(Tower.play(data,int(line[3]),1),"Second winning move")
        result = Tower.settle(data)
        check(bool(result.get("series_complete",false)),"Series victory")
        check(int(result.get("life_bonus",0))==3,"Boss life bonus")
        check(int(state.floor)==stage+1,"Next floor")
        check(Tower.settle(data).is_empty(),"No duplicate reward")

    check(state.cards.size()==7,"Seven unique guardian cards")
    check(int(state.record)==100,"Milestone record")
    check(Tower.section_index(61)==4,"Frostveil section")
    check(Tower.is_boss(100),"Hundredth floor boss")

    state.lives = 5
    state.active = true
    state.game = {}
    state.floor = 5

    for attempt in range(5):
        check(Tower.begin_floor(data),"Retry board")
        var board := BoardModel.new()
        board.swap_enabled = false
        board.turn = 2

        for j in range(3):
            board.cells[int(line[j])] = 2

        state.game = board.snapshot()
        check(Tower.play(data,int(line[3]),2),"Losing move")
        Tower.settle(data)

        check(int(state.lives)==4-attempt,"Life consumed")

    check(not bool(state.active),"Game over")
    check(Tower.new_run(data),"Restart tower")
    check(int(state.floor)==1,"Restart at floor one")
    check(int(state.lives)==5,"Lives restored")
    check(state.cards.size()==7,"Gallery survives restart")
    check(int(state.record)==100,"Record survives restart")

    Tower.begin_floor(data)

    var roundtrip: Dictionary = JSON.parse_string(
        JSON.stringify(data))

    check(SaveManager.valid_game(roundtrip.tower.game),
        "JSON board roundtrip")

    var renderer := CubeRenderer.new()
    root.add_child(renderer)
    await process_frame

    renderer.apply_skin(3)
    var original: Color = renderer.face_color(0)

    for index in range(7):
        renderer.set_tower_skin(index)
        renderer.paint(BoardModel.new(),false)
        check(renderer.skin_id==3,"Shop selection preserved")
        check(renderer.tiles.size()==54,"Geometry preserved")
        check(is_instance_valid(renderer.tower_trim),"Tower ornament")
        check(renderer.face_color(0)!=original,"Tower color")

        var color_board := BoardModel.new()

        for face in range(6):
            color_board.cells[face * 9] = 1
            color_board.cells[face * 9 + 1] = 2

        renderer.selected = 1
        renderer.paint(color_board, false)

        for face in range(6):
            var x_mark: MeshInstance3D = renderer.marks[face * 9].get_child(2) as MeshInstance3D
            var o_mark: MeshInstance3D = renderer.marks[face * 9 + 1].get_child(1) as MeshInstance3D

            var x_mat: StandardMaterial3D = x_mark.material_override as StandardMaterial3D
            var o_mat: StandardMaterial3D = o_mark.material_override as StandardMaterial3D

            check(x_mat.albedo_color == Color("ffe1a0"),
                "Stable Tower X color")
            check(o_mat.albedo_color == Color("94ffda"),
                "Stable Tower O color")

        renderer.selected = -1

    renderer.set_tower_skin(-1)
    renderer.paint(BoardModel.new(),false)

    check(renderer.face_color(0)==original,"Original color restored")
    check(renderer.skin_id==3,"Original skin restored")
    check(renderer.tower_trim==null,"Tower ornament removed")

    renderer.queue_free()
    await process_frame

    print("ZEN TOWER TEST FAILURES: ",failures)
    quit(1 if failures>0 else 0)
