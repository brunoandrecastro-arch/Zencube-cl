extends SceneTree
const DarkKuzeFixture = preload("res://tests/ActFourGateFixture.gd")
# Smoke-test the real Zen Chronicles chapter overview and isolated QA buttons
# for the two new Realms. Does not start a new release or change game stats.
const Story = preload("res://story/ZenRealmChronicles.gd")
const Moon = preload("res://story/ZenShatteredMoonCampaign.gd")
const SkyGarden = preload("res://story/ZenSkyGardenCampaign.gd")
const Satori = preload("res://story/ZenSatoriCampaign.gd")
const Fracture = preload("res://story/ZenFractureState.gd")
var errors: int = 0
var old_qa: bool
var save_backup: PackedByteArray = PackedByteArray()
var existed: bool = false

func test(condition: bool, label: String) -> void:
    if not condition:
        errors += 1
        printerr("REALM MENU FAIL: ",label)

func _initialize() -> void:
    call_deferred("run")

func _buttons(node: Node, result: Array) -> void:
    if node is Button:
        result.append(node)
    for child in node.get_children():
        _buttons(child,result)

func check_chapter_visibility(controller: Node, chronicles: Node, moon_visible: bool, sky_visible: bool) -> void:
    controller.call("show_realms")
    var dialog: Node = controller.get("active_realm_dialog")
    test(is_instance_valid(dialog),"realms menu exists in every gate state")
    if is_instance_valid(dialog):
        test((dialog.find_child("ShatteredMoonStoryRealmCard",true,false)!=null)==moon_visible,"Realm menu Moon visibility")
        test((dialog.find_child("SkyGardenEpilogueRealmCard",true,false)!=null)==sky_visible,"Realm menu Sky Garden visibility")
    chronicles.set("_library_tab",1)
    chronicles.call("open_library")
    var screen: Node = chronicles.get("_screen")
    if is_instance_valid(screen):
        test((screen.find_child("RealmCardShatteredMoon",true,false)!=null)==moon_visible,"Chronicles Moon visibility")
        test((screen.find_child("RealmCardSkyGarden",true,false)!=null)==sky_visible,"Chronicles Sky Garden visibility")
        test(screen.find_child("ShatteredMoonLibraryShortcut",true,false)==null and screen.find_child("SkyGardenLibraryShortcut",true,false)==null,"no duplicate secret chapter shortcuts")
    else:
        test(false,"Chronicles library exists in every gate state")
    chronicles.call("close_chronicles")

