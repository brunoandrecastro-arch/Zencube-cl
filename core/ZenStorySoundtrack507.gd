extends RefCounted
# Campaign-only tracks; never change shop IDs or saved music preferences.
const Tower = preload("res://core/ZenTower.gd")
const FIRST_ID: int = 1000
const KEYS: Array[String] = ["act_1", "act_2", "act_3", "act_4", "moon_theme", "moon_echo_keeper", "moon_silent_ferryman", "moon_warden", "sky_theme", "sky_ending", "tower_menu", "tower_world_01", "tower_boss_01", "tower_world_02", "tower_boss_02", "tower_world_03", "tower_boss_03", "tower_world_04", "tower_boss_04", "tower_world_05", "tower_boss_05", "tower_world_06", "tower_boss_06", "tower_world_07", "tower_boss_07"]
const ROOT = "res://assets/music/story507/"

static func track_id(key: String) -> int:
    var index: int = KEYS.find(key)
    return FIRST_ID + index if index >= 0 else -1

static func path_for(key: String) -> String:
    return ROOT + key + ".ogg" if KEYS.has(key) else ""

static func stream_for(key: String) -> AudioStream:
    var path: String = path_for(key)
    if path.is_empty() or not ResourceLoader.exists(path): return null
    var stream: AudioStreamOggVorbis = load(path) as AudioStreamOggVorbis
    if stream != null: stream.loop = true
    return stream

static func stream_for_id(track: int) -> AudioStream:
    var index: int = track - FIRST_ID
    if index < 0 or index >= KEYS.size(): return null
    return stream_for(KEYS[index])

static func tower_key(stage: int) -> String:
    var section: int = Tower.section_index(stage) + 1
    return ("tower_boss_%02d" if Tower.is_boss(stage) else "tower_world_%02d") % section
