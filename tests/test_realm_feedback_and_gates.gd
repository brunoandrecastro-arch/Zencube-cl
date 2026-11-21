extends SceneTree
const DarkKuzeFixture = preload("res://tests/ActFourGateFixture.gd")
# Regression test for the approved feedback: no duplicate library entry,
# working finger swipe, 4x4 return, twelve victory art configurations,
# preserved shop skins and full-screen shatter for real Realm unlocks.
const Story = preload("res://story/ZenRealmChronicles.gd")
const Realms = preload("res://core/ZenAscendRealms.gd")
const Artwork = preload("res://ui/ZenRealmVictoryArtwork.gd")
const BossMusic = preload("res://core/ZenRealmBossMusic.gd")
var failures: int = 0
var backups: Dictionary = {}

func check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        printerr("REALM FEEDBACK FAIL: ",reason)

func _initialize() -> void:
    call_deferred("run")

func _buttons(node: Node, result: Array[String]) -> void:
    if node is Button: result.append(str(node.text))
    for child in node.get_children():
        _buttons(child,result)

func _backup(path: String) -> void:
    if FileAccess.file_exists(path):
        backups[path] = FileAccess.get_file_as_bytes(path)

func _restore() -> void:
    for path in [SaveManager.PATH,Story.SAVE]:
        if backups.has(path):
            var file := FileAccess.open(path,FileAccess.WRITE)
            if file != null:
                file.store_buffer(backups[path])
                file.close()
        elif FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func run() -> void:
    _backup(SaveManager.PATH)
    _backup(Story.SAVE)
    var qkey: String = "application/config/realm_chronicles_qa"
    var oldqa: bool = bool(ProjectSettings.get_setting(qkey,false))
    ProjectSettings.set_setting(qkey,false)
    var dark_kuze_gate = DarkKuzeFixture.new()
    check(dark_kuze_gate.grant(),"genuine finished Dark Kuze boss fight checkpoint")
    var data: Dictionary = SaveManager.defaults()
    data.ascension.rank = 3
    data.ascension.completed = [true, true, true, false, false] # Real Zen Master entitlement survives ZenAscension.ensure()
    data.ascend.help_seen = true
    data.settings.language = "de"
    Realms.ensure(data)
    check(SaveManager.save_data(data),"seed ordinary player")
    check(Story.save_progress(Story.defaults()),"seed story progress")
    var book: Node = root.get_node("ZenChronicles")
    book.call("open_library")
    var labels: Array[String] = []
    _buttons(book.get("_screen"),labels)
    check(labels.has("Zen Campaign · Play") or labels.size() > 0,"library remains functional")
    check(not labels.has(Story.text_for("de","menu_button")),"4x4 story is not duplicated in book library")
    book.call("open_realm_story_overview",true)
    await process_frame
    var screen: Node = book.get("_screen")
    var scroll: ScrollContainer = screen.find_child("RealmChroniclesChapterScroll",true,false) as ScrollContainer
    check(scroll != null,"chapter list has a real touch-scroll area")
    if scroll != null:
        check(scroll.get_v_scroll_bar().max_value > scroll.size.y,"four chapter cards exceed the scrolling viewport")
        var origin: Vector2 = scroll.get_global_rect().position + Vector2(30,80)
        var touch: InputEventScreenTouch = InputEventScreenTouch.new()
        touch.position = origin
        touch.pressed = true
        book.call("_input",touch)
        var drag: InputEventScreenDrag = InputEventScreenDrag.new()
        drag.position = origin + Vector2(0,-240)
        drag.relative = Vector2(0,-240)
        book.call("_input",drag)
        check(scroll.scroll_vertical > 0,"finger drag scrolls the full chapter list")
        touch.pressed = false
        touch.position = drag.position
        book.call("_input",touch)
    book.call("close_chronicles")
    # Real 4x4 scene: only the separate story state may change.
    var asc: PackedScene = load("res://Ascend.tscn") as PackedScene
    check(asc != null,"Ascend.tscn unchanged")
    if asc == null:
        ProjectSettings.set_setting(qkey,oldqa)
        _restore()
        quit(1)
        return
    var controller: Node = asc.instantiate()
    var previous: Node = current_scene
    root.add_child(controller)
    current_scene = controller
    await process_frame
    var regular_save: String = FileAccess.get_file_as_string(SaveManager.PATH)
    var normal_music: AudioStream = controller.call("desired_realm_stream")
    check(normal_music != null,"normal Realm/Shop soundtrack available before boss")
    controller.call("start_realm_story")
    check(bool(controller.get("realm_story_active")),"first boss starts in existing Ascend scene")
    var boss_player: AudioStreamPlayer = controller.get("world_music") as AudioStreamPlayer
    check(boss_player != null and boss_player.stream == BossMusic.stream_for(0),
        "starting a boss switches to its exclusive soundtrack")
    var cube: Node = controller.get("cube")
    check(int(cube.get("boss_skin_id"))==0,"real story skin active")
    var board: Array = controller.get("cells")
    var lines: Array = ZenAscend.generate_lines()
    var winning: Array = lines[0]
    board.fill(0)
    for n in range(3): board[int(winning[n])] = 1
    controller.set("cells",board)
    controller.set("turn",1)
    controller.set("result",0)
    controller.set("busy",false)
    controller.call("play",int(winning[3]))
    check(int(controller.get("result"))==1,"real four-in-a-row still wins")
    controller.call("_realm_story_result")
    await process_frame
    var dialog: Node = controller.get("active_realm_dialog")
    check(dialog != null,"win dialog visible")
    if dialog != null:
        check(dialog.find_child("ZenRealmVictoryArt_00",true,false) != null,
            "a unique Kuze + defeated-boss aftermath appears after victory")
        check(dialog.find_child("DefeatedBoss_00",true,false) != null,
            "victory composition contains actual boss art")
    for stage in range(Story.LAST_STAGE):
        var view: PanelContainer = Artwork.new()
        root.add_child(view)
        view.call("present",stage,"de")
        check(view.name=="ZenRealmVictoryArt_%02d" % stage,"distinct victory art %d" % stage)
        check(view.find_child("DefeatedBoss_%02d" % stage,true,false) != null,"unique boss art %d" % stage)
        check(not Story.text_for("en","victory_story_%d" % stage).is_empty(),"narrative continues after boss %d" % stage)
        view.queue_free()
    # Schedule one late story bot move and immediately exit. The timer must
    # never place a marker on the restored ordinary Ascend 4x4 board.
    controller.set("result",0)
    controller.set("recorded",false)
    controller.set("turn",2)
    controller.call_deferred("bot_turn")
    await process_frame
    controller.call("_realm_story_return_to_ascend")
    var restored_music: AudioStreamPlayer = controller.get("world_music") as AudioStreamPlayer
    check(restored_music != null and restored_music.stream == normal_music,
        "leaving a boss restores normal Realm/Shop soundtrack instead of looping boss theme")
    await create_timer(1.2).timeout
    check(int(controller.call("move_count"))==0,"pending story bot is cancelled after returning to Ascend")
    check(not bool(controller.get("realm_story_active")),"direct story exit returns to normal Zen Ascend")
    check(int(cube.get("boss_skin_id")) == -1,"normal 3D shop skin restored")
    check(FileAccess.get_file_as_string(SaveManager.PATH)==regular_save,"story does not alter normal stats, rank or money")
    var menu: Node = controller.get("active_realm_dialog")
    check(menu != null and menu.find_child("RealmChroniclesCampaignCard",true,false)==null,
        "Legacy story tile is absent from ordinary four-Realm menu (now in Zen Realm Chronicles)")
    # Realm access is locked until BOTH independent milestones are true.
    check(not Realms.unlocked(data,1),"Ember stays locked with zero story victories")
    for task in Realms.TASKS[0]:
        Realms.state(data).completed[str(task.id)] = true
    check(not Realms.unlocked(data,1),"8/8 alone must not unlock Ember")
    var milestones: Dictionary = Story.load_progress()
    milestones.stage = 3
    milestones.game = {}
    check(Story.save_progress(milestones),"record actual stage-3 milestone")
    check(Realms.unlocked(data,1),"8/8 plus 3/3 unlocks Ember")
    check(not Realms.unlocked(data,2),"Celestial still locked until own chapter")
    # The shatter is a full-screen part of the REALM unlock ceremony, but
    # not of a routine manually selected unlocked Realm.
    var fx: ZenRealmTravelCeremony = ZenRealmTravelCeremony.new()
    root.add_child(fx)
    fx.present(Realms.REALM_ART[0],Realms.REALM_ART[1],"Ember Temple",true,false,[],"de")
    await process_frame
    var glass: Node = fx.find_child("EpicRealmScreenFracture",true,false)
    check(glass != null,"new Realm begins with a full-screen glass mirror")
    if glass != null:
        check(glass.get_child_count() >= 60,"dozens of actual textured glass fragments")
        var shard: Polygon2D = glass.find_child("MirrorGlassShard_00",true,false) as Polygon2D
        check(shard != null and shard.texture != null,"mirror shards preserve old Realm artwork")
        if shard != null:
            var before: Vector2 = shard.position
            glass.set("crack_strength",1.0)
            glass.set("break_progress",0.85)
            check(shard.position.distance_to(before) > 10.0,
                "shards really leave their starting position after impact")
    var audio: AudioStreamPlayer = fx.get("_player") as AudioStreamPlayer
    check(audio != null and audio.stream == load("res://assets/audio/zen_mirror_shatter.wav"),
        "new realm breakthrough plays dedicated glass-break sound rather than gong")
    fx.close()
    # QA preview must be reachable without completing all 8 challenges and
    # must NEVER fake Realm unlocks, victories, or saved progression.
    ProjectSettings.set_setting(qkey,true)
    controller.call("show_realms")
    await process_frame
    var qa_menu: Node = controller.get("active_realm_dialog")
    check(qa_menu != null and qa_menu.find_child("RealmMirrorShatterPreviewQA",true,false) == null,
        "No extra mirror/legacy-story button in normal four-Realm UI")
    var normal_before: String = FileAccess.get_file_as_string(SaveManager.PATH)
    var story_before: String = FileAccess.get_file_as_string(Story.SAVE)
    controller.call("_preview_mirror_shatter_qa")
    await process_frame
    var preview_glass: Node = controller.find_child("EpicRealmScreenFracture",true,false)
    check(preview_glass != null,"preview invokes the real, shattering Realm animation")
    check(FileAccess.get_file_as_string(SaveManager.PATH) == normal_before and FileAccess.get_file_as_string(Story.SAVE) == story_before,
        "preview never mutates actual player saves")
    if preview_glass != null:
        preview_glass.get_parent().get_parent().call("close")
    ProjectSettings.set_setting(qkey,false)
    controller.queue_free()
    current_scene = previous
    ProjectSettings.set_setting(qkey,oldqa)
    dark_kuze_gate.restore()
    _restore()
    print("Realm feedback and combined gate: ",failures," failure(s)")
    quit(1 if failures>0 else 0)
