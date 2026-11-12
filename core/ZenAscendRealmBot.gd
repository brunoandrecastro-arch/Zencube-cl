class_name ZenAscendRealmBot
extends RefCounted
# Five distinct strategic strengths for the standalone 4x4 bot. Classic AI remains unchanged.
# Tactical scans capped at 96 cells x 204 lines; no recursive search on Android.
const WIN_CHANCE: Array[float] = [0.78, 0.94, 1.0, 1.0, 1.0]
const BLOCK_CHANCE: Array[float] = [0.57, 0.78, 0.92, 0.98, 1.0]
const NOISE_CHANCE: Array[float] = [0.30, 0.12, 0.03, 0.0, 0.0]

static func _immediate_moves(cells: Array, lines: Array, player: int) -> Array:
    var cells_found: Array = []
    for line in lines:
        var marks: int = 0
        var free: int = -1
        var free_count: int = 0
        var blocked: bool = false
        for p in line:
            var c: int = int(p)
            if int(cells[c]) == player: marks += 1
            elif int(cells[c]) == 0:
                free_count += 1
                free = c
            else:
                blocked = true
                break
        if not blocked and marks == 3 and free_count == 1 and not cells_found.has(free):
            cells_found.append(free)
    return cells_found

static func _random_empty(cells: Array, avoid: Array = []) -> int:
    var empty: Array[int] = []
    for c in range(cells.size()):
        if int(cells[c]) == 0 and not avoid.has(c): empty.append(c)
    if empty.is_empty():
        for c in range(cells.size()):
            if int(cells[c]) == 0: empty.append(c)
    return -1 if empty.is_empty() else int(empty[randi_range(0,empty.size()-1)])

static func _score(cells: Array, lines: Array, player: int, candidate: int) -> float:
    var enemy: int = 3-player
    var score: float = 0.0
    for line in lines:
        if not line.has(candidate): continue
        var ours: int = 0
        var theirs: int = 0
        for index in line:
            var c: int = int(index)
            if c == candidate: continue
            if int(cells[c]) == player: ours += 1
            elif int(cells[c]) == enemy: theirs += 1
        if ours > 0 and theirs > 0: continue
        if ours > 0: score += float([0, 5, 18, 800][ours])
        elif theirs > 0: score += float([0, 5, 25, 600][theirs])
        else: score += 1.0
    return score

static func _fork_score(cells: Array, lines: Array, player: int, candidate: int) -> float:
    cells[candidate] = player
    var threats: int = _immediate_moves(cells,lines,player).size()
    cells[candidate] = 0
    if threats >= 2: return 250.0 + float(threats)*30.0
    if threats == 1: return 25.0
    return 0.0

static func next_move(cells: Array, lines: Array, player: int, difficulty: int) -> int:
    if player not in [1,2]: return -1
    var level: int = clampi(difficulty,0,4)
    var wins: Array = _immediate_moves(cells,lines,player)
    if not wins.is_empty():
        if randf() <= WIN_CHANCE[level]: return int(wins[0])
        # For Easy / Medium a genuine missed win should not be recovered by the heuristic.
        if level <= 1: return _random_empty(cells,wins)
    var blocks: Array = _immediate_moves(cells,lines,3-player)
    if not blocks.is_empty():
        if randf() <= BLOCK_CHANCE[level]: return int(blocks[0])
        if level <= 1: return _random_empty(cells,blocks)
    if randf() < NOISE_CHANCE[level]: return _random_empty(cells)
    var best: float = -1e20
    var options: Array[int] = []
    var grand_defense: Array = []
    if level == 4:
        # Only Grandmaster proactively prevents an enemy two-threat fork.
        for c in range(cells.size()):
            if int(cells[c]) != 0: continue
            var enemy_fork: float = _fork_score(cells,lines,3-player,c)
            if enemy_fork >= 250.0: grand_defense.append(c)
    for c in range(cells.size()):
        if int(cells[c]) != 0: continue
        var value: float = _score(cells,lines,player,c)
        if level >= 3: value += _fork_score(cells,lines,player,c)
        if level == 4 and grand_defense.has(c): value += 300.0
        if level == 0: value += randf_range(-35.0,35.0)
        elif level == 1: value += randf_range(-12.0,12.0)
        elif level == 2: value += randf_range(-3.0,3.0)
        if value > best + 0.0001:
            best = value
            options = [c]
        elif absf(value-best) < 0.0001:
            options.append(c)
    return -1 if options.is_empty() else int(options[randi_range(0,options.size()-1)])
