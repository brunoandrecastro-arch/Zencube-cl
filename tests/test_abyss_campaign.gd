extends SceneTree
const DarkKuzeFixture = preload("res://tests/ActFourGateFixture.gd")
## Campaign 2.0 headless smoke and save-isolation test.
const Abyss = preload("res://story/ZenAbyssCampaign.gd")
const Series = preload("res://core/ZenFinalGuardianSeries.gd")
const Skins = preload("res://core/ZenAbyssSkins.gd")
const Reader = preload("res://story/ZenAbyssReader.gd")
const Shadow = preload("res://story/ZenShadowCampaign.gd")
const Realm2 = preload("res://core/ZenRealmCampaign2.gd")
var failures: int = 0
var backups: Dictionary = {}

func check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        printerr("ABYSS TEST FAIL: ",reason)

func _initialize() -> void:
    call_deferred("run")

func _backup(path: String) -> void:
    if FileAccess.file_exists(path):
        backups[path] = FileAccess.get_file_as_bytes(path)

func _restore() -> void:
    for path in [Abyss.SAVE,Shadow.SAVE,Realm2.SAVE,SaveManager.PATH]:
        if backups.has(path):
            var file := FileAccess.open(path,FileAccess.WRITE)
            if file != null:
                file.store_buffer(backups[path])
                file.close()
        elif FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func run() -> void:
    _backup(Abyss.SAVE)
    _backup(Shadow.SAVE)
    _backup(Realm2.SAVE)
    _backup(SaveManager.PATH)
    check(Abyss.BOSS_IDS.size()==3,"three unique bosses")
    check(Abyss.GATES==[6,15,25],"bosses appear on pages 6, 15 and 25")
    check(Abyss.CONTINUE_PAGES==[7,16,26],"post-victory pages correct")
    check(Abyss.BOT_LEVELS==[1,2,2],"Medium Hard fixed final guardian difficulty")
    check(Abyss.page_path(1).ends_with("page_01.webp"),"first page path")
    check(Abyss.page_path(30).ends_with("page_30.webp"),"last page path")
    check(Abyss.page_path(31)=="","no page beyond story")
    check(Skins.PROFILES.size()==4,"four Abyss-only cube materials")
    for i in range(4):
        var material: ImageTexture = Skins.make_surface(i)
        check(material != null and material.get_width()==160,"procedural skin "+str(i))
    var lines: Array = ZenAscend.generate_lines()
    check(lines.size()==204,"use original 204 native 4x4 winning lines")
    var empty: Array = []
    empty.resize(96)
    empty.fill(0)
    for boss in range(3):
        var move: int = Abyss.choose_move(empty,lines,boss)
        check(move>=0 and move<96,"legal native bot opening "+str(boss))
    var state: Dictionary = Abyss.defaults()
    check(Abyss.save_progress(state),"new independent save writes")
    check(Abyss.page_limit(state)==6,"first boss cannot be skipped")
    for boss in range(3):
        state.page = Abyss.GATES[boss]
        check(Abyss.next_action(state).get("type")=="battle","gate "+str(boss))
        var first: Dictionary = Abyss.begin_battle(state,boss)
        check(first.cells.size()==96,"native 96-cell board "+str(boss))
        check(first.turn in [1,2],"legal first player "+str(boss))
        check(Abyss.save_progress(state),"save active match "+str(boss))
        var loaded: Dictionary = Abyss.load_progress()
        check(not loaded.game.is_empty(),"resume previous battle "+str(boss))
        state.game = {}
        var retry: Dictionary = Abyss.begin_battle(state,boss)
        check(retry.turn != first.turn,"alternate starter on retry "+str(boss))
        retry.result = 1
        state.game = retry
        check(Abyss.save_progress(state),"save actual round result")
        if boss==2:
            check(not Abyss.record_victory(state,boss),"only one final round win cannot advance")
            check(int(Series.score(Abyss.load_progress()).player)==1,"1:0 persists across restart")
            state = Abyss.load_progress()
            check(Series.start_next(state),"next round enabled")
            var second: Dictionary = Abyss.begin_battle(state,boss)
            check(int(second.turn)!=int(retry.turn),"starter alternates in series")
            second.result = 1
            check(Abyss.save_progress(state),"second round saved")
        check(Abyss.record_victory(state,boss),"record a real engine-approved victory "+str(boss))
        check(int(state.page)==Abyss.CONTINUE_PAGES[boss],"new page unlocked "+str(boss))
        check(Abyss.load_progress().page==Abyss.CONTINUE_PAGES[boss],"victory survives restart "+str(boss))
    check(Abyss.page_limit(state)==30,"all 30 pages unlocked after third win")
    state.page = 30
    check(Abyss.finish_chapter(state),"finish after page 30")
    check(Abyss.load_progress().completed,"ending persists")
    var scene: PackedScene = load("res://Ascend.tscn")
    check(scene != null,"unchanged native 4x4 scene can be loaded")
    var script: Script = Reader
    check(script != null,"native Manhwa reader script imports")
    var has_media: bool = FileAccess.file_exists(Abyss.page_path(1))
    if has_media:
        for p in range(1,31):
            check(ResourceLoader.exists(Abyss.page_path(p)),"every story picture "+str(p))
        for b in range(3):
            check(ResourceLoader.exists(Abyss.boss_art(b)),"HD boss art "+str(b))
            check(Abyss.boss_stream(b)!=null,"original boss soundtrack "+str(b))
        check(Abyss.story_stream()!=null,"story background soundtrack")
    else:
        print("ABYSS MEDIA PENDING: upload both ZIPs for complete Android build")
    # Exercise the actual Ascend.tscn controller and full-screen ZenChronicles reader.
    # This is a separately saved campaign and never awards normal rank/leaf wins.
    var dark_kuze_gate = DarkKuzeFixture.new()
    check(dark_kuze_gate.grant(),"genuine completed Dark Kuze story unlock")
    var user: Dictionary = SaveManager.defaults()
    user.ascension.rank = 3
    user.ascension.completed = [true,true,true,false,false]
    ZenAscend.ensure(user)
    ZenAscendRealms.ensure(user)
    user.ascend.help_seen = true
    user.settings.music = false
    check(SaveManager.save_data(user),"seed legal native 4x4 entitlement")
    # Campaign 2.0 now requires the actual Shadow story AND three regular
    # Shadow Zen-Bot achievements before entering Abyss.
    var old_shadow: Dictionary = Shadow.defaults()
    old_shadow.defeated = [true,true,true]
    old_shadow.page = 30
    old_shadow.completed = true
    check(Shadow.save_progress(old_shadow),"seed completed predecessor story")
    for i in range(3):
        var task: Dictionary = Realm2.shadow_task(i)
        ZenAscendRealms.state(user).completed[str(task.id)] = true
    check(SaveManager.save_data(user),"seed three original Shadow Realm bot milestones")
    check(Realm2.unlocked(1),"Abyss is genuinely unlocked via 3+3")
    check(Realm2.enter_next_realm(0),"the first Shadow→Abyss portal has already been watched for this boss fixture")
    var campaign: Dictionary = Abyss.defaults()
    campaign.page = 6
    check(Abyss.save_progress(campaign),"seed first battle gate")
    if scene != null:
        var original_scene: Node = current_scene
        var controller: Node = scene.instantiate()
        root.add_child(controller)
        current_scene = controller
        await process_frame
        check(controller.has_method("start_abyss_battle"),"native Ascend controller has Abyss mode")
        controller.call("start_abyss_battle")
        check(bool(controller.get("abyss_active")),"first boss actually launches in 3D scene")
        check(int(controller.get("abyss_index"))==0,"first boss is Memory Thief")
        var cube: Node = controller.get("cube")
        check(cube != null and int(cube.get("abyss_skin_id"))==1,"unique 3D Memory Thief surface is active")
        controller.call("_abyss_back_to_reader")
        await process_frame
        var book: Node = root.get_node("ZenChronicles")
        check(book.call("is_open"),"native Manhwa reader opens after leaving battle")
        check(int(Abyss.load_progress().page)==6,"leaving unfinished boss does not skip page gate")
        book.call("close_abyss_reader")
        await process_frame
        controller.queue_free()
        current_scene = original_scene
        await process_frame
    check(int(SaveManager.load_data().get("ascend",{}).get("played",0))==0,
        "Abyss match does not add normal 4x4 rank wins")
    dark_kuze_gate.restore()
    _restore()
    print("ABYSS CAMPAIGN TEST FAILURES=",failures)
    quit(0 if failures==0 else 1)
