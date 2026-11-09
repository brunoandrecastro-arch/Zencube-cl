class_name ZenChallenges
extends RefCounted
# Offline tactical puzzles for ZenCube 3D. All lines must match RulesEngine.
const PUZZLES_PATH = "res://challenges/challenges.json"
const PROGRESS_PATH = "user://zen_challenges_progress.json"
var puzzles: Array = []
var solved: Dictionary = {}
var valid: bool = false

func _init(reference_lines: Array) -> void:
    if not FileAccess.file_exists(PUZZLES_PATH):
        push_error("Zen Challenges: puzzles are missing")
        return
    var contents = JSON.parse_string(FileAccess.get_file_as_string(PUZZLES_PATH))
    if not contents is Dictionary or contents.get("format", "") != "zencube-challenges-v2":
        push_error("Zen Challenges: invalid data format")
        return
    var stored_lines = contents.get("lines", [])
    var stored_puzzles = contents.get("challenges", [])
    if not stored_lines is Array or not stored_puzzles is Array:
        return
    if stored_lines.size() != reference_lines.size() or stored_lines.size() != 108 or stored_puzzles.size() != 100:
        push_error("Zen Challenges: wrong number of lines or puzzles")
        return
    var real_keys: Dictionary = {}
    for line in reference_lines:
        real_keys[_line_key(line)] = true
    for line in stored_lines:
        if not line is Array or not real_keys.has(_line_key(line)):
            push_error("Zen Challenges: rules do not match the game")
            return
    for p in stored_puzzles:
        if not p is Dictionary or not p.get("x") is Array or not p.get("o") is Array or not p.get("solutions") is Array:
            return
        if not str(p.get("kind", "")) in ["win", "block", "fork", "sequence", "defense"] or p.solutions.is_empty():
            return
    # Godot JSON parser returns numeric values as floats; normalize cell IDs.
    for p in stored_puzzles:
        for field in ["x", "o", "solutions"]:
            p[field] = p[field].map(func(value): return int(value))
        p["id"] = int(p["id"])
        p["level"] = int(p["level"])
    puzzles = stored_puzzles
    valid = true
    load_progress()

static func _line_key(line: Array) -> String:
    var sorted_line: Array = line.duplicate()
    sorted_line.sort()
    return "%02d:%02d:%02d:%02d" % [int(sorted_line[0]), int(sorted_line[1]), int(sorted_line[2]), int(sorted_line[3])]

func load_progress() -> void:
    if not FileAccess.file_exists(PROGRESS_PATH): return
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(PROGRESS_PATH))
    if not parsed is Dictionary: return
    for i in range(1, 101):
        if parsed.get(str(i), false): solved[str(i)] = true

func record_solved(index: int) -> void:
    var key = str(index + 1)
    if solved.has(key): return
    solved[key] = true
    var f = FileAccess.open(PROGRESS_PATH + ".tmp", FileAccess.WRITE)
    if f == null:
        push_warning("Zen Challenges: progress could not be saved")
        return
    f.store_string(JSON.stringify(solved))
    f.close()
    if DirAccess.rename_absolute(ProjectSettings.globalize_path(PROGRESS_PATH + ".tmp"), ProjectSettings.globalize_path(PROGRESS_PATH)) != OK:
        push_warning("Zen Challenges: progress rename failed")

func puzzle(index: int) -> Dictionary:
    return puzzles[clampi(index, 0, puzzles.size() - 1)]

func setup(board: BoardModel, index: int) -> void:
    var p = puzzle(index)
    board.cells.fill(0)
    for cell in p.x: board.cells[int(cell)] = 1
    for cell in p.o: board.cells[int(cell)] = 2
    board.last_cell = -1
    board.turn = 1
    board.winner = 0
    board.win_lines = []
    board.history = []
    board.swap_enabled = false
    board.swap_pending = false
    board.result_recorded = false

func solutions(index: int) -> Array:
    return puzzle(index).solutions
