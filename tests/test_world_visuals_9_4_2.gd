extends SceneTree
# Five premium backgrounds on the original renderer; worlds are visual only.
var failures: int = 0
func check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        printerr("PREMIUM WORLD FAIL: "+reason)
func count_thumbnails(node: Node) -> int:
    var total: int = 1 if node is TextureRect else 0
    for child in node.get_children():
        total += count_thumbnails(child)
    return total
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var packed: PackedScene = load("res://Main.tscn") as PackedScene
    check(packed != null,"main scene loaded")
    if packed == null:
        quit(1)
        return
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame
    check(game.renderer.tiles.size() == 54, "original cube has 54 tiles")
    var original_lines: int = game.rules.lines.size()
    check(original_lines == 108,"108 original win lines")
    var old_music = game.music_player
    var prior_board = game.board.snapshot()
    game.data.ascension.completed = [true,true,true,true,true]
    ZenAscension.ensure(game.data)
    for i in range(5):
        game.data.ascension.world = i
        game.refresh()
        check(game.current_world == i,"world index %d" % i)
        check(game.world_background.texture == ZenAscension.WORLD_TEXTURES[i],"world art %d" % i)
        check(game.renderer.tiles.size() == 54,"cube survives world %d" % i)
    game.open_worlds()
    check(game.popup != null,"premium worlds menu")
    if game.popup != null:
        check(count_thumbnails(game.popup) == 5,"five independent thumbnails")
    game.select_world(2)
    check(int(game.data.ascension.world) == 2,"player chose mountain temple")
    check(game.world_background.texture == ZenAscension.WORLD_TEXTURES[2],"mountain temple background active")
    check(game.music_player == old_music,"music player preserved")
    check(game.board.snapshot() == prior_board,"world switch does not change game state")
    game.queue_free()
    await process_frame
    print("ZEN PREMIUM WORLDS CHECKS COMPLETE FAILURES=", failures)
    quit(0 if failures == 0 else 1)
