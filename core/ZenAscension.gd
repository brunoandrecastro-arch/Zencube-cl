class_name ZenAscension
extends RefCounted
# Five genuine bot levels, five earned ranks, and five visual worlds.
# Rank 0 is the original Zen garden. Old Classic saves remain VERSION=3.
const LEVELS = ["Leicht", "Mittel", "Schwer", "Meister", "Großmeister"]
const RANKS = ["Zen-Anfänger", "Zen-Schüler", "Zen-Adept", "Zen-Meister", "Zen-Weiser", "Zen-Wächter"]
const WORLDS = ["Zen-Garten", "Bambuspfad", "Bergtempel", "Mondgarten", "Himmelsgarten"]
const WORLD_TEXTURES = [
    preload("res://assets/zen_garden_scene.webp"),
    preload("res://assets/zen_world_bamboo.webp"),
    preload("res://assets/zen_world_temple.webp"),
    preload("res://assets/zen_world_moon.webp"),
    preload("res://assets/zen_world_heaven.webp")
]

# Rank exams: first three tiers require cumulative wins; last two require a streak.
# An existing 9.4 completed tier is grandfathered in so earned worlds/ranks survive.
const TARGETS = [3, 5, 7, 3, 5]
const FIRST_STREAK_LEVEL = 3

static func ensure(data: Dictionary) -> void:
    if not data.get("ascension") is Dictionary:
        data["ascension"] = {}
    var asc: Dictionary = data["ascension"]
    var raw_completed: Variant = asc.get("completed", [])
    var completed: Array = raw_completed if raw_completed is Array else []
    var normalized: Array = [false, false, false, false, false]
    for i in range(mini(5, completed.size())):
        normalized[i] = bool(completed[i])
    # Historical stats count towards the cumulative exams. Previously earned
    # 9.4 completion flags (including higher ranks) are never revoked.
    var wins: Array = data.get("stats", {}).get("ai_wins", [])
    for i in range(mini(3, wins.size())):
        if int(wins[i]) >= int(TARGETS[i]):
            normalized[i] = true
    asc["completed"] = normalized
    var raw_streaks: Variant = asc.get("streaks", [])
    var previous_streaks: Array = raw_streaks if raw_streaks is Array else []
    var streaks: Array = [0, 0, 0, 0, 0]
    for i in range(3, mini(5, previous_streaks.size())):
        streaks[i] = clampi(int(previous_streaks[i]), 0, int(TARGETS[i]))
    asc["streaks"] = streaks
    var rank: int = 0
    while rank < 5 and normalized[rank]:
        rank += 1
    asc["rank"] = rank
    asc["world"] = clampi(int(asc.get("world", mini(rank, 4))), 0, mini(rank, 4))

static func target(level: int) -> int:
    return int(TARGETS[clampi(level, 0, 4)])

static func is_streak(level: int) -> bool:
    return level >= FIRST_STREAK_LEVEL

static func progress(data: Dictionary, level: int) -> int:
    ensure(data)
    if level < 0 or level >= 5:
        return 0
    if bool(data.ascension.completed[level]):
        return target(level)
    if is_streak(level):
        return clampi(int(data.ascension.streaks[level]), 0, target(level))
    var wins: Array = data.get("stats", {}).get("ai_wins", [])
    return clampi(int(wins[level]) if wins.size() > level else 0, 0, target(level))

static func record_match(data: Dictionary, level: int, outcome: int) -> Dictionary:
    # Called once for each completed CPU match, BEFORE ai_wins/ai_losses is
    # incremented by GameController. 1 = player win, 0 = draw, -1 = loss.
    ensure(data)
    var before: int = int(data.ascension.rank)
    var result: Dictionary = {"rank_up": false, "old_rank": before, "new_rank": before}
    if level < 0 or level >= 5 or outcome not in [-1, 0, 1]:
        return result
    if bool(data.ascension.completed[level]) or level > before:
        return result
    if is_streak(level):
        if outcome == 1:
            data.ascension.streaks[level] = mini(target(level), int(data.ascension.streaks[level]) + 1)
        else:
            # Draws and defeats both break a consecutive-win exam.
            data.ascension.streaks[level] = 0
        if int(data.ascension.streaks[level]) >= target(level):
            data.ascension.completed[level] = true
    elif outcome == 1:
        # Legacy and current counters are already persisted. The result now
        # being recorded is NOT in ai_wins yet, so count this final win once.
        var wins: Array = data.get("stats", {}).get("ai_wins", [])
        var already_won: int = maxi(0, int(wins[level])) if wins.size() > level else 0
        if already_won + 1 >= target(level):
            data.ascension.completed[level] = true
    ensure(data)
    var after: int = int(data.ascension.rank)
    if after > before:
        data.ascension.world = mini(after, 4)
    result["rank_up"] = after > before
    result["new_rank"] = after
    return result

static func level_unlocked(data: Dictionary, level: int) -> bool:
    ensure(data)
    return level >= 0 and level < 5 and level <= int(data.ascension.rank)

static func world_unlocked(data: Dictionary, world: int) -> bool:
    ensure(data)
    return world >= 0 and world < 5 and world <= int(data.ascension.rank)
