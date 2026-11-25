extends RulesEngine

const Grid = preload("res://core/ZenTowerGrid.gd")

func _init(side: int = 3) -> void:
    lines = Grid.generate_lines() if side == 4 else WinLineGenerator.generate()

func play(board: BoardModel, cell: int) -> bool:
    if cell < 0 or cell >= board.cells.size() or board.winner != 0 or board.swap_pending or int(board.cells[cell]) != 0:
        return false
    board.history.append(board.snapshot())
    board.cells[cell] = board.turn
    board.last_cell = cell
    board.win_lines = victories(board.cells, board.turn)
    if not board.win_lines.is_empty():
        board.winner = board.turn
    elif not board.cells.has(0):
        board.winner = 3
    board.turn = 3 - board.turn
    board.swap_pending = false
    return true
