extends SceneTree
# Integration test: 100 challenges on the same interactive 3D board as Classic.
var checks := 0
var failures := 0
func verify(condition: bool, name: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        printerr("CHALLENGE FAIL: " + name)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var packed := load("res://Main.tscn") as PackedScene
    verify(packed != null, "main scene available")
    if packed == null:
        quit(1)
        return
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame
    verify(game.challenges != null and game.challenges.valid, "100-puzzle challenge pack validated")
    if game.challenges == null or not game.challenges.valid:
        quit(1)
        return
    verify(game.challenges.puzzles.size() == 100, "100 puzzles in one archive")
    verify(game.renderer.tiles.size() == 54, "54 tiles on original 3D cube")
    verify(game.music_player != null and game.music_player.stream != null, "music retained")
    game.data.settings.swap = false
    game.start_mode(0)
    game.on_cell(4)
    game.on_cell(28)
    var original_board = game.board.snapshot()
    var original_history = game.board.history.duplicate(true)
    var original_stats = game.data.stats.duplicate(true)
    var saved_disk = SaveManager.load_data().game.duplicate(true)
    var original_renderer = game.renderer
    var original_music = game.music_player
    game.begin_challenges()
    verify(game.challenge_active, "challenge mode activated")
    verify(game.renderer == original_renderer and game.music_player == original_music, "3D scene and music preserved")
    verify(game.challenge_row.visible and not game.classic_actions.visible, "challenge actions shown")
    for level in range(1,6):
        var count:=0
        for puzzle in game.challenges.puzzles:
            if int(puzzle.level)==level: count+=1
        verify(count==20, "20 puzzles at level %d" % level)
    for i in range(100):
        game.open_challenge_number(i)
        var puzzle: Dictionary = game.challenges.puzzle(i)
        var before = game.board.cells.duplicate()
        var expected: Array = []
        expected.resize(54)
        expected.fill(0)
        for c in puzzle.x: expected[int(c)]=1
        for c in puzzle.o: expected[int(c)]=2
        verify(before==expected,"initial position %d"%(i+1))
        verify(game.rules.victories(game.board.cells,1).is_empty() and game.rules.victories(game.board.cells,2).is_empty(), "no initial winner %d"%(i+1))
        var correct: int = int(puzzle.solutions[0])
        var wrong := -1
        for c in range(54):
            if game.board.cells[c]==0 and not puzzle.solutions.has(c):
                wrong=c
                break
        if wrong>=0:
            game.on_cell(wrong)
            verify(game.board.cells==before and game.challenge_phase==0,"invalid move rejected %d"%(i+1))
        if puzzle.kind == "sequence":
            var path: Array = puzzle.path
            for move_i in range(int(puzzle.moves)-1):
                var step_cell: int = int(path[2*move_i])
                game.on_cell(step_cell)
                verify(game.challenge_phase==move_i+1,"bot response %d move %d"%[i+1,move_i+1])
            var final_wins: Array = game.rules.threats(game.board.cells,1)
            verify(not final_wins.is_empty(),"winning finish offered %d"%(i+1))
            if not final_wins.is_empty(): game.on_cell(int(final_wins[0]))
        elif puzzle.kind == "fork":
            game.on_cell(correct)
            verify(game.challenge_phase==1,"fork triggers bot defense %d"%(i+1))
            var fork_wins: Array = game.rules.threats(game.board.cells,1)
            verify(not fork_wins.is_empty(),"fork has surviving win %d"%(i+1))
            if not fork_wins.is_empty(): game.on_cell(int(fork_wins[0]))
        else:
            game.on_cell(correct)
        verify(game.challenge_phase==-1, "puzzle completed %d"%(i+1))
        verify(game.challenges.solved.has(str(i+1)),"progress saved %d"%(i+1))
    verify(game.challenges.solved.size()==100,"100 zen leaves tracked")
    verify(game.data.stats==original_stats,"no influence on Classic statistics")
    verify(SaveManager.load_data().game==saved_disk,"no overwrite of Classic save on disk")
    game.leave_challenges()
    verify(not game.challenge_active,"returns to Classic")
    verify(game.board.snapshot()==original_board,"Classic position restored")
    verify(game.board.history==original_history,"undo history restored")
    verify(game.renderer==original_renderer and game.music_player==original_music,"3D renderer and music stay alive")
    verify(game.classic_actions.visible and not game.challenge_row.visible,"Classic controls restored")
    game.queue_free()
    await process_frame
    print("ZEN CHALLENGES V9 CHECKS=%d FAILURES=%d"%[checks,failures])
    quit(0 if failures==0 else 1)
