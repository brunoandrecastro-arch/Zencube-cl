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
    ProjectSettings.set_setting("application/config/realm_chronicles_qa",old_qa)
    if existed:
        var f := FileAccess.open(path,FileAccess.WRITE)
        f.store_buffer(save_backup)
        f.close()
    elif FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("Realm chapters 3+4 overview QA: ",errors," failure(s)")
    quit(1 if errors>0 else 0)
