extends SceneTree
# ZenCube 3D 2.0 UI upgrade regression:
# - real 2x2 Realm artwork teaser (DE/EN/PT)
# - Campaign is the PRIMARY choice and resumes the existing saved board
# - "New Match" in boss pause restarts the same boss without resetting awards
# All player/story saves are restored byte-for-byte after running.
const Realms = preload("res://core/ZenAscendRealms.gd")
const Story = preload("res://story/ZenRealmChronicles.gd")
var failures: int = 0

func check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        printerr("ZEN ASCEND ENTRY FLOW FAIL: ",reason)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var save_path: String = SaveManager.PATH
    var story_path: String = Story.SAVE
    var save_existed: bool = FileAccess.file_exists(save_path)
    var story_existed: bool = FileAccess.file_exists(story_path)
    var saved_bytes: PackedByteArray = FileAccess.get_file_as_bytes(save_path) if save_existed else PackedByteArray()
    var story_bytes: PackedByteArray = FileAccess.get_file_as_bytes(story_path) if story_existed else PackedByteArray()
    var player: Dictionary = SaveManager.defaults()
    player.ascension.rank = 3
    player.ascension.completed = [true,true,true,false,false]
    player.ascend.help_seen = true
    player.settings.intro_seen = true
    player.settings.language = "en"
    check(SaveManager.save_data(player),"temporary Zen Master rank save")

    var main_scene: PackedScene = load("res://Main.tscn") as PackedScene
    check(main_scene != null,"Classic main scene available")
    if main_scene != null:
        var main: Node = main_scene.instantiate()
        root.add_child(main)
        await process_frame
        var expected: Dictionary = {
            "de":"Zen Ascend betreten",
            "en":"Enter Zen Ascend",
            "pt":"Entrar no Zen Ascend"
        }
        for language in ["de","en","pt"]:
            (main.get("data") as Dictionary).settings.language = language
            main.call("open_ascend_intro")
            var popup: Node = main.get("popup")
            check(popup != null,"preview dialog opens " + language)
            if popup == null: continue
            var gallery: GridContainer = popup.find_child("AscendFourRealmSneakPeek",true,false) as GridContainer
            check(gallery != null,"actual Realm artwork gallery present " + language)
            if gallery != null:
                check(gallery.columns == 2 and gallery.get_child_count() == 4,"four cards in 2x2 gallery " + language)
                for realm in range(4):
                    var picture: TextureRect = gallery.find_child("AscendTeaserImage%d" % realm,true,false) as TextureRect
                    var name: Label = gallery.find_child("AscendTeaserCaption%d" % realm,true,false) as Label
                    var actual_art: Texture2D = load(Realms.REALM_ART[realm]) as Texture2D
                    check(picture != null and actual_art != null and picture.texture == actual_art,"real source image for Realm %d / %s" % [realm,language])
                    check(name != null and name.text == Realms.realm_name(realm,language),"localized Realm card %d / %s" % [realm,language])
            var enter: Button = popup.find_child("EnterZenAscend",true,false) as Button
            check(enter != null and enter.text == str(expected[language]),"localized Enter Zen Ascend button " + language)
            if enter != null:
                check(not enter.disabled and enter.pressed.get_connections().size() > 0,"enter action enabled and connected " + language)
            var snapshot: Array = (main.get("board") as BoardModel).cells.duplicate()
            check(snapshot.size() == 54,"viewing teaser never replaces the 3x3 board")
            main.call("close_modal")
        main.queue_free()
        await process_frame

    var story: Dictionary = Story.defaults()
    var game_cells: Array = []
    game_cells.resize(96)
    game_cells.fill(0)
    game_cells[0] = 1
    game_cells[4] = 2
    game_cells[10] = 1
    game_cells[14] = 2
    story.game = {"cells":game_cells,"turn":1,"result":0,"owners":[0,1],"last_human":10}
    check(Story.save_progress(story),"temporary in-progress first boss fight")
    var stored_pre: Dictionary = Story.load_progress()
    check(Story.valid_game(stored_pre.get("game",{})),"seeded saved boss game is structurally valid")
    check((stored_pre.get("game",{}) as Dictionary).get("cells",[]) == game_cells,"seeded saved board round-trips before entering")
    (player.settings as Dictionary).language = "en"
    check(SaveManager.save_data(player),"restore temporary enabled 4x4 save")

    var ascend_scene: PackedScene = load("res://Ascend.tscn") as PackedScene
    check(ascend_scene != null,"4x4 scene available")
    if ascend_scene != null:
        var ascend: Node = ascend_scene.instantiate()
        root.add_child(ascend)
        await process_frame
        var before_leaves: int = int((ascend.get("data") as Dictionary).economy.leaves)
        var wanted: Dictionary = {
            "de":"Zen Ascend Campaign",
            "en":"Zen Ascend Campaign",
            "pt":"Zen Ascend Campaign"
        }
        for language in ["de","en","pt"]:
            (ascend.get("data") as Dictionary).settings.language = language
            ascend.call("show_mode_picker")
            var dialog: Node = ascend.get("active_realm_dialog")
            check(dialog != null,"4x4 mode picker shown in " + language)
            if dialog == null: continue
            var first: Button = dialog.find_child("ZenAscendCampaignPrimary",true,false) as Button
            check(first != null,"Campaign primary action in " + language)
            if first != null:
                check(first.text.contains(str(wanted[language])),"localized primary title in " + language)
                check(first.pressed.get_connections().size() > 0,"campaign action connects to gameplay")
                var scroll: ScrollContainer = ascend.get("active_realm_scroll") as ScrollContainer
                if scroll != null and scroll.get_child_count() > 0:
                    var contents: VBoxContainer = scroll.get_child(0) as VBoxContainer
                    check(contents != null and contents.get_child(0) == first,"Campaign is FIRST selectable choice " + language)
        (ascend.get("data") as Dictionary).settings.language = "en"
        ascend.call("show_mode_picker")
        var campaign: Button = (ascend.get("active_realm_dialog") as Node).find_child("ZenAscendCampaignPrimary",true,false) as Button
        if campaign != null:
            campaign.pressed.emit()
            check(bool(ascend.get("realm_story_active")),"Campaign enters existing story, not a test-only mode")
            check(int(ascend.get("realm_story_stage")) == 0,"existing saved boss stage remains unchanged")
            var on_screen: Array = ascend.get("cells") as Array
            if on_screen != game_cells:
                var saved_now: Dictionary = Story.load_progress()
                printerr("DEBUG STORY RESUME expected marks=",96-game_cells.count(0)," actual=",96-on_screen.count(0),
                    " saved=",96-(saved_now.get("game",{}).get("cells",[]) as Array).count(0),
                    " on_screen 0..16=",on_screen.slice(0,16),
                    " expected 0..16=",game_cells.slice(0,16))
            check(on_screen == game_cells,"existing in-progress board resumes exactly")
            check((ascend.get("active_realm_dialog") as Node) != null,"existing boss intro/resume screen appears")
            ascend.call("_realm_story_begin")
            ascend.call("_realm_story_menu")
            var pause: Node = ascend.get("active_realm_dialog")
            var new_match: Button = pause.find_child("RealmChroniclesNewMatch",true,false) as Button
            check(new_match != null and new_match.text == "New match","New Match exists in paused boss battle")
            if new_match != null:
                new_match.pressed.emit()
                check(int(ascend.get("realm_story_stage")) == 0,"New Match restarts CURRENT boss only")
                check((ascend.get("cells") as Array).count(0) == 96,"New Match clears only current 96-cell board")
                check(int(ascend.get("result")) == 0,"New Match is playable")
                check(int(ascend.get("turn")) == 2,"New Match fairly flips opening player")
                check(int(Story.load_progress().retry_offset) == 1,"starter alternation persists")
                check(ascend.get("active_realm_dialog") == null,"New Match goes straight back to board")
                check(int((ascend.get("data") as Dictionary).economy.leaves) == before_leaves,"New Match creates no extra rewards")
        ascend.queue_free()
        await process_frame

    for filename in [save_path,story_path]:
        var existed: bool = save_existed if filename == save_path else story_existed
        var previous: PackedByteArray = saved_bytes if filename == save_path else story_bytes
        if existed:
            var out: FileAccess = FileAccess.open(filename,FileAccess.WRITE)
            if out != null:
                out.store_buffer(previous)
                out.close()
        elif FileAccess.file_exists(filename):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(filename))
    print("ZEN ASCEND ENTRY FLOW FAILURES=",failures)
    quit(0 if failures == 0 else 1)
