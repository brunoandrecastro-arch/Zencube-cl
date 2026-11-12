class_name ZenBotAutoLevel
extends RefCounted
# This maps the classic Zen rank to the next bot tier, without changing
# the actual rank exam or the player's ability to select lower tiers.
# Ranks: 0 beginner, 1 student, 2 adept, 3 master, 4 sage, 5 guardian.
# Bot levels: 0 easy, 1 medium, 2 hard, 3 master, 4 grandmaster.
static func level_for_rank(rank: int) -> int:
    return clampi(rank, 0, 4)

static func apply_after_rank_up(data: Dictionary, result: Dictionary) -> bool:
    if not bool(result.get("rank_up", false)):
        return false
    if not data.get("settings") is Dictionary:
        return false
    var rank: int = int(result.get("new_rank",data.get("ascension",{}).get("rank",0)))
    data.settings["level"] = level_for_rank(rank)
    return true
