extends SceneTree

const Tower = preload("res://core/ZenTower.gd")
const Cinematics = preload("res://core/ZenTowerCinematics.gd")
const Grid = preload("res://core/ZenTowerGrid.gd")
const Existing = preload("res://core/ZenAscend.gd")
var checks: int = 0
var failed: bool = false

func verify(condition: bool, message: String) -> void:
    if not condition:
        failed = true
        push_error("FAIL: " + message)
        quit(1)
        assert(condition, message)
    checks += 1

func fresh(stage: int, lives: int = 5) -> Dictionary:
    var data: Dictionary = SaveManager.defaults()
    Tower.new_run(data)
    data.tower.floor = stage
    data.tower.lives = lives
    Tower.begin_floor(data)
    return data

func finish_round(data: Dictionary, winner: int) -> Dictionary:
    var side: int = Tower.board_size(int(data.tower.floor))
    var board: BoardModel = Tower.new_board(side)
    var rules: RulesEngine = Tower.make_rules(side)
    if winner in [1, 2]:
        var line: Array = rules.lines[0]
        for cell in line:
            board.cells[int(cell)] = winner
        board.win_lines = [line.duplicate()]
        board.last_cell = int(line.back())
    board.winner = winner
    board.turn = 2 if winner == 1 else 1
    data.tower.game = board.snapshot()
    return Tower.settle(data)

func line_keys(lines: Array) -> Array:
    var keys: Array = []
    for line in lines:
        var sorted_line: Array = line.duplicate()
        sorted_line.sort()
        keys.append(str(sorted_line))
    keys.sort()
    return keys

