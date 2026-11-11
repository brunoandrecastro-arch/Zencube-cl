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
    # Each CI smoke test must start from an unowned music catalog, even when
    # a previous test has purchased songs in the same Godot user:// folder.
    var had_save: bool = FileAccess.file_exists(SaveManager.PATH)
    var original_save: PackedByteArray = PackedByteArray()
    if had_save:
        original_save = FileAccess.get_file_as_bytes(SaveManager.PATH)
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    game.data = SaveManager.defaults()
    ZenCollection.ensure(game.data)
    check(not ZenCollection.music_unlocked(game.data, 5), "new save: first bonus locked")
    check(not ZenCollection.music_unlocked(game.data, 6), "new save: second bonus locked")
    check(game.renderer.tiles.size()==54 and game.rules.lines.size()==108, "original gameplay preserved")
    for track in range(7):
        var music: AudioStreamWAV = game.make_zen_music_stream(track)
        check(music!=null and music.data.size()>=300000,"music %d" % track)
    game.select_music_track(4)
    check(int(game.data.settings.music_track)==4,"track 5 selectable")
    check(game.music_player != null and game.music_player.stream != null,"music player alive")
    game.select_music_track(5)
    check(int(game.data.settings.music_track)==4,"locked bonus music cannot be selected")
    check(game.data.has("economy"), "wallet available")
    game.queue_free()
    await process_frame
    # select_music_track() persists automatically; do not contaminate the
    # next test or the developer's existing local save.
    if had_save:
        var restore_file: FileAccess = FileAccess.open(SaveManager.PATH, FileAccess.WRITE)
        check(restore_file != null, "restore saved game after test")
        if restore_file != null:
            restore_file.store_buffer(original_save)
            restore_file.close()
    elif FileAccess.file_exists(SaveManager.PATH):
        var remove_error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.PATH))
        check(remove_error == OK, "delete temporary test save")
    print("ZEN RELEASE 1.0 CHECK FAILURES=",failures)
    quit(0 if failures==0 else 1)
