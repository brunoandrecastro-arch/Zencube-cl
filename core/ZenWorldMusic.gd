class_name ZenWorldMusic
extends RefCounted
# Playback of the same seven stable audio IDs in the independent Zen Ascend scene.
# The main scene retains its original music_stream() implementation.
const NEW_STREAMS = [
    preload("res://assets/music/cyberwave_main.mp3"),
    preload("res://assets/music/zen_piano.mp3"),
    preload("res://assets/music/velario_zen.mp3"),
    preload("res://assets/music/nature_wonder.mp3"),
    preload("res://assets/music/calm_spirit.mp3"),
    preload("res://assets/music/zen_of_nature.mp3"),
    preload("res://assets/music/sitar_story.mp3"),
]
const OLD_PCM = [
    "res://assets/zen_ambient_music.pcm",
    "res://assets/zen_bamboo_music.pcm",
    "res://assets/zen_moon_music.pcm",
    "res://assets/zen_flute_music.pcm",
    "res://assets/zen_koto_music.pcm",
    "res://assets/zen_regentropfen_music.pcm",
    "res://assets/zen_sternenlicht_music.pcm",
]

static func stream_for(track: int) -> AudioStream:
    if track >= 7 and track <= 13:
        var mp3: AudioStreamMP3 = NEW_STREAMS[track - 7] as AudioStreamMP3
        if mp3 != null:
            mp3.loop = true
            return mp3
        return null
    if track < 0 or track >= OLD_PCM.size():
        return null
    var pcm: PackedByteArray = FileAccess.get_file_as_bytes(OLD_PCM[track])
    if pcm.size() < 32000 or pcm.size() % 2 != 0:
        push_warning("ZenCube: missing legacy music PCM resource")
        return null
    var wav: AudioStreamWAV = AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.stereo = false
    wav.mix_rate = 16000
    wav.data = pcm
    wav.loop_begin = 0
    wav.loop_end = int(pcm.size() / 2)
    wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
    return wav
