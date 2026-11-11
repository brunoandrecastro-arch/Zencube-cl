extends SceneTree
var errors: int = 0
func test(condition: bool, detail: String) -> void:
    if not condition:
        errors += 1
        printerr("MUSIC FAIL: ", detail)
func _initialize() -> void:
    call_deferred("check_music")
func check_music() -> void:
    var scene: PackedScene = load("res://Main.tscn") as PackedScene
    if scene == null:
        printerr("MUSIC FAIL: Could not load Main.tscn")
        quit(1)
        return
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    var player: AudioStreamPlayer = game.music_player as AudioStreamPlayer
    if player == null:
        printerr("MUSIC FAIL: ZenGardenMusic player missing")
        quit(1)
        return
    var selected_stream: AudioStream = player.stream
    test(selected_stream != null, "Selected music stream missing")
    test(selected_stream is AudioStreamWAV or selected_stream is AudioStreamMP3, "Expected PCM or MP3 audio")
    if selected_stream is AudioStreamMP3:
        test((selected_stream as AudioStreamMP3).loop, "MP3 music does not loop")
    var legacy_stream: AudioStreamWAV = game.make_zen_music_stream(0)
    test(legacy_stream != null, "Original PCM music missing")
    if legacy_stream != null:
        test(legacy_stream.data.size() >= 32000, "PCM music buffer missing")
        test(legacy_stream.format == AudioStreamWAV.FORMAT_16_BITS, "Wrong PCM format")
        test(legacy_stream.mix_rate == 16000, "Wrong PCM sample rate")
        test(legacy_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "PCM music not looped")
        test(legacy_stream.loop_end == legacy_stream.data.size() / 2, "Incorrect PCM loop end")
    test(player.volume_db >= -3.0, "Music far too quiet")
    game.music_preview()
    test(player.playing, "Music preview does not start playback")
    game.data.settings.music = false
    game.sync_music()
    test(not player.playing, "Music should stop when disabled")
    game.data.settings.music = true
    game.sync_music()
    test(player.playing, "Music should start when enabled")
    game.queue_free()
    await process_frame
    print("Music stream check: ",errors," failures")
    quit(1 if errors != 0 else 0)
