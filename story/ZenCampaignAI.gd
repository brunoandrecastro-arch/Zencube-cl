extends RefCounted
## Demon personalities operate on the original 108 winning lines.
## Called by the existing bot worker with an independent snapshot.

# Attack, defence, chance to block an immediate threat.
const PROFILES := [
    [0.70, 0.10, 0.25], [2.00, 0.05, 0.22], [0.00, 2.20, 1.00],
    [1.20, 1.15, 0.90], [2.65, 0.26, 0.57], [1.90, 0.90, 0.82],
    [2.65, 0.48, 0.82], [1.75, 1.60, 1.00], [1.32, 1.95, 1.00],
    [1.82, 1.50, 1.00], [1.70, 1.75, 1.00],
]
const BUILD := [1.0, 4.0, 25.0]
const DENY := [0.0, 1.0, 5.0]

static func pick_move(cells_in: Array, stage: int, seed_value: int, context: Dictionary) -> int:
    var ai := AIEngine.new(seed_value)
    var legal := ai.legal(cells_in)
    if legal.is_empty():
        return -1
    var player := int(context.get("mark", 2))
    var opponent := 3 - player
    var last := int(context.get("last_cell", -1))
    var last_bot := int(context.get("last_bot", -1))
    if stage == 0 and ai.rng.randf() < 0.79:
        var options := legal.filter(func(cell): return last_bot < 0 or CubeGeometry.face(cell) != CubeGeometry.face(last_bot))
        return _random_from(ai.rng, options if not options.is_empty() else legal)

    var wins := ai.rules.threats(cells_in, player)
    if not wins.is_empty():
        return _random_from(ai.rng, wins)
    var blocks := ai.rules.threats(cells_in, opponent)
    var profile: Array = PROFILES[stage]
    if not blocks.is_empty() and ai.rng.randf() < float(profile[2]):
        return _random_from(ai.rng, blocks)
    if stage == 10 and legal.size() == 54:
        var openings: Dictionary = context.get("openings", {})
        var favorite := -1
        var frequency := 0
        for cell in legal:
            var count := int(openings.get(str(cell), 0))
            if count > frequency:
                favorite = cell
                frequency = count
        if favorite >= 0:
            return favorite
    if stage == 10 and last >= 0 and ai.rng.randf() < 0.40:
        # The Self recognises the player's patterns and sometimes reflects
        # the most recent stone before looking for a different plan.
        var mirror := -CubeGeometry.center(last)
        for cell in legal:
            if CubeGeometry.center(cell).is_equal_approx(mirror):
                return cell

    var cells := cells_in.duplicate()
    var hidden: Array = context.get("hidden_faces", [])
    var opposite := -1
    var last_position := Vector3.ZERO
    if last >= 0:
        opposite = CubeGeometry.N.find(-CubeGeometry.N[CubeGeometry.face(last)])
        last_position = CubeGeometry.center(last)
    var scores := PackedFloat32Array()
    scores.resize(cells.size())
    for line in ai.rules.lines:
        var own := 0
        var other := 0
        for tile in line:
            if cells[tile] == player:
                own += 1
            elif cells[tile] == opponent:
                other += 1
        var weight := 0.0
        if other == 0 and own < 3:
            weight = BUILD[own] * float(profile[0])
            if stage == 5 and own == 2:
                # The Name prefers a conspicuous two-plus-two line across an edge.
                var face := CubeGeometry.face(line[0])
                if line.filter(func(tile): return CubeGeometry.face(tile) == face).size() == 2:
                    weight += 18.0
            elif stage == 9 and own == 2:
                weight += 9.0
        elif own == 0 and other < 3:
            weight = DENY[other] * float(profile[1])
        for tile in line:
            if cells[tile] == 0:
                scores[tile] += weight

    var order: Array = []
    for cell in legal:
        var score := float(scores[cell]) + ai.rng.randf_range(-0.32, 0.32)
        if stage == 2 and last >= 0:
            score -= CubeGeometry.center(cell).distance_to(last_position)
        elif stage == 3 and CubeGeometry.face(cell) == opposite:
            score += 15.0 - CubeGeometry.center(cell).distance_to(-last_position) * 2.0
        elif stage == 7 and cell % 9 == 4:
            score += 13.0
        elif stage == 8 and hidden.has(CubeGeometry.face(cell)):
            score += 17.0
        order.append([cell, score])
    order.sort_custom(func(left, right): return left[1] > right[1])
    var best: int = order[0][0]
    if stage < 6 or order.size() < 2:
        return best

    # Reuse the Classic engine’s bounded reply search, with campaign ranking
    # deciding which candidates are worth searching on a phone.
    ai.deadline = Time.get_ticks_msec() + (130 if stage == 6 else 170)
    ai.branch_width = 6
    var best_score := -INF
    for candidate in order.slice(0, 5):
        var cell: int = candidate[0]
        cells[cell] = player
        var reply: float = -ai.search(cells, opponent, 1, -INF, INF)
        cells[cell] = 0
        if ai.timed_out:
            break
        var score := float(candidate[1]) + reply * 0.45
        if score > best_score:
            best_score = score
            best = cell
    return best

static func _random_from(random: RandomNumberGenerator, choices: Array) -> int:
    return int(choices[random.randi_range(0, choices.size() - 1)])
