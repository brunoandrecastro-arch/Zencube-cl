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

static func ensure(data: Dictionary) -> void:
    if not data.get("ascension") is Dictionary:
        data["ascension"] = {}
    var asc: Dictionary = data["ascension"]
    var raw_completed: Variant = asc.get("completed", [])
    var completed: Array = raw_completed if raw_completed is Array else []
    var normalized: Array = [false, false, false, false, false]
    for i in range(mini(5, completed.size())):
        normalized[i] = bool(completed[i])
    # Credit victories recorded in the earlier three-level version.
    var wins: Array = data.get("stats", {}).get("ai_wins", [])
    for i in range(mini(3, wins.size())):
        if int(wins[i]) > 0:
            normalized[i] = true
    asc["completed"] = normalized
    var rank: int = 0
    while rank < 5 and normalized[rank]:
        rank += 1
    asc["rank"] = rank
    asc["world"] = clampi(int(asc.get("world", mini(rank, 4))), 0, mini(rank, 4))

static func clear_level(data: Dictionary, level: int) -> Dictionary:
    ensure(data)
    var before: int = int(data.ascension.rank)
    if level < 0 or level >= 5:
        return {"rank_up": false, "old_rank": before, "new_rank": before}
    # A player may practise any level, but ascending requires sequential wins.
    data.ascension.completed[level] = true
    ensure(data)
    var after: int = int(data.ascension.rank)
    if after > before:
        data.ascension.world = mini(after, 4)
    return {"rank_up": after > before, "old_rank": before, "new_rank": after}

static func level_unlocked(data: Dictionary, level: int) -> bool:
    ensure(data)
    return level >= 0 and level < 5 and level <= int(data.ascension.rank)

static func world_unlocked(data: Dictionary, world: int) -> bool:
    ensure(data)
    return world >= 0 and world < 5 and world <= int(data.ascension.rank)