func _init() -> void:
    var catalog: Dictionary = Tower.manifest()
    verify(catalog.sections.size() == 7, "seven sections")
    verify(catalog.guardians.size() == 7, "seven guardians")
    verify(int(catalog.image_count) == 35, "35 combined image entries")
    for row in [
        [60, 3, true], [61, 4, false], [74, 4, false], [75, 4, true],
        [76, 5, false], [89, 5, false], [90, 5, true], [91, 6, false],
        [99, 6, false], [100, 6, true], [101, 0, false], [115, 0, true],
        [200, 6, true],
    ]:
        verify(Tower.section_index(int(row[0])) == int(row[1]), "section at %s" % row[0])
        verify(Tower.is_boss(int(row[0])) == bool(row[2]), "boss at %s" % row[0])
    verify(Tower.board_size(100) == 3 and Tower.board_size(101) == 4, "100 to 101 board switch")
    verify(not Tower.is_boss(0), "invalid floor has no boss")
    var lines: Array = Grid.generate_lines()
    verify(lines.size() == 204, "204 4x4 winning lines")
    verify(line_keys(lines) == line_keys(Existing.generate_lines()), "same topology as existing 4x4")
    var unique: Dictionary = {}
    for line in lines:
        verify(line.size() == 4, "line length")
        var sorted_line: Array = line.duplicate()
        sorted_line.sort()
        unique[str(sorted_line)] = true
        for cell in line:
            verify(int(cell) >= 0 and int(cell) < 96, "line cell range")
    verify(unique.size() == 204, "no duplicate winning lines")
    var four: BoardModel = Tower.new_board(4)
    var four_rules: RulesEngine = Tower.make_rules(4)
    verify(four.cells.size() == 96 and four.move_count() == 0, "empty four board")
    verify(four_rules.play(four, 95) and four.move_count() == 1, "cell 95 is playable")
    verify(not four_rules.play(four, 95), "occupied cell rejected")
    verify(not four_rules.play(four, 96) and not four_rules.play(four, -1), "invalid cell rejected")
    verify(Tower.valid_game(four.snapshot(), 96), "4x4 snapshot valid")
    verify(not SaveManager.valid_game(four.snapshot()), "classic save validator remains unchanged")
    var copied: BoardModel = Tower.new_board(4)
    copied.restore(JSON.parse_string(JSON.stringify(four.snapshot())))
    verify(copied.cells == four.cells and copied.move_count() == 1, "4x4 save roundtrip")
    for cross_edge in [false, true]:
        var chosen: Array = []
        for line in lines:
            if (Grid.face(int(line.front())) != Grid.face(int(line.back()))) == cross_edge:
                chosen = line
                break
        var winning_board: BoardModel = Tower.new_board(4)
        for i in range(3):
            winning_board.cells[int(chosen[i])] = 1
        verify(four_rules.play(winning_board, int(chosen[3])), "winning fourth move")
        verify(winning_board.winner == 1, "4x4 face or edge victory")
    var classic: BoardModel = Tower.new_board(3)
    verify(classic.cells.size() == 54 and Tower.make_rules(3).lines.size() == 108, "classic rules retained")
    for path in ["res://assets/video/tower_rootbound_warden_defeat.ogv", "res://assets/video/tower_windweave_keeper_defeat.ogv", "res://assets/video/tower_stillwater_dragon_defeat.ogv", "res://assets/video/tower_amber_fox_defeat.ogv", "res://assets/video/tower_snowbound_kirin_defeat.ogv", "res://assets/video/tower_dawnwing_crane_defeat.ogv", "res://assets/video/tower_eclipse_sovereign_defeat.ogv", "res://assets/video/tower_root_to_wind_gate.ogv", "res://assets/video/tower_wind_to_water_gate.ogv", "res://assets/video/tower_water_to_amber_gate.ogv", "res://assets/video/tower_amber_to_frost_gate.ogv", "res://assets/video/tower_frost_to_dawn_gate.ogv", "res://assets/video/tower_dawn_to_eclipse_gate.ogv", "res://assets/video/tower_eclipse_to_ascend_gate.ogv"]:
        verify(ResourceLoader.exists(path) and load(path) is VideoStream, "native video resource: " + path)
    verify(Cinematics.transition_for({"winner":1,"floor_complete":true,"completed_floor":1,"next_floor":2}) == "", "normal floor advances without animation")
    verify(Tower.MAX_LIVES == 5, "five starting lives")
    verify(Tower.difficulty(1,0.0)==0,"easy entry")
    verify(Tower.difficulty(15,0.0)==1,"first boss medium")
    verify(Tower.difficulty(30,0.0)==1,"second boss medium")
    verify(Tower.difficulty(45,0.0)==1,"third boss medium")
    verify(Tower.difficulty(60,0.0)==2,"fourth boss hard")
    verify(Tower.difficulty(100,0.0)==2,"milestone boss hard")
    verify(Tower.difficulty(101,0.9)==0,"gentle 4x4 entry")
    verify(Tower.difficulty(201,0.0)==2,"late floor hard")
    verify(Tower.difficulty(215,0.0)==3,"late boss master")
    var bosses: Array = [15, 30, 45, 60, 75, 90, 100]
    for boss in bosses:
        var data: Dictionary = fresh(int(boss))
        var first: Dictionary = finish_round(data, 1)
        verify(not bool(first.series_complete) and not bool(first.floor_complete), "first boss win keeps series open")
        verify(int(data.tower.floor) == int(boss) and int(data.tower.lives) == 5, "no early floor or life reward")
        verify(int(first.reward) == 0 and data.tower.cards.is_empty(), "no early currency or card")
        verify(Cinematics.defeat_for(first).is_empty() and Cinematics.transition_for(first).is_empty(), "no video on individual boss round")
        Tower.begin_floor(data)
        var second: Dictionary = finish_round(data, 1)
        verify(bool(second.series_complete) and bool(second.floor_complete), "two wins finish series")
        verify(int(data.tower.floor) == int(boss) + 1 and int(data.tower.lives) == 8, "stage advance and 5 plus 3 lives")
        verify(int(second.life_bonus) == 3 and data.tower.cards.size() == 1, "one life bonus and one card")
        var expected_clip: String = ["res://assets/video/tower_rootbound_warden_defeat.ogv", "res://assets/video/tower_windweave_keeper_defeat.ogv", "res://assets/video/tower_stillwater_dragon_defeat.ogv", "res://assets/video/tower_amber_fox_defeat.ogv", "res://assets/video/tower_snowbound_kirin_defeat.ogv", "res://assets/video/tower_dawnwing_crane_defeat.ogv", "res://assets/video/tower_eclipse_sovereign_defeat.ogv"][bosses.find(boss)]
        verify(Cinematics.defeat_for(second) == expected_clip, "first series win selects only matching clip")
        var repeat := second.duplicate(true)
        repeat.unlocked_card = ""
        verify(Cinematics.defeat_for(repeat).is_empty(), "repeat wins do not replay automatically")
        var expected_transition: String = ["res://assets/video/tower_root_to_wind_gate.ogv", "res://assets/video/tower_wind_to_water_gate.ogv", "res://assets/video/tower_water_to_amber_gate.ogv", "res://assets/video/tower_amber_to_frost_gate.ogv", "res://assets/video/tower_frost_to_dawn_gate.ogv", "res://assets/video/tower_dawn_to_eclipse_gate.ogv", "res://assets/video/tower_eclipse_to_ascend_gate.ogv"][bosses.find(boss)]
        verify(Cinematics.transition_for(second) == expected_transition, "correct stage transition")
        var wallet: int = int(data.economy.leaves)
        verify(Tower.settle(data).is_empty() and int(data.economy.leaves) == wallet, "settlement cannot pay twice")
    var deciding: Dictionary = fresh(100)
    finish_round(deciding, 1)
    Tower.begin_floor(deciding)
    finish_round(deciding, 2)
    Tower.begin_floor(deciding)
    var tied: Dictionary = finish_round(deciding, 3)
    verify(int(tied.player_wins) == 1 and int(tied.guardian_wins) == 1, "draw keeps one-all score")
    verify(not bool(tied.series_complete) and int(deciding.tower.lives) == 5, "draw costs no life")
    Tower.begin_floor(deciding)
    var final: Dictionary = finish_round(deciding, 1)
    verify(bool(final.floor_complete) and int(final.player_wins) == 2, "third decisive round wins 2 to 1")
    verify(str(final.unlocked_card) == "zen_tower_007_eclipse_sovereign", "correct milestone card")
    Tower.begin_floor(deciding)
    verify(deciding.tower.game.cells.size() == 96, "floor 101 begins with 96 cells")
    var loser: Dictionary = fresh(75, 2)
    finish_round(loser, 2)
    verify(int(loser.tower.lives) == 2, "round loss has no series life penalty")
    Tower.begin_floor(loser)
    var lost: Dictionary = finish_round(loser, 2)
    verify(int(loser.tower.lives) == 1 and not bool(lost.game_over), "lost series costs one life")
    verify(Cinematics.defeat_for(lost).is_empty() and Cinematics.transition_for(lost).is_empty(), "loss never opens gate")
    Tower.begin_floor(loser)
    verify(int(loser.tower.series.player) == 0 and int(loser.tower.series.guardian) == 0, "retry starts new series")
    var last_life: Dictionary = fresh(30, 1)
    finish_round(last_life, 2)
    Tower.begin_floor(last_life)
    verify(bool(finish_round(last_life, 2).game_over), "lost series on last life ends run")
    var resume: Dictionary = fresh(100)
    var archived_board: Dictionary = resume.tower.game.duplicate(true)
    var partial: Dictionary = finish_round(resume, 1)
    resume.tower.finished = {"board": archived_board, "result": partial}
    var restored: Dictionary = JSON.parse_string(JSON.stringify(resume))
    verify(not Tower.begin_floor(restored), "pending result survives resume")
    verify(int(restored.tower.series.player) == 1, "series score survives resume")
    restored.tower.finished = {}
    Tower.begin_floor(restored)
    verify(int(restored.tower.series.player) == 1, "next round retains series score")
    var old: Dictionary = fresh(101, 6)
    old.tower.game = BoardModel.new().snapshot()
    Tower.begin_floor(old)
    verify(old.tower.game.cells.size() == 96 and int(old.tower.lives) == 6, "legacy board migration retains lives")
    var checkpoint_data: Dictionary = fresh(49, 2)
    checkpoint_data.tower.record = 49
    verify(Tower.checkpoint_floor(checkpoint_data) == 1, "no early checkpoint")
    verify(not Tower.restart_run(checkpoint_data, 51), "locked checkpoint rejected")
    checkpoint_data.tower.record = 50
    checkpoint_data.tower.cards = ["test_card"]
    var checkpoint_wallet: int = int(checkpoint_data.economy.leaves)
    verify(Tower.checkpoint_floor(checkpoint_data) == 51, "floor 50 unlocks 51")
    verify(Tower.restart_run(checkpoint_data, 51), "restart checkpoint")
    verify(int(checkpoint_data.tower.floor) == 51 and int(checkpoint_data.tower.lives) == 5, "checkpoint starts with five lives")
    verify(checkpoint_data.tower.cards.has("test_card") and int(checkpoint_data.economy.leaves) == checkpoint_wallet, "permanent rewards preserved")
    checkpoint_data.tower.record = 100
    verify(Tower.restart_run(checkpoint_data, 101), "restart 4x4 checkpoint")
    verify(checkpoint_data.tower.game.cells.size() == 96, "checkpoint 101 board size")
    verify(Tower.restart_run(checkpoint_data, 1), "reset to beginning")
    verify(int(checkpoint_data.tower.floor) == 1 and Tower.checkpoint_floor(checkpoint_data) == 101, "reset retains unlocked checkpoints")
    var normal: Dictionary = fresh(99)
    verify(bool(finish_round(normal, 1).floor_complete) and int(normal.tower.floor) == 100, "normal floor still one match")
    var tactical: Array = Tower.new_board(4).cells
    tactical[0] = 2
    tactical[1] = 2
    tactical[2] = 2
    verify(Tower.choose_move(tactical, 4, 250, 3) == 3, "4x4 bot takes winning move")
    tactical[0] = 1
    tactical[1] = 1
    tactical[2] = 1
    verify(Tower.choose_move(tactical, 4, 250, 3) == 3, "4x4 bot blocks immediate loss")
    print("PASS" if not failed else "FAIL", ": ", checks, " Tower component checks")
    quit(1 if failed else 0)
