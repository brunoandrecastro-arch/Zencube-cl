extends SceneTree
# Campaign 2.0 Shadow Realm headless native integration checks.
const Shadow = preload("res://story/ZenShadowCampaign.gd")
const Series = preload("res://core/ZenFinalGuardianSeries.gd")
const Reader = preload("res://story/ZenShadowReader.gd")
const Original = preload("res://story/ZenRealmChronicles.gd")
var failures: int = 0
var backups: Dictionary = {}

func check(ok: bool, label: String) -> void:
    if not ok:
        failures += 1
        printerr("SHADOW CAMPAIGN FAIL: ",label)

func _initialize() -> void:
    call_deferred("run")

func _backup(path: String) -> void:
    if FileAccess.file_exists(path): backups[path] = FileAccess.get_file_as_bytes(path)

func _restore() -> void:
    for path in [Shadow.SAVE,Original.SAVE,SaveManager.PATH]:
        if backups.has(path):
            var f := FileAccess.open(path,FileAccess.WRITE)
            if f != null:
                f.store_buffer(backups[path])
                f.close()
        elif FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func run() -> void:
    _backup(Shadow.SAVE)
    _backup(Original.SAVE)
    _backup(SaveManager.PATH)
    check(Series.REALM_LEVELS==[1,2,3,2,4],"agreed fixed final guardian difficulty policy")
    var fixture: Dictionary = Shadow.defaults()
    fixture.defeated = [true,true,false]
    fixture.page = Shadow.GATES[2]
    var round_data: Dictionary = Shadow.begin_battle(fixture,2)
    round_data.result = 3
    Series.settle(fixture)
    check(int(Series.score(fixture).player)==0 and int(Series.score(fixture).guardian)==0,"draw earns no series point")
    check(Series.start_next(fixture),"draw may be replayed")
    var first_loss: Dictionary = Shadow.begin_battle(fixture,2)
    check(int(first_loss.turn)!=int(round_data.turn),"starter alternates after draw")
    first_loss.result = 2
    Series.settle(fixture)
    check(Series.start_next(fixture),"one loss does not end series")
    var second_loss: Dictionary = Shadow.begin_battle(fixture,2)
    second_loss.result = 2
    Series.settle(fixture)
    check(Series.guardian_won(fixture),"two losses end series")
    check(not Shadow.record_victory(fixture,2),"lost series cannot unlock story")
    check(Series.start_next(fixture),"explicit retry of lost series")
    check(int(Series.score(fixture).player)==0 and int(Series.score(fixture).guardian)==0,"retry starts at 0:0")
    var retry_round: Dictionary = Shadow.begin_battle(fixture,2)
    retry_round.result = 1
    Series.settle(fixture)
    Series.settle(fixture)
    check(int(Series.score(fixture).player)==1,"count monotonic after restarting series")
    check(Shadow.BOSS_IDS==["mist_guardian","mirror_novice","veil_monk"],"preserve existing Shadow boss identities")
    check(Shadow.GATES==[10,20,27],"remake gates before victories on pages 11,21,28")
    check(Shadow.CONTINUE_PAGES==[11,21,28],"remake resumes after each boss without skipping its victory page")
    check(Shadow.BOT_LEVELS==[1,1,1],"all Shadow bosses retain Medium AI")
    check(Shadow.page_path(1).ends_with("page_01.webp"),"first page")
    check(Shadow.page_path(30).ends_with("page_30.webp"),"last page")
    check(Shadow.page_path(31)=="","no invalid page")
    var lines: Array = ZenAscend.generate_lines()
    check(lines.size()==204,"unchanged native 4x4 204 winning lines")
    var empty: Array = []
    empty.resize(96)
    empty.fill(0)
    for b in range(3):
        var art: Texture2D = Shadow.boss_art(b)
        check(art!=null,"existing illustrated Shadow boss portrait "+str(b))
        var song: AudioStream = Shadow.boss_stream(b)
        check(song!=null,"original Shadow boss soundtrack "+str(b))
        check(Shadow.choose_move(empty,lines,b)>=0,"existing tactical bot "+str(b))
    check(Shadow.battle_backdrop()!=null,"Shadow Realm arena exists")
    check(Shadow.story_stream()!=null,"Shadow realm soundtrack exists")
    var page_files: int = 0
    for page in range(1,31):
        if ResourceLoader.exists(Shadow.page_path(page)): page_files += 1
    check(page_files==0 or page_files==30,"all 30 pages must be supplied together")
    var state: Dictionary = Shadow.defaults()
    check(Shadow.save_progress(state),"independent Shadow save writes")
    check(Shadow.page_limit(state)==10,"first gate cannot be skipped before the first depicted win")
    for index in range(3):
        state.page = Shadow.GATES[index]
        check(Shadow.next_action(state).get("type")=="battle","boss gate "+str(index))
        var game: Dictionary = Shadow.begin_battle(state,index)
        check(game.cells.size()==96,"native 96-cell Shadow board "+str(index))
        check(Shadow.save_progress(state),"save in-progress match "+str(index))
        var loaded: Dictionary = Shadow.load_progress()
        check(not loaded.game.is_empty(),"restart restores battle "+str(index))
        check(not Shadow.record_victory(state,index),"unwon boss never unlocks next pages")
        state.game = {}
        var retry: Dictionary = Shadow.begin_battle(state,index)
        check(int(retry.turn)!=int(game.turn),"starter alternates on retry "+str(index))
        retry.result = 1
        state.game = retry
        check(Shadow.save_progress(state),"save actual round result")
        if index==2:
            check(not Shadow.record_victory(state,index),"first final round win keeps gate locked")
            check(int(Series.score(Shadow.load_progress()).player)==1,"1:0 survives restart")
            state = Shadow.load_progress()
            check(Shadow.save_progress(state),"repeated save is idempotent")
            check(int(Series.score(state).player)==1,"no duplicate round point")
            check(Series.start_next(state),"advance series")
            var second: Dictionary = Shadow.begin_battle(state,index)
            check(int(second.turn)!=int(retry.turn),"alternate series starter")
            second.result = 2
            check(Shadow.save_progress(state),"save second round loss")
            check(int(Series.score(state).guardian)==1,"1:1 allows decider")
            check(Series.start_next(state),"third round")
            var third: Dictionary = Shadow.begin_battle(state,index)
            third.result = 1
            check(Shadow.save_progress(state),"decider saved")
        check(Shadow.record_victory(state,index),"validated victory opens chapter "+str(index))
        check(int(Shadow.load_progress().page)==Shadow.CONTINUE_PAGES[index],"save resumes after boss "+str(index))
    check(Shadow.page_limit(state)==30,"all 30 Shadow pages unlock after three victories")
    state.page = 30
    check(Shadow.finish_chapter(state),"chapter can finish only after all bosses")
    check(Shadow.load_progress().completed,"Chapter 1 completion saved")
    var original_before: String = FileAccess.get_file_as_string(Original.SAVE) if FileAccess.file_exists(Original.SAVE) else ""
    var base_before: String = FileAccess.get_file_as_string(SaveManager.PATH) if FileAccess.file_exists(SaveManager.PATH) else ""
    var data: Dictionary = SaveManager.defaults()
    data.ascension.rank = 3
    data.ascension.completed = [true,true,true,false,false]
    ZenAscend.ensure(data)
    ZenAscendRealms.ensure(data)
    data.ascend.help_seen = true
    data.settings.music = false
    check(SaveManager.save_data(data),"create legitimate 4x4 test entitlement")
    var seeded: Dictionary = Shadow.defaults()
    seeded.page = Shadow.GATES[0]
    check(Shadow.save_progress(seeded),"seed first boss")
    var scene: PackedScene = load("res://Ascend.tscn") as PackedScene
    check(scene!=null,"existing native 3D scene imports")
    check(Reader!=null,"Shadow full-screen reader script imports")
    if scene!=null:
        var previous: Node = current_scene
        var controller: Node = scene.instantiate()
        root.add_child(controller)
        current_scene = controller
        await process_frame
        controller.call("start_shadow_battle")
        check(bool(controller.get("shadow_active")),"Shadow starts on actual 3D cube")
        check(int(controller.get("shadow_index"))==0,"first battle Mist Guardian")
        var cube: Node = controller.get("cube")
        check(cube!=null and int(cube.get("boss_skin_id"))==0,"original boss 3D material applied")
        controller.call("_shadow_back_to_reader")
        await process_frame
        var book: Node = root.get_node("ZenChronicles")
        check(bool(book.call("is_open")),"Shadow reader returns after boss")
        check(int(Shadow.load_progress().page)==10,"unfinished fight does not skip the new gate")
        book.call("close_shadow_reader")
        await process_frame
        controller.queue_free()
        current_scene = previous
        await process_frame
    check(FileAccess.get_file_as_string(Original.SAVE)==original_before if original_before!="" else not FileAccess.file_exists(Original.SAVE),
        "original Realm Chronicles progress remains untouched")
    _restore()
    print("SHADOW CAMPAIGN FAILURES=",failures," / 30 user pages in repo=",page_files)
    quit(0 if failures==0 else 1)
