extends SceneTree
# Live smoke test of world and quote changes without touching gameplay rules.
const Locale = preload("res://core/ZenLocalization.gd")
var failures: int = 0
func check(value: bool, info: String) -> void:
    if not value:
        failures += 1
        printerr("WORLD QUOTES FAIL: " + info)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var packed: PackedScene = load("res://Main.tscn") as PackedScene
    check(packed != null,"Main.tscn exists")
    if packed == null:
        quit(1)
        return
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame
    if game.popup != null:
        game.close_modal()
    # Grant tiers in this in-memory test only, then check all five Classic Worlds.
    game.data.ascension.completed = [true,true,true,true,true]
    ZenAscension.ensure(game.data)
    for language in ["de","en","pt"]:
        game.data.settings.language = language
        for world in range(5):
            game.data.ascension.world = world
            game.refresh()
            check(game.world_title_label.text == Locale.translate(ZenAscension.WORLDS[world],language), "header world %d / %s" % [world,language])
            check(game.world_quote_label.text == Locale.translate(game.WORLD_QUOTES[world],language), "footer quote %d / %s" % [world,language])
            check(game.world_background.texture == ZenAscension.WORLD_TEXTURES[world], "scene World %d" % world)
            check(game.world_quote_label.visible, "footer should remain visible")
    check(game.board.cells.size()==54,"Classic cube remains 54 cells")
    game.queue_free()
    print("WORLD QUOTES FAILURES=",failures)
    quit(1 if failures > 0 else 0)
