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
func _find_story_thumbnail(node: Node) -> TextureRect:
    if node is TextureRect: return node as TextureRect
    for child in node.get_children():
        var found: TextureRect = _find_story_thumbnail(child)
        if found != null: return found
    return null
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
    var music_players: Array = [game.music_player, game.music_fade_player]
    game.data.settings.music = true
    game.data.settings.music_mode = "base"
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
        # The five original cosmetics remain intact; Sky Garden adds one
        # independent story-only 3x3 card and its own visual thumbnail.
        check(count_thumbnails(game.popup) == 6,"five premium cosmetics plus Sky Garden story thumbnail")
        var sky_card: Node = game.popup.find_child("SkyGardenClassicWorldCard",true,false)
        check(sky_card != null,"Sky Garden story card exists separately from Classic cosmetics")
        if sky_card != null:
            var sky_entry: Node = sky_card.find_child("SkyGardenClassicWorldEntry",true,false)
            check(sky_entry != null,"Sky Garden has its own story entry")
            var sky_thumb: TextureRect = null
            for child in sky_card.get_children():
                sky_thumb = _find_story_thumbnail(child)
                if sky_thumb != null: break
            check(sky_thumb != null and sky_thumb.texture != null,"Sky Garden thumbnail is loaded")
        check(ZenAscension.WORLD_TEXTURES.size() == 5,"five original cosmetic worlds remain unchanged")
    game.select_world(2)
    check(int(game.data.ascension.world) == 2,"player chose mountain temple")
    check(game.world_background.texture == ZenAscension.WORLD_TEXTURES[2],"mountain temple background active")
    check(game.music_player in music_players and game.music_player.playing, "world music plays on an existing audio player")
    check(game.music_player.get_meta("track", -1) == ZenMusicPolicy.WORLD_TRACKS[2], "mountain temple soundtrack active")
    check(game.board.snapshot() == prior_board,"world switch does not change game state")
    game.queue_free()
    await process_frame
    print("ZEN PREMIUM WORLDS CHECKS COMPLETE FAILURES=", failures)
    quit(0 if failures == 0 else 1)
