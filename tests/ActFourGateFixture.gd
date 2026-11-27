extends RefCounted
## Temporary real Act IV victory used only in isolated regression tests.
const Series509 = preload("res://story/ZenActBossSeries.gd")
const Act = preload("res://story/ZenActFour.gd")
var existed: bool = false
var original: PackedByteArray = PackedByteArray()
var active: bool = false

func grant() -> bool:
    if active: return false
    existed = FileAccess.file_exists(Act.SAVE_FILE)
    original = FileAccess.get_file_as_bytes(Act.SAVE_FILE) if existed else PackedByteArray()
    active = true
    var rules: RulesEngine = RulesEngine.new()
    var board: BoardModel = Act.new_board()
    var line: Array = rules.lines[0]
    if line.size() != 4: return false
    for index in range(4):
        if not rules.play(board,int(line[index])): return false
        if index == 3: break
        var placed: bool = false
        for cell in range(54):
            if line.has(cell) or board.cells[cell] != 0: continue
            var simulated: Array = board.cells.duplicate()
            simulated[cell] = 2
            if not rules.victories(simulated,2).is_empty(): continue
            if rules.play(board,cell):
                placed = true
                break
        if not placed: return false
    if board.winner != 1 or board.owners != [0,1]: return false
    var p: Dictionary = Act.fresh()
    Act.capture(p,board)
    if bool(p.won): return false
    var second: BoardModel = Act.new_board()
    if not Series509.next_round(p, board, second): return false
    # Play a second genuine win, now with O starting.
    while second.winner == 0:
        if second.turn == 1:
            var move_index: int = second.cells.count(1)
            if move_index >= line.size() or not rules.play(second, int(line[move_index])): return false
        else:
            var placed_second: bool = false
            for cell in range(54):
                if line.has(cell) or second.cells[cell] != 0: continue
                var candidate: Array = second.cells.duplicate()
                candidate[cell] = 2
                if not rules.victories(candidate, 2).is_empty(): continue
                if rules.play(second, cell):
                    placed_second = true
                    break
            if not placed_second: return false
    if second.winner != 1: return false
    Act.capture(p,second)
    if not bool(p.won): return false
    p.acknowledged = true
    p.complete = true
    p.page = 12
    return Act.save_progress(p) and bool(Act.load_progress().complete)

func restore() -> void:
    if not active: return
    if existed:
        var file: FileAccess = FileAccess.open(Act.SAVE_FILE,FileAccess.WRITE)
        if file != null:
            file.store_buffer(original)
            file.close()
    elif FileAccess.file_exists(Act.SAVE_FILE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(Act.SAVE_FILE))
    active = false
