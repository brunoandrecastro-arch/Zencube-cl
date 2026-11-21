extends SceneTree
const DarkKuzeFixture = preload("res://tests/ActFourGateFixture.gd")
# ZenCube 2.0 Realm regression: real auto-awarded Realm tasks vs active Zen Challenges.
const Realm2 = preload("res://core/ZenRealmCampaign2.gd")
const Shadow = preload("res://story/ZenShadowCampaign.gd")
const Abyss = preload("res://story/ZenAbyssCampaign.gd")
const Realms = preload("res://core/ZenAscendRealms.gd")
const Reader = preload("res://story/ZenRealmChallengeMenu.gd")
var failed: int = 0
var snapshots: Dictionary = {}
func check(value: bool, what: String) -> void:
    if not value:
        failed += 1
        printerr("REALM 2.0: ",what)

func _initialize() -> void:
    call_deferred("run")

func backup(path: String) -> void:
    if FileAccess.file_exists(path): snapshots[path]=FileAccess.get_file_as_bytes(path)

func restore() -> void:
    for path in [Realm2.SAVE,Shadow.SAVE,Abyss.SAVE,SaveManager.PATH]:
        if snapshots.has(path):
            var f: FileAccess = FileAccess.open(path,FileAccess.WRITE)
            if f!=null:
                f.store_buffer(snapshots[path])
                f.close()
        elif FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func seed_story(chapter: int, done: bool) -> void:
    var story: Dictionary = Shadow.defaults() if chapter==0 else Abyss.defaults()
    story.defeated = [true,true,true]
    story.page = 30
    story.completed = done
    if chapter==0: check(Shadow.save_progress(story),"seed Shadow boss/story")
    else: check(Abyss.save_progress(story),"seed Abyss boss/story")

