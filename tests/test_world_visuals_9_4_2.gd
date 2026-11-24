extends SceneTree
const Moon = preload("res://story/ZenShatteredMoonCampaign.gd")
const SkyGarden = preload("res://story/ZenSkyGardenCampaign.gd")
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
func check_world_menu(game: Node, sky_visible: bool) -> void:
    check(is_instance_valid(game.popup),"premium worlds menu")
    if not is_instance_valid(game.popup): return
    check(count_thumbnails(game.popup)==(6 if sky_visible else 4),"only unlocked story artwork appears in Worlds")
    var sky_card: Node = game.popup.find_child("SkyGardenClassicWorldCard",true,false)
    check((sky_card!=null)==sky_visible,"Sky Garden story card follows completed Shattered Moon")
    if sky_card!=null:
        var sky_entry: Button = sky_card.find_child("SkyGardenClassicWorldEntry",true,false) as Button
        check(sky_entry!=null and not sky_entry.disabled,"unlocked Sky Garden has a usable story entry")
        var sky_thumb: TextureRect = _find_story_thumbnail(sky_card)
        check(sky_thumb!=null and sky_thumb.texture!=null,"Sky Garden thumbnail is loaded")
    check(ZenAscension.WORLD_TEXTURES.size()==5,"all five original cosmetic resources remain unchanged")

func check_touch_scroll(game: Node, context: String) -> void:
    var scroll: ScrollContainer = game.popup.find_child("FeedbackTouchScroll",true,false) as ScrollContainer
    check(scroll!=null,context+" exposes its Android touch scroll area")
    if scroll==null: return
    scroll.scroll_vertical = 0
    var bar: VScrollBar = scroll.get_v_scroll_bar()
    check(bar.max_value>bar.page,context+" actually overflows the viewport")
    var origin: Vector2 = scroll.get_global_rect().position + Vector2(30,80)
    var touch := InputEventScreenTouch.new()
    touch.index = 0
    touch.position = origin
    touch.pressed = true
    game.call("_input",touch)
    var drag := InputEventScreenDrag.new()
    drag.index = 0
    drag.position = origin + Vector2(0,-180)
    drag.relative = Vector2(0,-180)
    game.call("_input",drag)
    check(scroll.scroll_vertical>0,context+" scrolls with a finger drag")
    touch.position = drag.position
    touch.pressed = false
    game.call("_input",touch)

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
    # Exercise both actual save-backed gate states, then restore the original save.
    var moon_existed: bool = FileAccess.file_exists(Moon.SAVE)
    var moon_backup: PackedByteArray = FileAccess.get_file_as_bytes(Moon.SAVE) if moon_existed else PackedByteArray()
    var moon_progress: Dictionary = Moon.defaults()
    check(Moon.save_progress(moon_progress),"write isolated unfinished Moon fixture")
    check(not SkyGarden.unlocked(),"Sky Garden locked before Shattered Moon")
    game.open_worlds()
    await process_frame
    check_world_menu(game,false)
    moon_progress.defeated = [true,true,true]
    moon_progress.page = 30
    check(Moon.save_progress(moon_progress),"all Moon bosses beaten but chapter not confirmed")
    check(not SkyGarden.unlocked(),"final chapter confirmation still required")
    game.open_worlds()
    await process_frame
    check_world_menu(game,false)
    check(Moon.finish_chapter(moon_progress),"finish the Moon fixture")
    check(SkyGarden.unlocked(),"Sky Garden unlocks after finishing Moon")
    game.open_worlds()
    await process_frame
    await process_frame
    check_world_menu(game,true)
    check_touch_scroll(game,"Worlds")
    game.open_settings()
    await process_frame
    await process_frame
    check_touch_scroll(game,"Settings")
    check(game.popup.find_child("SettingsDoneSticky",true,false)!=null,"Settings retains its sticky Done button")
    game.open_worlds()
    await process_frame
    if moon_existed:
        var f := FileAccess.open(Moon.SAVE,FileAccess.WRITE)
        f.store_buffer(moon_backup)
        f.close()
    elif FileAccess.file_exists(Moon.SAVE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(Moon.SAVE))
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
