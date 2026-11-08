class_name RulesEngine
extends RefCounted
var lines: Array = WinLineGenerator.generate()
func victories(cells: Array, player: int) -> Array:
    var result: Array = []
    for line in lines:
        var complete := true
        for cell in line:
            if cells[cell] != player:
                complete = false
                break
        if complete: result.append(line)
    return result
func threats(cells: Array, player: int) -> Array:
    var result: Array = []
    for line in lines:
        var own := 0
        var free := -1
        var blocked := false
        for c in line:
            if cells[c] == player: own += 1
            elif cells[c] == 0:
                if free != -1: blocked = true
                free = c
            else: blocked = true
        if not blocked and own == 3 and free >= 0 and not result.has(free):
            result.append(free)
    return result
func play(board: BoardModel, cell: int) -> bool:
    if cell < 0 or cell >= 54 or board.winner != 0 or board.swap_pending or board.cells[cell] != 0: return false
    board.history.append(board.snapshot())
    board.cells[cell] = board.turn
    board.last_cell = cell
    board.win_lines = victories(board.cells,board.turn)
    if not board.win_lines.is_empty(): board.winner = board.turn
    elif not board.cells.has(0): board.winner = 3
    board.turn = 3-board.turn
    board.swap_pending = board.swap_enabled and board.move_count() == 1
    return true
func swap(board: BoardModel, accept: bool) -> bool:
    if not board.swap_pending: return false
    board.history.append(board.snapshot())
    if accept: board.owners.reverse()
    board.swap_pending = false
    return true
func undo(board: BoardModel) -> bool:
    if board.result_recorded or board.history.is_empty(): return false
    board.restore(board.history.pop_back())
    return true
