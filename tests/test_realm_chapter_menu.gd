extends SceneTree
# Smoke-test the real Zen Chronicles chapter overview and isolated QA buttons
# for the two new Realms. Does not start a new release or change game stats.
const Story = preload("res://story/ZenRealmChronicles.gd")
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

func run() -> void:
    var path: String = SaveManager.PATH
    existed = FileAccess.file_exists(path)
    if existed: save_backup = FileAccess.get_file_as_bytes(path)
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
    # Real 4x4 menu integration: the campaign must be the FIRST card, in the
    # existing Realm list, not merely in the Chronicles library overlay.
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
            var card: Node = modal.find_child("RealmChroniclesCampaignCard",true,false)
            var open_button: Node = modal.find_child("RealmChroniclesCampaignOpen",true,false)
            var visual_previews: Node = modal.find_child("RealmChroniclesFourRealmPreviews",true,false)
            test(card != null,"separate story campaign card is visible in Realm menu")
            test(open_button is Button,"story campaign has a real button")
            test(visual_previews != null and visual_previews.get_child_count()==4,
                "campaign card shows all four realm preview pictures")
            if card != null:
                var direct_cards: Array = []
                for item in card.get_parent().get_children():
                    if item is PanelContainer:
                        direct_cards.append(item)
                test(direct_cards.size()==5 and direct_cards[0]==card,
                    "story campaign appears above Shadow, Ember, Celestial and Satori")
            if open_button is Button:
                (open_button as Button).emit_signal("pressed")
                test(chronicles.get("_screen_name")=="realm-story",
                    "Realm-menu campaign button actually opens Zen Chronicles story overview")
                test(bool(chronicles.get("_realm_story_from_realms")),
                    "story overview remembers that user entered through Realm menu")
                chronicles.call("_back_from_realm_story")
                await process_frame
                test(chronicles.get("_screen")==null,
                    "back from story returns to 4x4 UI instead of the global library")
                var restored: Node = controller.get("active_realm_dialog")
                test(is_instance_valid(restored) and restored.find_child("RealmChroniclesCampaignCard",true,false)!=null,
                    "back from story reopens the existing Realm menu")
        test(FileAccess.get_file_as_string(SaveManager.PATH)==ordinary_save,
            "opening story card and returning never changes normal player saves")
        current_scene = previous_scene
        controller.queue_free()
    ProjectSettings.set_setting("application/config/realm_chronicles_qa",old_qa)
    if existed:
        var f := FileAccess.open(path,FileAccess.WRITE)
        f.store_buffer(save_backup)
        f.close()
    elif FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("Realm chapters 3+4 overview QA: ",errors," failure(s)")
    quit(1 if errors>0 else 0)
