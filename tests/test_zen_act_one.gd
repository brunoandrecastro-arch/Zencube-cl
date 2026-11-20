extends SceneTree

const Act = preload("res://story/ZenActOne.gd")
var failures := 0
var backups: Dictionary = {}

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        printerr("ACT I: " + message)

func play_result(target: int) -> BoardModel:
    var board := Act.new_board()
    var rules := RulesEngine.new()
    var line: Array = rules.lines[0]
    var index := 0
    while board.winner == 0 and index < 12:
        if board.turn == target:
            check(rules.play(board, int(line[board.cells.count(target)])), "legal target move")
        else:
            for cell in range(54):
                if line.has(cell) or board.cells[cell] != 0: continue
                var candidate: Array = board.cells.duplicate()
                candidate[cell] = board.turn
                if rules.victories(candidate, board.turn).is_empty():
                    check(rules.play(board, cell), "legal filler")
                    break
        index += 1
    return board

func run() -> void:
    for path in [Act.SAVE_FILE, SaveManager.PATH]:
        if FileAccess.file_exists(path):
            backups[path] = FileAccess.get_file_as_bytes(path)
            DirAccess.remove_absolute(path)
    var classic := SaveManager.defaults()
    classic.settings.merge({"language": "en", "intro_seen": true, "music": false}, true)
    classic.economy.leaves = 37
    check(SaveManager.save_data(classic), "seed Classic")
    var scene := load("res://Main.tscn") as PackedScene
    var game := scene.instantiate()
    root.add_child(game)
    current_scene = game
    await process_frame
    game.close_modal()
    var reader := root.get_node("ZenChronicles")
    var before: String = FileAccess.get_file_as_string(SaveManager.PATH)
    var original: Dictionary = game.board.snapshot()
    check(game.rules.lines.size() == 108, "108 Classic lines")
    for n in range(1, 13):
        check(ResourceLoader.exists(Act.page_path(n)), "original page " + str(n))
    check(ResourceLoader.exists(Act.REFERENCE), "master reference")
    check(Act.config().get("id") == "zen_master_trial", "config is packaged")
    reader.open_library()
    reader.open_act_one()
    for n in range(10): reader._act_one_turn(1)
    check(reader._page_counter.text == "11 / 12", "reader reaches page eleven")
    reader._act_one_turn(1)
    check(reader._screen_name == "act-one-gate", "trial gate")
    check(Act.max_page(Act.load_progress()) == 11, "page 12 locked before victory")
    game.start_act_one_trial()
    check(game.act_one_active and game.board.cells.size() == 54 and game.board.owners == [0, 1], "real Classic board")
    game.on_cell(0)
    game._act_one_leave()
    check(game.board.snapshot() == original, "restore Classic board")
    check(Act.load_progress().game.cells[0] == 1, "running game saved")
    reader.open_act_one_gate()
    game.start_act_one_trial()
    check(game.board.cells[0] == 1, "running game resumed")
    game.board = play_result(2)
    check(game.board.winner == 2, "real O victory")
    game._act_one_result()
    check(Act.max_page(Act.load_progress()) == 11, "loss stays locked")
    game._act_one_retry()
    check(game.board.move_count() == 0, "same trial restarts")
    var fixture: Array = JSON.parse_string(FileAccess.get_file_as_string("res://reports/draw_fixture.json"))
    for ply in range(54):
        var chosen := -1
        for i in range(54):
            if game.board.cells[i] == 0 and int(fixture[i]) == game.board.turn:
                chosen = i
                break
        check(game.rules.play(game.board, chosen), "play draw fixture")
    check(game.board.winner == 3, "real draw")
    game._act_one_result()
    check(Act.max_page(Act.load_progress()) == 11, "draw stays locked")
    game._act_one_retry()
    game.board = play_result(1)
    check(game.board.winner == 1, "real X victory")
    game._act_one_result()
    check(Act.load_progress().won and Act.max_page(Act.load_progress()) == 11, "win saved, dialogue still required")
    game._inspect_classic_finished_board()
    check(game.popup == null and game.board.winner == 1, "finished board inspection")
    game._act_one_result()
    game._act_one_continue()
    check(Act.max_page(Act.load_progress()) == 12 and reader._page_counter.text == "12 / 12", "victory opens finale")
    reader._act_one_turn(1)
    check(Act.load_progress().complete, "act completed")
    check(FileAccess.get_file_as_string(SaveManager.PATH) == before, "Classic save unchanged")
    reader.close_chronicles()
    reader.open_act_one()
    check(reader._page_counter.text == "12 / 12", "saved victory does not require replay")
    reader.close_chronicles()
    game.queue_free()
    await process_frame
    for path in [Act.SAVE_FILE, SaveManager.PATH]:
        if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
        if backups.has(path):
            var file := FileAccess.open(path, FileAccess.WRITE)
            file.store_buffer(backups[path])
            file.close()
    print("ACT I FAILURES=", failures)
    quit(0 if failures == 0 else 1)
