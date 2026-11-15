extends RefCounted
## Demon personalities scored on the same canonical winning lines as the player.
## Called on the existing bot worker. Uses only the supplied board and profile.

# The Eleventh Night, The Lord and The Self use the existing tactical search.
const ATTACK := [0.8, 2.0, 0.0, 0.9, 2.8, 1.5, 0.0, 0.0, 0.85, 1.2]
const DEFENCE := [0.6, 0.14, 2.6, 1.0, 0.4, 0.75, 0.0, 0.0, 1.7, 1.5]
const BLOCK_CHANCE := [0.62, 0.16, 1.0, 1.0, 0.55, 0.73, 0.0, 0.0, 1.0, 1.0]
const BUILD := [0.0, 1.0, 6.0, 31.0]
const DENY := [0.0, 0.4, 4.0, 42.0]

static func pick_move(cells: Array, stage: int, seed_value: int, player: int,
        last_cell: int, hidden_faces: Array, openings: Array) -> int:
    var bot := AIEngine.new(seed_value)
    var legal: Array = bot.legal(cells)
    if legal.is_empty():
        return -1
    if stage == 0 and bot.rng.randf() < 0.76:
        var last_face := CubeGeometry.face(last_cell) if last_cell >= 0 else -1
        var scattered := legal.filter(func(cell: int): return CubeGeometry.face(cell) != last_face)
        var choices: Array = legal if scattered.is_empty() else scattered
        return int(choices[bot.rng.randi_range(0, choices.size() - 1)])
    if stage == 6:
        return bot.choose(cells, player, 2, 200)
    if stage == 7:
        if legal.size() == cells.size():
            return 4
        return bot.choose(cells, player, 3, 220)

    var wins := bot.rules.threats(cells, player)
    if not wins.is_empty():
        return int(wins[bot.rng.randi_range(0, wins.size() - 1)])
    var blocks := bot.rules.threats(cells, 3 - player)
    if stage == 10:
        if not blocks.is_empty():
            return int(blocks[0])
        if cells.count(player) == 0 and openings.size() == cells.size():
            var favorite: int = 0
            var copied: int = -1
            for cell in legal:
                if int(openings[cell]) > favorite:
                    favorite = int(openings[cell])
                    copied = cell
            if copied >= 0:
                return copied
        return bot.choose(cells, player, 4, 300)
    if stage == 3 and blocks.is_empty() and last_cell >= 0:
        var opposite := -CubeGeometry.center(last_cell)
        for cell in legal:
            if CubeGeometry.center(cell).is_equal_approx(opposite):
                return cell

    # When a demon overlooks defence, drop its explicit blocking preference.
    var block_now: bool = not blocks.is_empty() and bot.rng.randf() < float(BLOCK_CHANCE[stage])
    var scores := PackedFloat32Array()
    scores.resize(cells.size())
    for line in bot.rules.lines:
        var own: int = 0
        var other: int = 0
        var faces: Array[int] = []
        for cell in line:
            if cells[cell] == player:
                own += 1
            elif cells[cell] != 0:
                other += 1
            var face := CubeGeometry.face(cell)
            if not faces.has(face):
                faces.append(face)
        var weight := 0.0
        if other == 0 and own < 4:
            weight += (BUILD[own] + 0.15) * ATTACK[stage]
            if stage == 5 and faces.size() >= 3:
                weight += 2.5 + 3.0 * own
            if stage == 9 and own == 2:
                # A tempting isolated line gives way to overlapping threats.
                weight += 10.0
        if own == 0 and other < 4 and (other < 3 or block_now):
            weight += DENY[other] * DEFENCE[stage]
        for cell in line:
            if cells[cell] == 0:
                scores[cell] += weight

    var candidates: Array = blocks if block_now else legal
    var best: int = int(candidates[0])
    var best_score := -INF
    for cell in candidates:
        var score := float(scores[cell]) + bot.rng.randf_range(-0.34, 0.34)
        if stage == 8 and hidden_faces.has(CubeGeometry.face(cell)):
            score += 4.0
        if score > best_score:
            best = cell
            best_score = score
    return best
