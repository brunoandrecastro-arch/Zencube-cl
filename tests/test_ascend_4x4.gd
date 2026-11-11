extends SceneTree
# Standalone 4x4 rule, unlock and save regression, run headlessly.
var failures: int = 0
func check(value: bool, details: String) -> void:
    if not value:
        failures += 1
        printerr("ASCEND 4X4 FAIL: " + details)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var lines: Array = ZenAscend.generate_lines()
    check(lines.size() == 204, "204 lines = 60 face lines + 144 edge lines")
    var seen: Dictionary = {}
    var face_lines: int = 0
    var edge_lines: int = 0
    for line in lines:
        check(line.size() == 4, "four cells per winning line")
        var faces: Dictionary = {}
        var copy: Array = line.duplicate()
        copy.sort()
        var key: String = str(copy)
        check(not seen.has(key), "no duplicate winning line")
        seen[key] = true
        for cell in line:
            check(int(cell) >= 0 and int(cell) < 96, "valid 4x4 cell")
            faces[int(int(cell)/16)] = true
        check(faces.size() >= 1 and faces.size() <= 2, "one or two faces per line")
        if faces.size() == 1: face_lines += 1
        elif faces.size() == 2: edge_lines += 1
    check(face_lines == 60 and edge_lines == 144, "60 face + 144 edge")
    var cells: Array = []
    cells.resize(96)
    cells.fill(0)
    for c in lines[0]: cells[int(c)] = 1
    check(not ZenAscend.winning_lines(cells,lines,1).is_empty(), "on-face win")
    cells.fill(0)
    for c in lines[60]: cells[int(c)] = 2
    check(not ZenAscend.winning_lines(cells,lines,2).is_empty(), "across-edge win")
    cells.fill(0)
    for i in range(3): cells[int(lines[0][i])] = 1
    check(ZenAscend.next_move(cells,lines,1) == int(lines[0][3]), "bot takes immediate win")
    check(ZenAscend.next_move(cells,lines,2) == int(lines[0][3]), "bot blocks immediate loss")
    var data: Dictionary = SaveManager.defaults()
    ZenAscend.ensure(data)
    # The debug APK must enforce precisely the same gate as the Play AAB.
    check(not ZenAscend.TEST_UNLOCKED, "free debug access disabled")
    check(not ZenAscend.test_access_enabled(), "test override never active")
    check(not ZenAscend.unlocked(data), "new player locked")
    check(not ZenAscend.unlocked_for_release(data), "production beginner locked")
    data.ascension.rank = 2
    check(not ZenAscend.unlocked(data), "rank 2 still locked")
    check(not ZenAscend.unlocked_for_release(data), "production rank 2 still locked")
    data.ascension.rank = 3
    check(ZenAscend.unlocked_for_release(data), "production: Zen Master unlocks 4x4")
    check(ZenAscend.unlocked(data), "Zen Master unlocks even without test flag")
    data.economy.leaves = 800
    check(not ZenAscend.buy(data) and int(data.economy.leaves)==800, "no store charge after Zen Master")
    data.ascension.rank = 0
    data.economy.leaves = 0
    check(not ZenAscend.buy(data), "insufficient currency")
    data.economy.leaves = 800
    check(ZenAscend.buy(data), "shop buy")
    check(int(data.economy.leaves)==50 and bool(data.economy.ascend_owned),"shop deducts once")
    check(ZenAscend.unlocked_for_release(data), "purchase unlocks release")
    check(ZenAscend.unlocked(data), "purchase allows entry regardless of build variant")
    check(not ZenAscend.buy(data), "cannot buy twice")
    check(int(data.economy.leaves)==50,"no double charge")
    # 4x4 never alters Classic's 54 cells, 108 lines or the saved match.
    check(BoardModel.new().cells.size()==54,"Classic 54 cells")
    check(RulesEngine.new().lines.size()==108,"Classic 108 lines")
    check(SaveManager.valid_game(SaveManager.defaults().game)==false,"fresh Classic game stays distinct")
    var scene: PackedScene = load("res://Ascend.tscn") as PackedScene
    check(scene != null, "separate scene exists")
    print("ZEN ASCEND 4X4 CHECK FAILURES=",failures)
    quit(0 if failures==0 else 1)
