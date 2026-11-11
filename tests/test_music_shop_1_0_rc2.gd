extends SceneTree
var fails: int = 0
func check(value: bool, msg: String) -> void:
    if not value:
        fails += 1
        printerr("MUSIC SHOP FAIL: "+msg)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var data: Dictionary = SaveManager.defaults()
    ZenCollection.ensure(data)
    check(not ZenCollection.music_unlocked(data, 5), "first bonus locked")
    check(not ZenCollection.music_unlocked(data, 6), "second bonus locked")
    for i in range(5):
        check(ZenCollection.music_unlocked(data, i), "free song %d" % i)
    check(not ZenCollection.buy_music(data, 5), "insufficient balance rejected")
    data.economy.leaves = 400
    check(ZenCollection.buy_music(data, 5), "buy first bonus")
    check(int(data.economy.leaves) == 280, "first purchase deduct 120")
    check(not ZenCollection.buy_music(data, 5), "no duplicate purchase")
    check(int(data.economy.leaves) == 280, "duplicate has no cost")
    check(ZenCollection.buy_music(data, 6), "buy second bonus")
    check(int(data.economy.leaves) == 100, "second purchase deduct 180")
    var json_data: Variant = JSON.parse_string(JSON.stringify(data))
    check(json_data is Dictionary, "wallet serialized")
    if json_data is Dictionary:
        ZenCollection.ensure(json_data)
        check(ZenCollection.music_unlocked(json_data, 5) and ZenCollection.music_unlocked(json_data, 6), "wallet survives JSON reload")
    var scene: PackedScene = load("res://Main.tscn") as PackedScene
    check(scene != null, "Main scene")
    if scene == null:
        quit(1)
        return
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    game.data = SaveManager.defaults()
    ZenCollection.ensure(game.data)
    game.select_music_track(5)
    check(int(game.data.settings.music_track) == 0, "locked track cannot be selected")
    game.data.economy.leaves = 350
    game.store_select_music(5)
    check(int(game.data.settings.music_track) == 5 and ZenCollection.music_unlocked(game.data, 5), "shop purchase also selects")
    check(int(game.data.economy.leaves) == 230, "shop purchase costs 120")
    game.store_select_music(5)
    check(int(game.data.economy.leaves) == 230, "select again costs nothing")
    for i in range(7):
        var stream: AudioStreamWAV = game.make_zen_music_stream(i)
        check(stream != null and stream.data.size() > 500000, "music stream %d" % i)
    game.queue_free()
    await process_frame
    print("ZEN MUSIC SHOP 1.0 RC2 FAILURES=",fails)
    quit(0 if fails == 0 else 1)
