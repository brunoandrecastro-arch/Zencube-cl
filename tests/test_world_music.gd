extends SceneTree
# Godot 4.5.1: headless checks without touching a real player save.
var failures: int = 0
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        printerr("WORLD MUSIC FAIL: " + message)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var data: Dictionary = SaveManager.defaults()
    ZenCollection.ensure(data)
    check(ZenMusicPolicy.mode(data) == "base", "new game defaults to Base")
    for world in range(5):
        data.ascension.world = world
        check(ZenMusicPolicy.selected_track(data) == ZenMusicPolicy.WORLD_TRACKS[world], "World %d soundtrack" % world)
    data.ascension.world = 0
    data.settings.music_mode = "manual"
    data.settings.music_track = 7
    check(ZenMusicPolicy.selected_track(data) == 7, "free manual selection")
    data.settings.music_track = 10
    check(ZenMusicPolicy.selected_track(data) == 7, "unowned manual selection rejected")
    data.economy.leaves = 400
    check(ZenCollection.buy_music(data, 10), "buy music with earned currency")
    var remaining: int = int(data.economy.leaves)
    check(not ZenCollection.buy_music(data, 10), "no repeat charge")
    check(int(data.economy.leaves) == remaining, "currency preserved")
    for world in range(5):
        data.ascension.world = world
        check(ZenMusicPolicy.selected_track(data) == 10, "owned manual track works in World %d" % world)
    data.settings.music_mode = "base"
    data.ascension.world = 3
    check(ZenMusicPolicy.selected_track(data) == 8, "Base restores World 3 song")
    check(data.economy.owned_music.has(10), "Base doesn't erase purchases")
    for track in range(7,14):
        var stream: AudioStream = ZenWorldMusic.stream_for(track)
        check(stream is AudioStreamMP3, "MP3 resource for track %d" % track)
        if stream is AudioStreamMP3:
            check(stream.loop, "automatic looping for track %d" % track)
    check(ZenMusicPolicy.base_label("de") != ZenMusicPolicy.base_label("en"), "localized German and English")
    check(ZenMusicPolicy.base_label("pt") != ZenMusicPolicy.base_label("en"), "European Portuguese")
    print("WORLD MUSIC FAILURES=", failures)
    quit(0 if failures == 0 else 1)