func run() -> void:
    for path in [Realm2.SAVE,Shadow.SAVE,Abyss.SAVE,SaveManager.PATH]:
        backup(path)
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    check(not Realm2.base_unlocked(),"4x4 gate is never bypassed just because test APK")
    check(not Realm2.unlocked(0),"Shadow locked without real Zen Master / purchased 4x4")
    check(Realm2.record_abyss_match(1,false).is_empty(),"practice cannot bypass locked 4x4")
    check(not Realm2.can_unlock(3,2,true),"3/3 automatic tasks mandatory")
    check(not Realm2.can_unlock(2,3,true),"3/3 story bosses mandatory")
    check(not Realm2.can_unlock(3,3,false),"final victory must wait for Finish Chapter")
    check(Realm2.can_unlock(3,3,true),"3+3 unlock predicate")
    var dark_kuze_gate = DarkKuzeFixture.new()
    check(dark_kuze_gate.grant(),"genuine finished Dark Kuze boss fight checkpoint")
    var data: Dictionary = SaveManager.defaults()
    data.ascension.rank = 3
    data.ascension.completed = [true,true,true,false,false]
    ZenAscend.ensure(data)
    Realms.ensure(data)
    data.ascend.help_seen = true
    data.settings.music = false
    check(SaveManager.save_data(data),"seed earned 4x4 entitlement")
    check(Realm2.base_unlocked(),"earned 4x4 access")
    check(Realm2.unlocked(0),"Shadow unlocked only after 4x4")
    check(Realm2.completed_count(Realm2.load_progress(),0)==0,"Shadow has no fake puzzle awards")
    check(Realm2.can_face_boss(0,0) and Realm2.can_face_boss(0,1),"first two Shadow battles need no challenges")
    check(not Realm2.can_face_boss(0,2),"final Shadow boss needs all three challenges")
    var old_realm: Dictionary = SaveManager.load_data()
    Realms.ensure(old_realm)
    for i in range(3):
        var task: Dictionary = Realm2.shadow_task(i)
        check(not task.is_empty(),"existing 4x4 Shadow milestone "+str(i))
        old_realm.ascend.realm_state.completed[str(task.id)]=true
    check(SaveManager.save_data(old_realm),"save genuine Shadow Realm milestones")
    check(Realm2.completed_count(Realm2.load_progress(),0)==3,"read Shadow milestones from original 4x4 stats")
    check(Realm2.can_face_boss(0,2),"all three challenges unlock final Shadow boss")
    check(not Realm2.unlocked(1),"Shadow milestones without bosses never unlock Abyss")
    var final_shadow: Dictionary = Shadow.defaults()
    final_shadow.defeated = [true,true,false]
    final_shadow.page = Shadow.GATES[2]
    check(Shadow.save_progress(final_shadow),"seed final guardian location")
    check(Realm2.final_boss_waiting(0),"final boss shortcut available at 3/3 and actual boss page")
    seed_story(0,false)
    check(not Realm2.unlocked(1),"no premature breakthrough before Finish Shadow chapter")
    seed_story(0,true)
    check(Realm2.unlocked(1),"3 bosses + three REAL Shadow bot milestones unlock Abyss")
    check(Realm2.task_title(0,2,"en")=="Veil Tactician","original Veil Tactician, not a selectable puzzle")
    check(Realm2.completed_count(Realm2.load_progress(),1)==0,"Abyss begins with zero true bot matches")
    check(Realm2.can_face_boss(1,0) and Realm2.can_face_boss(1,1),"first two Abyss bosses need no challenges")
    check(not Realm2.can_face_boss(1,2),"final Abyss boss locked before trials")
    check(Realm2.record_abyss_match(1,false).size()==1,"first genuine win auto-earns First Echo")
    check(Realm2.completed_count(Realm2.load_progress(),1)==1,"Abyss 1/3 after first match")
    check(Realm2.record_abyss_match(-1,false).is_empty(),"losing does not trigger extra achievement")
    check(Realm2.record_abyss_match(1,false).is_empty(),"second regular win, third requires total 3")
    var got: Array[String] = Realm2.record_abyss_match(1,true)
    check(got.size()==2,"third edge victory earns last two automatic tasks")
    check(Realm2.completed_count(Realm2.load_progress(),1)==3,"Abyss 3/3 auto milestones")
    check(Realm2.can_face_boss(1,2),"all three trials unlock final Abyss boss")
    check(not Realm2.unlocked(2),"Abyss 3 challenges without bosses cannot unlock Ember")
    seed_story(1,false)
    check(not Realm2.unlocked(2),"no premature breakthrough before Finish Abyss chapter")
    seed_story(1,true)
    check(Realm2.unlocked(2),"all Abyss bosses, story and 3 auto tasks unlock Ember")
    check(Realm2.enter_next_realm(0),"Shadow→Abyss may transition")
    check(Realm2.already_entered(0),"portal will only play on first entry")
    check(Realm2.enter_next_realm(1),"Abyss→Ember may transition")
    check(Realm2.already_entered(1),"Ember first-visit tracked")
    check(Reader!=null,"passive Realm Challenge cards import")
    check(ZenAscend.generate_lines().size()==204,"unchanged 4x4 win rules")
    var leaves_before: int = int(SaveManager.load_data().economy.leaves)
    var ascended_before: int = int(SaveManager.load_data().ascend.played)
    var packed: PackedScene = load("res://Ascend.tscn") as PackedScene
    check(packed!=null,"native 4x4 scene imports")
    if packed!=null:
        var old_scene: Node = current_scene
        var controller: Node = packed.instantiate()
        root.add_child(controller)
        current_scene = controller
        await process_frame
        controller.call("start_campaign_practice",1)
        check(bool(controller.get("campaign_practice_active")),"separate real Abyss Zen-Bot mode starts")
        check((controller.get("cells") as Array).size()==96,"96 real playable cube cells")
        check(not controller.has_method("start_campaign_challenge"),"no separate puzzle launcher exists")
        controller.call("_campaign_practice_back")
        await process_frame
        var nav: Node = root.get_node_or_null("ZenChronicles")
        check(nav!=null and nav.call("is_open"),"returns to passive challenge overview")
        if nav!=null: nav.call("close_campaign_challenges")
        await process_frame
        controller.call("show_rules")
        var dialog: Node = controller.get("active_realm_dialog")
        check(dialog!=null and dialog.find_child("AscendEntryChronicles",true,false)!=null,"first entry has direct Chronicles")
        controller.call("show_ascend_menu")
        dialog = controller.get("active_realm_dialog")
        check(dialog!=null and dialog.find_child("AscendSettingsEntry",true,false)!=null,"4x4 menu opens Settings")
        var board_before: Array = (controller.get("cells") as Array).duplicate()
        controller.call("show_ascend_settings")
        dialog = controller.get("active_realm_dialog")
        check(dialog!=null and dialog.find_child("AscendSettingsLanguage",true,false)!=null,"native Settings language picker")
        check(dialog!=null and dialog.find_child("AscendSettingsMusicTrack",true,false)!=null,"native Settings music picker")
        controller.call("_save_ascend_setting","language","pt")
        check(controller.get("cells")==board_before,"language settings do not reset board")
        controller.call("_save_ascend_setting","music",true)
        controller.call("_close_realm_dialog",dialog)
        if nav!=null:
            nav.call("open_shadow_reader")
            var old_reader: Node = nav.get("_shadow_reader")
            check(is_instance_valid(old_reader) and nav.call("campaign_audio_exclusive"),"Shadow owns exclusive music")
            var scene_music: AudioStreamPlayer = controller.get("world_music")
            check(is_instance_valid(scene_music) and not scene_music.playing,"scene music stops for Shadow")
            nav.call("open_abyss_reader")
            await process_frame
            var abyss_reader: Node = nav.get("_abyss_reader")
            check(is_instance_valid(abyss_reader) and nav.get("_story_audio_owner")==abyss_reader,"Abyss owns music after Shadow exit")
            check(not scene_music.playing,"closing previous reader cannot restart scene music")
            nav.call("close_abyss_reader")
            await process_frame
            check(not nav.call("campaign_audio_exclusive"),"closing final reader releases exclusive music")
        controller.queue_free()
        current_scene=old_scene
        await process_frame
    check(int(SaveManager.load_data().economy.leaves)==leaves_before,
        "Abyss practice does not invent shop rewards")
    check(int(SaveManager.load_data().ascend.played)==ascended_before,
        "Abyss practice does not inflate regular 4x4 wins")
    dark_kuze_gate.restore()
    restore()
    print("ZENCUBE 2.0 REALM FAILURES=",failed)
    quit(0 if failed==0 else 1)
