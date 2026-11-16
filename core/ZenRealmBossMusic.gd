extends RefCounted
## Twelve original looping Boss Battle tracks for Zen Ascend Realm Chronicles.
## Boss songs override realm/shop background only while playing the 4x4 story.
## They do not add Shop IDs, modify coins/leaves, or alter Classic audio.
## OGG assets are deployed separately to res://assets/realm_boss_music/.
## If the assets have not yet been copied into the branch, normal realm music
## remains available as a safe fallback (no missing-resource compile errors).
const BOSS_IDS: Array[String] = [
    "mist_guardian", "mirror_novice", "veil_monk",
    "ash_runner", "banner_guardian", "ember_high_priest",
    "wind_scribe", "bridge_sentinel", "sky_archivist",
    "lotus_witness", "halo_keeper", "fully_aware"
]
const TRACK_TITLES: Array[String] = [
    "Whispers of Doubt", "Mirror of Regret", "The Mask of Fear",
    "Ashes of Anger", "Burning Resolve", "Heart of the Inferno",
    "Wings of Silence", "The Celestial Trial", "Keeper of the Stars",
    "Stillness Before Dawn", "The Weight of Self", "Beyond the Self"
]
static var _cache: Dictionary = {}

static func path_for(stage: int) -> String:
    if stage < 0 or stage >= BOSS_IDS.size(): return ""
    return "res://assets/realm_boss_music/%s.ogg" % BOSS_IDS[stage]

static func title_for(stage: int) -> String:
    if stage < 0 or stage >= TRACK_TITLES.size(): return ""
    return TRACK_TITLES[stage]

static func stream_for(stage: int) -> AudioStream:
    var path: String = path_for(stage)
    if path.is_empty(): return null
    if _cache.has(stage): return _cache[stage] as AudioStream
    # Godot import-aware: binaries only become available after the ZIP has
    # been added to the development branch and the normal asset import runs.
    if not ResourceLoader.exists(path): return null
    var stream: AudioStreamOggVorbis = ResourceLoader.load(path) as AudioStreamOggVorbis
    if stream == null: return null
    stream.loop = true
    _cache[stage] = stream
    return stream
