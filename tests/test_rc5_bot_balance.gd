extends SceneTree
# Gameplay regression: early teaching examples still block correctly, but
# Medium and Master deliberately allow counterplay in later real matches.
var failures: int = 0
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        printerr("RC5 BOT FAIL: " + message)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var rules: RulesEngine = RulesEngine.new()
    var cells: Array = BoardModel.new().cells
    var threat: Array = rules.lines[0]
    for i in range(3): cells[int(threat[i])] = 1
    var urgent: int = int(threat[3])
    for level in [1, 2, 3, 4]:
        check(AIEngine.new(27).choose(cells, 2, level, 40) == urgent, "all tiers block textbook early threat")
    # Put non-contiguous opponent marks on the board without a finished line.
    # This models an actual midgame where learning bots may miss a forced block.
    for extra in [5, 16, 28, 40, 52]:
        if cells[extra] == 0: cells[extra] = 2
    check(rules.victories(cells, 1).is_empty(), "fixture: X has no completed line")
    check(rules.victories(cells, 2).is_empty(), "fixture: O has no completed line")
    check(rules.threats(cells, 2).is_empty(), "fixture: O has no faster immediate win")
    var blocked_medium: int = 0
    var blocked_hard: int = 0
    var blocked_master: int = 0
    var blocked_grandmaster: int = 0
    for seed in range(96):
        var medium_move: int = AIEngine.new(seed + 300).choose(cells, 2, 1, 55)
        var hard_move: int = AIEngine.new(seed + 300).choose(cells, 2, 2, 55)
        var master_move: int = AIEngine.new(seed + 300).choose(cells, 2, 3, 55)
        var grandmaster_move: int = AIEngine.new(seed + 300).choose(cells, 2, 4, 55)
        check(medium_move >= 0 and cells[medium_move] == 0, "medium chooses valid move")
        check(hard_move >= 0 and cells[hard_move] == 0, "hard chooses valid move")
        check(master_move >= 0 and cells[master_move] == 0, "master chooses valid move")
        check(grandmaster_move >= 0 and cells[grandmaster_move] == 0, "grandmaster chooses valid move")
        if medium_move == urgent: blocked_medium += 1
        if hard_move == urgent: blocked_hard += 1
        if master_move == urgent: blocked_master += 1
        if grandmaster_move == urgent: blocked_grandmaster += 1
    check(blocked_medium >= 20 and blocked_medium <= 90, "medium leaves human counterplay")
    check(blocked_hard >= 50 and blocked_hard < 96, "hard remains capable but allows counterplay")
    check(blocked_master >= 50 and blocked_master <= 95, "master remains harder but fallible")
    check(blocked_grandmaster == 96, "grandmaster always blocks forced win")
    print("RC5 BOT CHECK FAILURES=", failures, " medium=", blocked_medium, " master=", blocked_master, " grandmaster=", blocked_grandmaster)
    quit(0 if failures == 0 else 1)
