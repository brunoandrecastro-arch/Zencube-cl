extends SceneTree
var checks: int = 0
var failures: int = 0
var rules = RulesEngine.new()
func check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        printerr("FAIL: " + message)
func _initialize() -> void:
    check(CubeGeometry.N.size() == 6,"six cube faces")
    check(CubeGeometry.edges().size() == 12,"12 cube edges")
    var centers: Dictionary = {}
    for c in range(54): centers[CubeGeometry.center(c)] = c
    check(centers.size() == 54,"54 distinct face-cell centers")
    var seen: Dictionary = {}
    var by_distribution := {"3+1":0,"2+2":0,"1+3":0}
    for line in rules.lines:
        check(line.size() == 4,"each line has exactly 4 cells")
        var sorted = line.duplicate()
        sorted.sort()
        seen[str(sorted)] = true
        var faces: Dictionary = {}
        for c in line:
            check(c >= 0 and c < 54,"line cell in range")
            faces[CubeGeometry.face(c)] = true
        check(faces.size() == 2,"each line has exactly two faces")
        var f1: int = CubeGeometry.face(int(line[0]))
        var f2: int = CubeGeometry.face(int(line[3]))
        check(CubeGeometry.N[f1].dot(CubeGeometry.N[f2]) == 0,"faces physically adjacent")
        var tangent: Vector3 = CubeGeometry.N[f1].cross(CubeGeometry.N[f2])
        var lane: float = CubeGeometry.center(int(line[0])).dot(tangent)
        for c in line:
            check(is_equal_approx(CubeGeometry.center(c).dot(tangent),lane),"straight across the edge, no diagonals")
        for k in range(3):
            var gap: float = CubeGeometry.center(int(line[k])).distance_to(CubeGeometry.center(int(line[k+1])))
            check(is_equal_approx(gap,1.0) or is_equal_approx(gap,sqrt(0.5)),"no gap between neighboring cells")
        var first_count: int = 0
        for c in line:
            if CubeGeometry.face(c) == f1: first_count += 1
        by_distribution[str(first_count)+"+"+str(4-first_count)] += 1
        for player in [1,2]:
            var board = BoardModel.new()
            board.swap_enabled = false
            for idx in range(3): board.cells[line[idx]] = player
            board.turn = player
            check(rules.threats(board.cells,player).has(line[3]),"three marks make a real fourth-cell threat")
            check(rules.play(board,line[3]) and board.winner == player,"every four-cell line wins for both players")
            check(not rules.play(board,board.cells.find(0)),"no extra moves after victory")
    check(rules.lines.size() == 108 and seen.size() == 108,"108 unique four-cell lines")
    check(by_distribution == {"3+1":36,"2+2":36,"1+3":36},"36 per 3+1/2+2/1+3 distribution")

    # Rotations of physical cube cannot alter winning combinations.
    var rotations := 0
    for x in CubeGeometry.N:
        for y in CubeGeometry.N:
            if x.dot(y) != 0: continue
            var rot = Basis(x,y,x.cross(y))
            rotations += 1
            for line in rules.lines:
                var mapped: Array = []
                for c in line: mapped.append(centers[rot*CubeGeometry.center(c)])
                mapped.sort()
                check(seen.has(str(mapped)),"proper rotation preserves winline")
    check(rotations == 24,"24 cube rotations")

    var b = BoardModel.new()
    check(not rules.play(b,-1) and not rules.play(b,54),"bounds validated")
    check(rules.play(b,4) and b.swap_pending,"swap opportunity after first mark")
    check(not rules.play(b,5),"must resolve swap before next mark")
    check(rules.swap(b,true) and b.owners == [1,0],"swap transfers player identity")
    check(not rules.swap(b,true),"swap cannot repeat")
    check(not rules.play(b,4),"occupied cell not playable")
    check(rules.undo(b) and b.swap_pending,"undo restores swap state")
    check(rules.swap(b,false) and b.current_owner() == 1,"declining swap retains turn")
    check(rules.play(b,5),"second player legal after decline")
    check(rules.undo(b) and b.cells[5] == 0,"undo second move")
    var clone = BoardModel.new()
    clone.restore(JSON.parse_string(JSON.stringify(b.snapshot())))
    check(clone.cells == b.cells,"JSON save/restore is lossless")
    check(SaveManager.valid_game(clone.snapshot()),"save validator accepts valid board")
    check(not SaveManager.valid_game({"cells":[]}),"save validator rejects invalid board")
    for case in [[0,1,2], [0,1,3,4], [0,1,2,4], [0,9,18,36]]:
        var bad_cells = BoardModel.new().cells
        for c in case: bad_cells[c] = 1
        check(rules.victories(bad_cells,1).is_empty(),"same-face/incoherent combination does not win")

    # Existing full-board draw fixture (no old three-in-a-row win) remains a valid
    # four-in-a-row draw since every four-cell window contains an old three-cell window.
    var fixture = JSON.parse_string(FileAccess.get_file_as_string("res://reports/draw_fixture.json"))
    check(fixture is Array and fixture.size() == 54,"legacy draw fixture available")
    b = BoardModel.new()
    b.swap_enabled = false
    for ply in range(54):
        var chosen = -1
        for c in range(54):
            if b.cells[c] == 0 and int(fixture[c]) == b.turn:
                chosen = c
                break
        check(chosen >= 0 and rules.play(b,chosen),"full-board draw fixture playable")
        check(b.winner == (3 if ply == 53 else 0),"fixture draw appears only after 54 marks")
    var ai = AIEngine.new(1729)
    var max_ms := 0
    for line in rules.lines:
        for level in [1,2]:
            var cells = BoardModel.new().cells
            for i in range(3): cells[line[i]] = 1
            check(rules.threats(cells,1).has(ai.choose(cells,1,level)),"AI completes immediate fourth mark")
            check(rules.threats(cells,1).has(ai.choose(cells,2,level)),"AI blocks immediate four-in-a-row threat")
    for level in range(3):
        b = BoardModel.new()
        b.swap_enabled = false
        while b.winner == 0:
            var t = Time.get_ticks_msec()
            var move = ai.choose(b.cells,b.turn,level,80)
            max_ms = maxi(max_ms,Time.get_ticks_msec()-t)
            check(move >= 0 and b.cells[move] == 0,"AI selects legal move")
            rules.play(b,move)
        check(ai.choose(b.cells,b.turn,level) == -1,"AI recognizes finished game")
    check(max_ms < 400,"AI move time bounded")
    FileAccess.open("res://reports/lines.json",FileAccess.WRITE).store_string(JSON.stringify(rules.lines))
    var report = {"checks":checks,"failures":failures,"lines":rules.lines.size(),"rotations":rotations,"max_ai_ms":max_ms}
    FileAccess.open("res://reports/tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print(JSON.stringify(report))
    quit(0 if failures == 0 else 1)
