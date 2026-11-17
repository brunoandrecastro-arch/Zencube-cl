class_name ZenMaster
extends RefCounted
# Isolated 5x5 experiment. No Classic/Zen Ascend saves, menus or unlocks are touched.
const SIDE: int = 5
const CELLS: int = 150
const EXPECTED_LINES: int = 312
const SPACING: float = 0.615
const SURFACE: float = 1.62

static func id(face: int, row: int, col: int) -> int:
    return face * SIDE * SIDE + row * SIDE + col

static func face(cell: int) -> int:
    return int(cell / (SIDE * SIDE))

static func center(cell: int, height: float = SURFACE) -> Vector3:
    var f: int = face(cell)
    var n: int = cell % (SIDE * SIDE)
    var row: int = int(n / SIDE)
    var col: int = n % SIDE
    return CubeGeometry.N[f] * height + CubeGeometry.U[f] * (float(col) - 2.0) * SPACING + CubeGeometry.V[f] * (float(row) - 2.0) * SPACING

# Both faces are projected onto the *same* physical edge tangent.
# That preserves lane order when one face is mirrored relative to its neighbour.
static func boundary(f: int, neighbour: int, tangent: Vector3, lane: int, inward: int) -> int:
    var desired_near: float = float(2 - inward) * SPACING
    var desired_lane: float = float(lane - 2) * SPACING
    for c in range(f * SIDE * SIDE, (f + 1) * SIDE * SIDE):
        var p: Vector3 = center(c, 0.0)
        if absf(p.dot(CubeGeometry.N[neighbour]) - desired_near) < 0.001 and absf(p.dot(tangent) - desired_lane) < 0.001:
            return c
    return -1

static func generate_lines() -> Array:
    var lines: Array = []
    # Five rows, five columns, and the two long diagonals on every face.
    for f in range(6):
        for r in range(SIDE):
            var horizontal: Array = []
            var vertical: Array = []
            for c in range(SIDE):
                horizontal.append(id(f, r, c))
                vertical.append(id(f, c, r))
            lines.append(horizontal)
            lines.append(vertical)
        var diagonal_a: Array = []
        var diagonal_b: Array = []
        for i in range(SIDE):
            diagonal_a.append(id(f, i, i))
            diagonal_b.append(id(f, i, SIDE - 1 - i))
        lines.append(diagonal_a)
        lines.append(diagonal_b)
    # The 12 physical cube edges each have five lanes and four splits:
    # 1+4, 2+3, 3+2, 4+1. Lines do not turn around cube corners.
    for a in range(6):
        for b in range(a + 1, 6):
            if CubeGeometry.N[a].dot(CubeGeometry.N[b]) != 0.0:
                continue
            var tangent: Vector3 = CubeGeometry.N[a].cross(CubeGeometry.N[b])
            for lane in range(SIDE):
                for split in range(1, SIDE):
                    var line: Array = []
                    for inward in range(split - 1, -1, -1):
                        line.append(boundary(a, b, tangent, lane, inward))
                    for inward in range(SIDE - split):
                        line.append(boundary(b, a, tangent, lane, inward))
                    assert(not line.has(-1), "Missing 5x5 physical edge cell")
                    lines.append(line)
    assert(lines.size() == EXPECTED_LINES)
    return lines

static func winning_lines(cells: Array, lines: Array, player: int) -> Array:
    var result: Array = []
    for line in lines:
        var complete: bool = true
        for c in line:
            if int(cells[int(c)]) != player:
                complete = false
                break
        if complete:
            result.append(line)
    return result

static func immediate_move(cells: Array, lines: Array, player: int) -> int:
    for line in lines:
        var own: int = 0
        var free: int = -1
        var valid: bool = true
        for c in line:
            var cell: int = int(c)
            if int(cells[cell]) == player:
                own += 1
            elif int(cells[cell]) == 0 and free == -1:
                free = cell
            else:
                valid = false
                break
        if valid and own == SIDE - 1 and free != -1:
            return free
    return -1

# Bounded tactical prototype (NOT a perfect solver). Never modifies input cells.
static func next_move(cells: Array, lines: Array, player: int, level: int = 1) -> int:
    if cells.size() != CELLS or (player != 1 and player != 2):
        return -1
    if not winning_lines(cells, lines, 1).is_empty() or not winning_lines(cells, lines, 2).is_empty():
        return -1
    var available: Array = []
    for c in range(CELLS):
        if int(cells[c]) == 0:
            available.append(c)
    if available.is_empty():
        return -1
    var win: int = immediate_move(cells, lines, player)
    if win >= 0:
        return win
    var block: int = immediate_move(cells, lines, 3 - player)
    if block >= 0:
        return block
    if level <= 0 and randf() < 0.40:
        return int(available.pick_random())
    var weights: Array = []
    weights.resize(CELLS)
    weights.fill(0.0)
    for line in lines:
        var own: int = 0
        var enemy: int = 0
        for c in line:
            if int(cells[int(c)]) == player:
                own += 1
            elif int(cells[int(c)]) == 3 - player:
                enemy += 1
        if own > 0 and enemy > 0:
            continue
        var score: float = 1.0
        if own > 0:
            score += float([0, 4, 14, 70, 600][own])
        if enemy > 0:
            score += float([0, 3, 12, 65, 520][enemy])
        for c in line:
            if int(cells[int(c)]) == 0:
                weights[int(c)] += score
    var best_score: float = -1.0
    var best: Array = []
    for c in available:
        var score: float = float(weights[int(c)])
        if score > best_score:
            best_score = score
            best = [c]
        elif is_equal_approx(score, best_score):
            best.append(c)
    return int(best.pick_random())