func run() -> void:
    var path: String = SaveManager.PATH
    var chapter_backups: Dictionary = {}
    for chapter_path in [Satori.SAVE,Moon.SAVE,Fracture.PATH]:
        chapter_backups[chapter_path] = FileAccess.get_file_as_bytes(chapter_path) if FileAccess.file_exists(chapter_path) else null
    test(Satori.save_progress(Satori.defaults()),"reset isolated Satori fixture")
    test(Moon.save_progress(Moon.defaults()),"reset isolated Moon fixture")
    existed = FileAccess.file_exists(path)
    if existed: save_backup = FileAccess.get_file_as_bytes(path)
    var dark_kuze_gate = DarkKuzeFixture.new()
    test(dark_kuze_gate.grant(),"genuine finished Dark Kuze boss fight checkpoint")
    test(Fracture.mark_awakening(),"isolated post-Act-IV cinematic checkpoint")
    var data: Dictionary = SaveManager.defaults()
    data.ascension.rank = 3
    data.ascension.completed = [true, true, true, false, false] # Real Zen Master entitlement survives ZenAscension.ensure()
    data.settings.language = "de"
    SaveManager.save_data(data)
    old_qa = bool(ProjectSettings.get_setting("application/config/realm_chronicles_qa",false))
    ProjectSettings.set_setting("application/config/realm_chronicles_qa",true)
    # ZenChronicles is an autoload and already attached to /root in Godot tests.
    var chronicles: Node = root.get_node_or_null("ZenChronicles")
    test(chronicles!=null,"Chronicles autoload accessible")
    if chronicles!=null:
        chronicles.call("open_realm_story_overview")
        var screen: Node = chronicles.get("_screen")
        test(screen!=null,"four-chapter overview creates its real canvas")
        if screen!=null:
            var buttons: Array = []
            _buttons(screen,buttons)
            var labels: Array = []
            for button in buttons: labels.append(str(button.text))
            test(labels.has(Story.text_for("de","qa_ember")),"Ember QA chapter button visible")
            test(labels.has(Story.text_for("de","qa_celestial")),"Celestial QA chapter button visible")
            test(labels.has(Story.text_for("de","qa_satori")),"Satori QA chapter button visible")
            test(chronicles.has_method("_launch_chapter_qa"),"working shared chapter QA launcher is connected")
            var cards: Array = []
            # Four realm chapter cards retain the correct visual art paths.
            for chapter in range(4):
                test(ResourceLoader.exists(Story.CHAPTER_ART[chapter]),"chapter hero art included "+str(chapter))
        chronicles.call("close_chronicles")
    # New single entrance: Legacy/Manhwa belongs in Zen Realm Chronicles,
    # while the 4x4 Realm screen contains the five existing cards plus one story-only Moon card.
    var ascend_scene: PackedScene = load("res://Ascend.tscn") as PackedScene
    test(ascend_scene != null,"4x4 Ascend scene is still loadable")
    if ascend_scene != null and chronicles != null:
        var controller: Node = ascend_scene.instantiate()
        var previous_scene: Node = current_scene
        root.add_child(controller)
        current_scene = controller
        await process_frame
        var ordinary_save: String = FileAccess.get_file_as_string(SaveManager.PATH)
        controller.call("show_realms")
        var modal: Node = controller.get("active_realm_dialog")
        test(is_instance_valid(modal),"the normal 4x4 Realm menu opens")
        if is_instance_valid(modal):
            test(modal.find_child("RealmChroniclesCampaignCard",true,false)==null,
                "no duplicate story card in the normal four-Realm menu")
            test(modal.find_child("RealmChroniclesCampaignOpen",true,false)==null,
                "no duplicate Open Story button")
            var content: Node = controller.get("active_realm_scroll")
            if content != null:
                var count: int = 0
                for item in content.get_children():
                    for card in item.get_children():
                        if card is PanelContainer: count += 1
                var expected: int = 5 + int(Moon.unlocked()) + int(SkyGarden.unlocked())
                test(count==expected,"five main Realms plus only earned secret chapters")
                var ordered: Array[String] = []
                for item in content.get_children():
                    for card in item.get_children():
                        if card is PanelContainer:
                            var labels_in_card: Array = []
                            _buttons(card,labels_in_card)
                            ordered.append(str(card.name))
                test(modal.find_child("Campaign2AbyssRealmCard",true,false)!=null,"Abyss card exists")
                test(modal.find_child("Campaign2ChroniclesEntry",true,false)!=null,"dedicated Chronicles entry exists")
                test(ordered.size()>=5 and ordered[1]=="Campaign2AbyssRealmCard","Abyss is immediately after Shadow")
                test((modal.find_child("ShatteredMoonStoryRealmCard",true,false)!=null)==Moon.unlocked(),
                    "Shattered Moon remains hidden until Satori is finished")
                test((modal.find_child("SkyGardenEpilogueRealmCard",true,false)!=null)==SkyGarden.unlocked(),
                    "Sky Garden remains hidden until Shattered Moon is finished")
                test((modal.find_child("ShatteredMoonStoryRealmButton",true,false)!=null)==Moon.unlocked(),
                    "Shattered Moon has a direct story entry only when earned")
        check_chapter_visibility(controller,chronicles,false,false)
        var satori_progress: Dictionary = Satori.defaults()
        satori_progress.defeated = [true,true,true]
        satori_progress.page = 30
        test(Satori.finish_chapter(satori_progress),"finish isolated Satori fixture")
        check_chapter_visibility(controller,chronicles,true,false)
        var moon_progress: Dictionary = Moon.defaults()
        moon_progress.defeated = [true,true,true]
        moon_progress.page = 30
        test(Moon.finish_chapter(moon_progress),"finish isolated Moon fixture")
        check_chapter_visibility(controller,chronicles,true,true)
        controller.call("show_ascend_home")
        var home: Node = controller.get("active_realm_dialog")
        test(home!=null and home.find_child("AscendHomeCubePreview",true,false)!=null,"4x4 home has an independent cube preview")
        test(home!=null and home.find_child("AscendHomeCampaign",true,false)!=null,"4x4 home exposes Continue Campaign")
        test(home!=null and home.find_child("AscendSettingsEntry",true,false)!=null,"4x4 home exposes Settings")
        chronicles.call("open_library")
        test(chronicles.get("_screen_name")=="library","Zen Realm Chronicles is the sole story entry")
        var screen: Node = chronicles.get("_screen")
        test(is_instance_valid(screen) and screen.find_child("ZenChroniclesRoot",true,false)==null,
            "central Chronicles opens independently of the 4x4 Realms UI")
        chronicles.call("close_chronicles")
        test(FileAccess.get_file_as_string(SaveManager.PATH)==ordinary_save,
            "Chronicles navigation never changes existing Realm stats or progress")
        current_scene = previous_scene
        controller.queue_free()
    ProjectSettings.set_setting("application/config/realm_chronicles_qa",old_qa)
    dark_kuze_gate.restore()
    if existed:
        var f := FileAccess.open(path,FileAccess.WRITE)
        f.store_buffer(save_backup)
        f.close()
    elif FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    for chapter_path in chapter_backups:
        if chapter_backups[chapter_path]!=null:
            var chapter_file := FileAccess.open(str(chapter_path),FileAccess.WRITE)
            chapter_file.store_buffer(chapter_backups[chapter_path])
            chapter_file.close()
        elif FileAccess.file_exists(str(chapter_path)):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(str(chapter_path)))
    print("Realm chapters 3+4 overview QA: ",errors," failure(s)")
    quit(1 if errors>0 else 0)
