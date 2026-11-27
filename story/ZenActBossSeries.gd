extends RefCounted
## Shared, persistent first-to-two series for Acts I-IV only.
## Legacy verified victories remain cleared; a finished round is counted once.
static func restore(progress: Dictionary, raw: Dictionary, board: BoardModel) -> void:
    var winner: int = board.winner if board != null else 0
    var counted: bool = bool(raw.get("round_counted", false)) and winner in [1, 2, 3]
    var player: int = clampi(int(raw.get("series_player", 0)), 0, 2)
    var boss: int = clampi(int(raw.get("series_boss", 0)), 0, 2)
    if not raw.has("series_player"):
        # A verified single-round victory from a previous release stays valid.
        player = 2 if winner == 1 and bool(raw.get("won", false)) else 0
        boss = 0
        counted = player == 2
    if player == 2 and (winner != 1 or not counted): player = 1
    if boss == 2 and (winner != 2 or not counted): boss = 1
    if player == 2 and boss == 2: boss = 1
    progress.series_player = player
    progress.series_boss = boss
    progress.round_counted = counted
    progress.won = player == 2 and winner == 1 and counted

static func capture(progress: Dictionary, board: BoardModel) -> void:
    progress.reached = true
    progress.game = board.snapshot()
    if bool(progress.get("round_counted", false)): return
    if board.owners != [0, 1] or board.swap_enabled or board.swap_pending: return
    var rules := RulesEngine.new()
    var x: Array = rules.victories(board.cells, 1)
    var o: Array = rules.victories(board.cells, 2)
    if board.winner == 1 and not x.is_empty() and o.is_empty():
        progress.series_player = mini(2, int(progress.get("series_player", 0)) + 1)
    elif board.winner == 2 and not o.is_empty() and x.is_empty():
        progress.series_boss = mini(2, int(progress.get("series_boss", 0)) + 1)
    elif not (board.winner == 3 and not board.cells.has(0) and x.is_empty() and o.is_empty()):
        return
    progress.round_counted = true
    progress.won = int(progress.get("series_player", 0)) == 2

static func next_round(progress: Dictionary, previous: BoardModel, next: BoardModel) -> bool:
    if previous.winner == 0 or not bool(progress.get("round_counted", false)) or bool(progress.get("won", false)):
        return false
    # A lost series restarts at 0:0. Draws do not award points.
    if int(progress.get("series_boss", 0)) >= 2:
        progress.series_player = 0
        progress.series_boss = 0
    next.starter_owner = 1 - previous.starter_owner
    next.turn = next.starter_owner + 1
    progress.round_counted = false
    progress.game = next.snapshot()
    return true
