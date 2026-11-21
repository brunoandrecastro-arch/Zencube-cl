extends RefCounted
## Act III independent progress. Classic and previous acts remain untouched.
const SAVE_FILE := "user://zen_chronicles_act03_aiko_trial_v1.json"
const ROOT := "res://story/act03/"
const CONFIG := ROOT + "aiko_trial.json"
const REFERENCE := ROOT + "references/aiko_portrait.png"
const PORTRAIT := ROOT + "references/aiko_portrait.png"

const ActTwo = preload("res://story/ZenActTwo.gd")

static func portrait_path() -> String:
    return PORTRAIT

static func medium_wins(data: Dictionary) -> int:
    var wins: Array = data.get("stats",{}).get("ai_wins",[])
    return clampi(int(wins[1]) if wins.size()>1 else 0,0,5)

static func unlocked(data: Dictionary) -> bool:
    return bool(ActTwo.load_progress().complete) and medium_wins(data)>=5 and ZenAscension.world_unlocked(data,2)

static func media_ready() -> bool:
    if not ResourceLoader.exists(PORTRAIT): return false
    for page in range(1,13):
        if not ResourceLoader.exists(page_path(page)): return false
    return true

static func page_path(page: int) -> String:
    return ROOT + "pages/zen_chronicles_ch01_act03_%02d.png" % page

static func config() -> Dictionary:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
    return parsed if parsed is Dictionary else {}

static func fresh() -> Dictionary:
    return {"version": 1, "page": 1, "reached": false, "game": {}, "won": false, "acknowledged": false, "complete": false}

static func new_board() -> BoardModel:
    var board := BoardModel.new()
    board.swap_enabled = false
    return board

static func restore_board(snapshot: Dictionary) -> BoardModel:
    var board := new_board()
    if not SaveManager.valid_game(snapshot):
        return board
    board.restore(snapshot)
    if board.owners != [0, 1] or board.swap_enabled or board.swap_pending:
        return new_board()
    var rules := RulesEngine.new()
    var x_lines := rules.victories(board.cells, 1)
    var o_lines := rules.victories(board.cells, 2)
    if not x_lines.is_empty() and not o_lines.is_empty():
        return new_board()
    board.win_lines = x_lines + o_lines
    board.winner = 1 if not x_lines.is_empty() else (2 if not o_lines.is_empty() else (3 if not board.cells.has(0) else 0))
    return board

static func load_progress() -> Dictionary:
    var progress := fresh()
    if not FileAccess.file_exists(SAVE_FILE):
        return progress
    var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_FILE))
    if not raw is Dictionary or int(raw.get("version", 0)) != 1:
        return progress
    progress.reached = bool(raw.get("reached", false))
    var game: Variant = raw.get("game", {})
    if progress.reached and game is Dictionary and not game.is_empty():
        var board := restore_board(game)
        progress.game = board.snapshot()
        progress.won = bool(raw.get("won", false)) and board.winner == 1
    progress.acknowledged = progress.won and bool(raw.get("acknowledged", false))
    progress.complete = progress.acknowledged and bool(raw.get("complete", false))
    progress.page = clampi(int(raw.get("page", 1)), 1, max_page(progress))
    return progress

static func max_page(progress: Dictionary) -> int:
    return 12 if bool(progress.get("won", false)) and bool(progress.get("acknowledged", false)) else 11

static func capture(progress: Dictionary, board: BoardModel) -> void:
    progress.reached = true
    progress.game = board.snapshot()
    # Only the real rules-engine result for the dedicated X/O board can win.
    if board.winner == 1 and board.owners == [0, 1] and not RulesEngine.new().victories(board.cells, 1).is_empty():
        progress.won = true

static func save_progress(progress: Dictionary) -> bool:
    var temp := SAVE_FILE + ".tmp"
    var file := FileAccess.open(temp, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(progress))
    file.flush()
    var error := file.get_error()
    file.close()
    if error != OK:
        return false
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), ProjectSettings.globalize_path(SAVE_FILE)) == OK
