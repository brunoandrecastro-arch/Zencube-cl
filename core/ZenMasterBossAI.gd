class_name ZenMasterBossAI
extends RefCounted
# Sixteen stage-specific test opponents; FOUR-in-a-row only.
const Mode = preload("res://core/ZenMaster.gd")

static func choose(cells: Array, lines: Array, stage_index: int) -> int:
    if cells.size() != Mode.CELLS or lines.size() != Mode.EXPECTED_LINES:
        return -1
    if not Mode.winning_lines(cells, lines, 1).is_empty() or not Mode.winning_lines(cells, lines, 2).is_empty():
        return -1
    var level: int = mini(5, 1 + int(stage_index / 3))
    var win: int = Mode.immediate_move(cells, lines, 2)
    if win >= 0:
        return win
    var block: int = Mode.immediate_move(cells, lines, 1)
    # The lowest tier deliberately has a small imperfection; later bosses defend properly.
    if block >= 0 and (level > 1 or randf() > 0.26):
        return block

    var weights: Array[float] = []
    weights.resize(Mode.CELLS)
    weights.fill(0.0)
    var options: Array[int] = []
    for c in range(Mode.CELLS):
        if int(cells[c]) == 0:
            options.append(c)
    if options.is_empty():
        return -1
    for line in lines:
        var own: int = 0
        var opposing: int = 0
        for v in line:
            if int(cells[int(v)]) == 2:
                own += 1
            elif int(cells[int(v)]) == 1:
                opposing += 1
        if own > 0 and opposing > 0:
            continue
        var score: float = 0.9
        if own > 0:
            score += float([0, 4, 23, 180][mini(3,own)])
        if opposing > 0:
            score += float([0, 2, 17, 140][mini(3,opposing)])
        for v in line:
            if int(cells[int(v)]) == 0:
                weights[int(v)] += score
    # Personalities: duelist/prophet/executioner/guardian each prefer different geometry.
    var temperament: int = stage_index % 4
    for c in options:
        var local: int = c % 25
        var row: int = int(local/5)
        var col: int = local % 5
        if temperament == 0:
            weights[c] += float(4 - absi(row-col)) * 1.3
        elif temperament == 1:
            weights[c] += float(4 - absi(row-2)-absi(col-2)) * 2.0
        elif temperament == 2:
            weights[c] += float(absi(row-2)+absi(col-2)) * 1.8
        else:
            weights[c] += float(4 - absi(row-2)-absi(col-2)) * 1.7

    options.sort_custom(func(a: int,b: int) -> bool: return weights[a] > weights[b])
    if level >= 4:
        # Look ahead at the strongest few placements; don't attempt exponential search.
        var count: int = mini(10,options.size())
        for i in range(count):
            var c: int = options[i]
            cells[c] = 2
            var forks: int = _count_immediate_wins(cells, lines, 2, 3)
            cells[c] = 0
            weights[c] += float(forks)*70.0
        options.sort_custom(func(a: int,b: int) -> bool: return weights[a] > weights[b])
    var window: int = [0, 18, 10, 5, 3, 2][level]
    var upper: int = mini(window,options.size())
    return options[randi_range(0,upper-1)]

static func _count_immediate_wins(cells: Array, lines: Array, player: int, cap: int) -> int:
    var count: int = 0
    var unique: Dictionary = {}
    for line in lines:
        var own: int = 0
        var free: int = -1
        var invalid: bool = false
        for v in line:
            var c: int = int(v)
            if int(cells[c]) == player:
                own += 1
            elif int(cells[c]) == 0:
                if free != -1:
                    invalid = true
                    break
                free = c
            else:
                invalid = true
                break
        if not invalid and own == Mode.CONNECT - 1 and free >= 0 and not unique.has(free):
            unique[free] = true
            count += 1
            if count >= cap:
                break
    return count
