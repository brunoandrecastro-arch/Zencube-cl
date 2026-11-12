class_name ZenRealmMusic
extends RefCounted
## Four independently looped Zen Ascend music themes. They do NOT consume
## Music Shop IDs (0..13), change Classic World music or affect purchases.
const REALM_NAMES: Array[String] = ["Shadow Realm", "Ember Temple", "Celestial Realm", "Satori Realm"]
const REALM_SONGS: Array[String] = [
    "Whispers Beyond the Veil",
    "The Flame That Never Sleeps",
    "Where the Heavens Breathe",
    "The Sound of Awakening"
]
const STREAMS: Array = [
    preload("res://assets/realm_music/shadow_realm.ogg"),
    preload("res://assets/realm_music/ember_temple.ogg"),
    preload("res://assets/realm_music/celestial_realm.ogg"),
    preload("res://assets/realm_music/satori_realm.ogg")
]
static func stream_for(realm: int) -> AudioStream:
    if realm < 0 or realm >= STREAMS.size():
        return null
    var stream: AudioStreamOggVorbis = STREAMS[realm] as AudioStreamOggVorbis
    if stream != null:
        stream.loop = true
    return stream
