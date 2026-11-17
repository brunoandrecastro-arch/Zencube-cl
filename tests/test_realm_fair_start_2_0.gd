extends SceneTree
# Alternating opening moves must be fair, including 4x4 Realm Challenges
# and story boss retries. Existing saves and ranks are restored afterwards.
const Story = preload("res://story/ZenRealmChronicles.gd")
var failures: int = 0

func check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        printerr("REALM START FAIRNESS FAIL: ",reason)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var save_path: String = SaveManager.PATH
    var story_path: String = Story.SAVE
    var existed: bool = FileAccess.file_exists(save_path)
    var existed_story: bool = FileAccess.file_exists(story_path)
    var old: PackedByteArray = FileAccess.get_file_as_bytes(save_path) if existed else PackedByteArray()
    var old_story: PackedByteArray = FileAccess.get_file_as_bytes(story_path) if existed_story else PackedByteArray()
    var data: Dictionary = SaveManager.defaults()
    data.ascension.rank = 3
    data.ascension.completed = [true,true,true,false,false]
    data.ascend.help_seen = true
    data.settings.language = "en"
    check(SaveManager.save_data(data),"save temporary test data")
    var scene: PackedScene = load("res://Ascend.tscn") as PackedScene
    check(scene != null,"4x4 scene exists")
    if scene == null:
        quit(1)
        return
    var game: Node = scene.instantiate()
    root.add_child(game)
    await process_frame
    var active: Dictionary = game.get("data")
    active.ascend.next_start = 0
    game.call("start_game",true)
    check(int(game.get("turn")) == 1,"ordinary Realm bot match begins with player")
    check(not bool(game.get("busy")),"player start is immediately ready")
    active.ascend.next_start = 1
    game.call("start_game",true)
    check(int(game.get("turn")) == 2,"second ordinary Realm bot match begins with O")
    check(bool(game.get("busy")),"bot is scheduled instead of accepting a player's mark")
    check((game.get("cells") as Array).count(0) == 96,"bot first does not prefill board")

    var progress: Dictionary = Story.defaults()
    check(int(progress.retry_offset) == 0,"old campaigns default to fair first attempt")
    game.set("realm_story_active",true)
    game.set("realm_story_progress",progress)
    for stage in range(12):
        game.call("_realm_story_set_stage",stage)
        check(int(game.get("turn")) == (1 if stage % 2 == 0 else 2),
            "story boss %d alternates its opening move" % stage)
    progress.retry_offset = 1
    game.set("realm_story_progress",progress)
    for stage in [0,1,2,5,8,11]:
        game.call("_realm_story_set_stage",stage)
        check(int(game.get("turn")) == (2 if stage % 2 == 0 else 1),
            "retry reverses boss %d starter" % stage)
    check(Story.save_progress(progress),"persist retry starter")
    check(int(Story.load_progress().retry_offset) == 1,"retry starter survives a relaunch")

    # Old JSON saves lacking retry_offset still open with the original side.
    var compatible: Dictionary = Story.defaults()
    compatible.erase("retry_offset")
    check(Story.save_progress(compatible),"write old-style progress data")
    check(int(Story.load_progress().retry_offset) == 0,"legacy progress loads without migration")
    game.queue_free()
    await process_frame

    for path in [save_path,story_path]:
        var old_exists: bool = existed if path == save_path else existed_story
        var backup: PackedByteArray = old if path == save_path else old_story
        if old_exists:
            var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
            if file != null:
                file.store_buffer(backup)
                file.close()
        elif FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("REALM START FAIRNESS FAILURES=",failures)
    quit(0 if failures == 0 else 1)
