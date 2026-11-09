extends SceneTree
# Verify that Zen Challenges use the SAME interactive 3D board and restore Classic.
var checks: int = 0
var failures: int = 0
func check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        printerr("CHALLENGE FAIL: " + message)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var scene = load("res://Main.tscn") as PackedScene
    check(scene != null, "Main.tscn loads")
    if scene == null:
        quit(1)
        return
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    check(game.challenges != null and game.challenges.valid, "challenge pack loads and matches original 108 lines")
    if not game.challenges.valid:
        quit(1)
        return
    check(game.challenges.puzzles.size() == 30, "30 puzzles present")
    check(game.renderer.tiles.size() == 54, "original 3D board is present")
    check(game.music_player != null and game.music_player.stream != null, "original music stream present")
    game.data.settings.swap = false
    game.start_mode(0)
    game.on_cell(4)
    game.on_cell(28)
    var classic = game.board.snapshot()
    var history = game.board.history.duplicate(true)
    var stats = game.data.stats.duplicate(true)
    var disk = SaveManager.load_data().game.duplicate(true)
    var renderer = game.renderer
    var music = game.music_player
    game.begin_challenges()
    check(game.challenge_active, "challenge mode activated")
    check(game.renderer == renderer, "3D renderer is reused")
    check(game.music_player == music, "music player is reused")
    check(game.challenge_row.visible and not game.classic_actions.visible, "challenge controls replace Classic controls")
    for i in range(30):
        game.open_challenge_number(i)
        var p: Dictionary = game.challenges.puzzle(i)
        var first: int = int(p.solutions[0])
        var expected_cells: Array = []
        expected_cells.resize(54)
        expected_cells.fill(0)
        for c in p.x: expected_cells[int(c)] = 1
        for c in p.o: expected_cells[int(c)] = 2
        check(game.board.cells == expected_cells, "initial board matches puzzle %d" % (i+1))
        check(game.rules.victories(game.board.cells,1).is_empty() and game.rules.victories(game.board.cells,2).is_empty(), "puzzle %d has no preexisting winner" % (i+1))
        # Reject a wrong move without changing the board.
        var wrong := -1
        for c in range(54):
            if game.board.cells[c] == 0 and not p.solutions.has(c):
                wrong = c
                break
        if wrong >= 0:
            game.on_cell(wrong)
            check(game.board.cells == expected_cells and game.challenge_phase == 0, "wrong choice is non-destructive, puzzle %d" % (i+1))
        game.on_cell(first)
        if p.kind == "fork":
            check(game.challenge_phase == 1, "fork puzzle %d asks for second move" % (i+1))
            var replies: Array = game.rules.threats(game.board.cells,1)
            check(not replies.is_empty(), "fork puzzle %d has remaining win" % (i+1))
            if not replies.is_empty(): game.on_cell(int(replies[0]))
        else:
            check(game.challenge_phase == 2, "one-move puzzle %d solved" % (i+1))
        check(game.challenge_phase == 2, "puzzle %d completed" % (i+1))
        check(game.challenges.solved.has(str(i+1)), "puzzle %d progress persisted" % (i+1))
    check(game.challenges.solved.size() == 30, "thirty progress leaves tracked")
    check(game.data.stats == stats, "puzzles do not count as Classic matches")
    check(SaveManager.load_data().game == disk, "puzzles have not overwritten on-disk Classic game")
    game.leave_challenges()
    check(not game.challenge_active, "exit restores Classic")
    check(game.board.snapshot() == classic, "all Classic board state restored")
    check(game.board.history == history, "Classic undo history restored")
    check(game.renderer == renderer and game.music_player == music, "renderer and music preserved after exit")
    check(game.classic_actions.visible and not game.challenge_row.visible, "Classic controls restored")
    game.queue_free()
    await process_frame
    print("ZEN CHALLENGES CHECKS=%d FAILURES=%d" % [checks,failures])
    quit(0 if failures == 0 else 1)
