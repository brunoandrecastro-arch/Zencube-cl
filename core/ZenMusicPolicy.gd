class_name ZenMusicPolicy
extends RefCounted
# Each World has a default theme. IDs 7..13 always stay unchanged.
const WORLD_TRACKS: Array[int] = [7, 9, 11, 8, 12]

static func base_label(language: String) -> String:
    match language:
        "en": return "Base – Automatic World Music"
        "pt": return "Base – Música automática de cada mundo"
        _: return "Base – Automatische World-Musik"

static func mode(data: Dictionary) -> String:
    var raw: String = str(data.get("settings", {}).get("music_mode", "base"))
    return raw if raw in ["base", "manual"] else "base"

static func world_track(world: int) -> int:
    return WORLD_TRACKS[clampi(world, 0, 4)]

static func selected_track(data: Dictionary) -> int:
    var world: int = int(data.get("ascension", {}).get("world", 0))
    if mode(data) == "base":
        # World music does not require a separate purchase while in that world.
        return world_track(world)
    var chosen: int = clampi(int(data.get("settings", {}).get("music_track", 7)), 0, 13)
    # A separately owned manual selection works throughout every World.
    return chosen if ZenCollection.music_unlocked(data, chosen) else world_track(world)
