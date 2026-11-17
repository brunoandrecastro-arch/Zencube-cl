extends SceneTree
# Completed previous Realm titles remain visible in Statistics & Rank.
# This test restores both save files and never changes actual player data.
const Story = preload("res://story/ZenRealmChronicles.gd")
const Realms = preload("res://core/ZenAscendRealms.gd")
const Achievements = preload("res://core/ZenAscendAchievements.gd")
var failures: int = 0

func check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        printerr("CURRENT TITLE FAIL: ",reason)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var blank: Dictionary = SaveManager.defaults()
    Realms.ensure(blank)
    check(Achievements.latest_main_title(blank) == "—","no prestige title in fresh save")
    for i in range(7):
        Realms.state(blank).completed[str(Realms.TASKS[0][i].id)] = true
    check(Achievements.latest_main_title(blank) == "—","7 Shadow challenges never create title")
    Realms.state(blank).completed[str(Realms.TASKS[0][7].id)] = true
    check(Achievements.latest_main_title(blank) == "Master of Shadows","Shadow title at 8/8")
    for task in Realms.TASKS[1]:
        Realms.state(blank).completed[str(task.id)] = true
    check(Achievements.latest_main_title(blank) == "Ember Master","Ember title at 8/8")
    check(Achievements.main_title(blank,2) == "—","unfinished Celestial has no realm title")
    check(Realms.localized_name(Achievements.latest_main_title(blank),"de") == "Meister der Glut","German title localization")
    check(Realms.localized_name(Achievements.latest_main_title(blank),"pt") == "Mestre das Brasas","Portuguese title localization")

    var main_path: String = SaveManager.PATH
    var story_path: String = Story.SAVE
    var had_main: bool = FileAccess.file_exists(main_path)
    var had_story: bool = FileAccess.file_exists(story_path)
    var main_backup: PackedByteArray = FileAccess.get_file_as_bytes(main_path) if had_main else PackedByteArray()
    var story_backup: PackedByteArray = FileAccess.get_file_as_bytes(story_path) if had_story else PackedByteArray()
    var data: Dictionary = blank
    data.ascension.rank = 3
    data.ascension.completed = [true,true,true,false,false]
    data.ascend.help_seen = true
    data.settings.language = "en"
    Realms.state(data).selected = 2
    var story_progress: Dictionary = Story.defaults()
    story_progress.stage = 6
    check(Story.save_progress(story_progress),"seed completed first six story bosses")
    check(SaveManager.save_data(data),"seed unlocked Celestial player")
    check(Realms.unlocked(data,2),"Celestial is genuinely available")

    var scene: PackedScene = load("res://Ascend.tscn") as PackedScene
    check(scene != null,"Ascend scene available")
    if scene != null:
        var controller: Node = scene.instantiate()
        root.add_child(controller)
        await process_frame
        check(int(controller.get("match_realm")) == 2,"scene restored selected Celestial Realm")
        controller.call("show_statistics")
        var dialog: Node = controller.get("active_realm_dialog")
        var title_label: Label = dialog.find_child("CurrentRealmTitle",true,false) as Label
        check(title_label != null,"statistics render dedicated current title label")
        if title_label != null:
            check(title_label.text.contains("Ember Master"),"stats show most recent earned title, NOT a dash")
        var saved_stats: String = JSON.stringify(controller.get("data"))
        controller.call("show_statistics")
        check(JSON.stringify(controller.get("data")) == saved_stats,"viewing stats never changes progression")
        controller.queue_free()
        await process_frame

    for path in [main_path,story_path]:
        var existed: bool = had_main if path == main_path else had_story
        var old: PackedByteArray = main_backup if path == main_path else story_backup
        if existed:
            var restore: FileAccess = FileAccess.open(path,FileAccess.WRITE)
            if restore != null:
                restore.store_buffer(old)
                restore.close()
        elif FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("CURRENT TITLE FAILURES=",failures)
    quit(1 if failures > 0 else 0)
