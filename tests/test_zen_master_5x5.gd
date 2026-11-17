extends SceneTree
# Invoke: godot --headless --path . --script tests/test_zen_master_5x5.gd
const Mode = preload("res://core/ZenMaster.gd")
var failures: int = 0

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        printerr("ZEN MASTER 5X5 FAIL: " + message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var lines: Array = Mode.generate_lines()
    check(lines.size() == 312, "312 total lines")
    var seen: Dictionary = {}
    var face_count: int = 0
    var edge_count: int = 0
    var split_counts: Dictionary = {1:0, 2:0, 3:0, 4:0}
    for line in lines:
        check(line.size() == 5, "every winning line contains exactly five cells")
        var faces: Dictionary = {}
        var copy: Array = line.duplicate()
        copy.sort()
        var key: String = str(copy)
        check(not seen.has(key), "no duplicate line")
        seen[key] = true
        for c in line:
            check(int(c) >= 0 and int(c) < Mode.CELLS, "all indexes in bounds")
            faces[Mode.face(int(c))] = true
        check(faces.size() >= 1 and faces.size() <= 2, "no corner- or third-face lines")
        if faces.size() == 1:
            face_count += 1
        else:
            edge_count += 1
            var first_face: int = Mode.face(int(line[0]))
            var prefix: int = 0
            for c in line:
                if Mode.face(int(c)) == first_face:
                    prefix += 1
                else:
                    break
            check(prefix >= 1 and prefix <= 4, "valid crossing split")
            split_counts[prefix] += 1
    check(face_count == 72, "72 face lines")
    check(edge_count == 240, "240 edge lines")
    for split in range(1, 5):
        check(int(split_counts[split]) == 60, "60 lines with split " + str(split))
    var cells: Array = []
    cells.resize(Mode.CELLS)
    cells.fill(0)
    for c in lines[0]:
        cells[int(c)] = 1
    check(Mode.winning_lines(cells, lines, 1).size() > 0, "five on one face wins")
    cells.fill(0)
    for c in lines[72]:
        cells[int(c)] = 2
    check(Mode.winning_lines(cells, lines, 2).size() > 0, "five across an edge wins")
    cells.fill(0)
    for i in range(4):
        cells[int(lines[0][i])] = 1
    check(Mode.immediate_move(cells, lines, 1) == int(lines[0][4]), "immediate fifth mark detected")
    check(Mode.next_move(cells, lines, 1) == int(lines[0][4]), "bot wins immediately")
    check(Mode.next_move(cells, lines, 2) == int(lines[0][4]), "bot blocks immediate threat")
    check(cells.count(0) == 146, "bot does not mutate board")
    check(BoardModel.new().cells.size() == 54, "Classic remains 54 cells")
    check(ZenAscend.generate_lines().size() == 204, "Zen Ascend remains 204 lines")
    var packed: PackedScene = load("res://ZenMasterPrototype.tscn") as PackedScene
    check(packed != null, "independent prototype scene loads")
    if packed != null:
        var game: Node = packed.instantiate()
        root.add_child(game)
        await process_frame
        check(game.cells.size() == 150, "scene initializes 150 cells")
        check(game.tiles.size() == 150, "scene has 150 3D tiles")
        check(game.marks.size() == 150, "scene has 150 symbol holders")
        game._restart(false)
        game._on_tap(Mode.id(0, 0, 0))
        check(int(game.cells[Mode.id(0, 0, 0)]) == 1, "scene accepts legal player move")
        game._on_tap(Mode.id(0, 0, 0))
        check(game.cells.count(0) == 149, "occupied cell cannot be played twice")
        game.queue_free()
        await process_frame
    print("ZEN MASTER 5X5 FAILURES=", failures)
    quit(0 if failures == 0 else 1)
