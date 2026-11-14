extends SceneTree
var failures: int = 0
func check(ok: bool, detail: String) -> void:
    if not ok:
        failures += 1
        printerr("RC4 MUSIC FAIL: " + detail)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var data: Dictionary = SaveManager.defaults()
    ZenCollection.ensure(data)
    check(int(data.settings.music_track) == 7, "Cyberwave is default")
    check(ZenCollection.music_unlocked(data, 7), "Cyberwave is always free")
    for t in range(8,14):
        check(not ZenCollection.music_unlocked(data, t), "new song locked %d" % t)
        check(not ZenCollection.buy_music(data, t), "no purchase without leaves %d" % t)
    data.economy.leaves = 400
    check(ZenCollection.buy_music(data, 8), "buy Zen Piano")
    check(int(data.economy.leaves) == 225, "price 175 leaves")
    check(not ZenCollection.buy_music(data, 8), "duplicate purchase blocked")
    check(int(data.economy.leaves) == 225, "duplicate purchase free")
    var parsed: Variant = JSON.parse_string(JSON.stringify(data))
    check(parsed is Dictionary, "save JSON survives")
    if parsed is Dictionary:
        ZenCollection.ensure(parsed)
        check(ZenCollection.music_unlocked(parsed,8), "purchases preserved")
    var before_exists: bool = FileAccess.file_exists(SaveManager.PATH)
    var before: PackedByteArray = PackedByteArray()
    if before_exists:
        before = FileAccess.get_file_as_bytes(SaveManager.PATH)
    var packed: PackedScene = load("res://Main.tscn") as PackedScene
    check(packed != null, "main scene")
    if packed == null:
        quit(1)
        return
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame
    game.data = SaveManager.defaults()
    ZenCollection.ensure(game.data)
    game.shop_tab = 1
    game.open_store()
    check(game.shop_tab == 1 and game.popup != null, "music tab opens")
    check(game.music_stream(7) is AudioStreamMP3, "Cyberwave MP3 imported")
    check(game.music_stream(13) is AudioStreamMP3, "last bonus imported")
    game.preview_shop_music(8)
    check(int(game.data.economy.leaves) == 0, "preview does not buy")
    check(not ZenCollection.music_unlocked(game.data,8), "preview does not unlock")
    game.stop_shop_preview()
    game.select_music_track(8)
    check(int(game.data.settings.music_track)==7, "cannot select locked")
    game.data.economy.leaves = 350
    game.store_select_music(8)
    check(int(game.data.settings.music_track)==8, "purchase selects")
    check(int(game.data.economy.leaves)==175, "only 175 leaves deducted")
    game.change_shop_tab(0)
    check(game.shop_tab==0, "skins tab opens")
    game.close_modal()
    game.queue_free()
    await process_frame
    if before_exists:
        var f: FileAccess = FileAccess.open(SaveManager.PATH, FileAccess.WRITE)
        check(f != null, "restore earlier game")
        if f != null:
            f.store_buffer(before)
            f.close()
    elif FileAccess.file_exists(SaveManager.PATH):
        var result: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.PATH))
        check(result == OK, "delete test save")
    print("RC4 MUSIC TAB FAILURES=", failures)
    quit(0 if failures == 0 else 1)
