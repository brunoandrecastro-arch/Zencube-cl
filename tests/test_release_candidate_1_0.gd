extends SceneTree
var failures: int = 0
func check(ok: bool, detail: String) -> void:
    if not ok:
        failures += 1
        printerr("ZEN RELEASE 1.0 FAIL: " + detail)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var scene: PackedScene = load("res://Main.tscn") as PackedScene
    check(scene != null, "Main scene")
    if scene == null:
        quit(1)
        return
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    check(game.renderer.tiles.size()==54 and game.rules.lines.size()==108, "original gameplay preserved")
    for track in range(7):
        var music: AudioStreamWAV = game.make_zen_music_stream(track)
        check(music!=null and music.data.size()>=300000,"music %d" % track)
    game.data.settings.music_track = 4
    game.select_music_track(4)
    check(int(game.data.settings.music_track)==4,"track 5 selectable")
    check(game.music_player != null and game.music_player.stream != null,"music player alive")
    game.select_music_track(5)
    check(int(game.data.settings.music_track)==4,"locked bonus music cannot be selected")
    check(game.data.has("economy"), "wallet available")
    game.queue_free()
    await process_frame
    print("ZEN RELEASE 1.0 CHECK FAILURES=",failures)
    quit(0 if failures==0 else 1)
