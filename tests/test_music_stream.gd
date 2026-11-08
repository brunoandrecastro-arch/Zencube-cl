extends SceneTree
var errors: int = 0
func test(condition: bool, detail: String) -> void:
    if not condition:
        errors += 1
        printerr("MUSIC FAIL: ", detail)
func _initialize() -> void:
    call_deferred("check_music")
func check_music() -> void:
    var scene = load("res://Main.tscn") as PackedScene
    if scene == null:
        printerr("MUSIC FAIL: Could not load Main.tscn")
        quit(1)
        return
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    var player = game.music_player as AudioStreamPlayer
    if player == null:
        printerr("MUSIC FAIL: ZenGardenMusic player missing")
        quit(1)
        return
    var stream = player.stream as AudioStreamWAV
    test(stream != null, "Expected PCM16 music stream")
    if stream != null:
        test(stream.data.size() >= 32000, "PCM music buffer missing")
        test(stream.format == AudioStreamWAV.FORMAT_16_BITS, "Wrong PCM format")
        test(stream.mix_rate == 16000, "Wrong PCM sample rate")
        test(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Music not looped")
        test(stream.loop_end == stream.data.size() / 2, "Incorrect loop end")
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
    print("Music stream check: ", errors, " failures (not an audible Android device test)")
    quit(1 if errors != 0 else 0)
