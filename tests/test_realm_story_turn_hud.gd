extends SceneTree
# The 4x4 boss HUD must identify the current turn and count X+O once.
# Read-only presentation regression; restores player save after the test.
const Story = preload("res://story/ZenRealmChronicles.gd")
var failures: int = 0

func check(ok: bool, info: String) -> void:
    if not ok:
        failures += 1
        printerr("STORY TURN HUD FAIL: ",info)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var save: String = SaveManager.PATH
    var had_save: bool = FileAccess.file_exists(save)
    var backup: PackedByteArray = FileAccess.get_file_as_bytes(save) if had_save else PackedByteArray()
    var data: Dictionary = SaveManager.defaults()
    data.ascension.rank = 3
    data.ascension.completed = [true,true,true,false,false]
    data.ascend.help_seen = true
    data.settings.language = "en"
    check(SaveManager.save_data(data),"seed permitted UI-test save")

    var scene: PackedScene = load("res://Ascend.tscn") as PackedScene
    check(scene != null,"Ascend scene exists")
    if scene == null:
        quit(1)
        return
    var game: Node = scene.instantiate()
    root.add_child(game)
    await process_frame
    game.set("realm_story_active",true)
    game.set("realm_story_stage",8) # Archivist of the Sky
    game.set("against_bot",true)
    game.set("owners",[0,1])
    game.set("busy",false)
    game.set("result",0)
    game.set("turn",1)
    var marks: Array = []
    marks.resize(96)
    marks.fill(0)
    for i in range(6):
        marks[i] = 1
        marks[16+i] = 2
    game.set("cells",marks)
    game.call("draw")
    var status: Label = game.get("status_label") as Label
    var details: Label = game.get("details_label") as Label
    var rank: Label = game.get("rank_label") as Label
    check(status != null and details != null and rank != null,"HUD labels exist")
    if status != null and details != null:
        check(status.text == "Your turn · X","human turn is clearly identified")
        check(details.text == "Total moves: 12/96 · X: 6 · O: 6","twelve occupied cells are counted once")
        check((status.text+details.text).count("12/96") == 1,"12/96 appears exactly once across both rows")
        check(not details.text.contains("Boss skin active"),"duplicate technical skin message hidden")
    if rank != null:
        check(rank.text == Story.text_for("en","boss_8"),"boss name remains in heading")

    game.set("turn",2)
    game.set("busy",true)
    game.call("draw")
    if status != null: check(status.text.contains("Archivist of the Sky") and status.text.contains("thinking"),"actual boss name displayed while calculating")
    game.set("busy",false)
    game.call("draw")
    if status != null: check(status.text.contains("Archivist of the Sky") and status.text.contains("turn"),"bot turn displayed when no longer busy")

    # The display must reflect actual placements, not a tap count or draw calls.
    marks[50] = 1
    game.set("cells",marks)
    game.call("draw")
    if details != null: check(details.text == "Total moves: 13/96 · X: 7 · O: 6","one new X increments exactly once")
    game.call("draw")
    if details != null: check(details.text == "Total moves: 13/96 · X: 7 · O: 6","redraw alone does not increment counter")
    marks[60] = 2
    game.set("cells",marks)
    game.call("draw")
    if details != null: check(details.text == "Total moves: 14/96 · X: 7 · O: 7","one boss O also increments once")

    for lang in ["de","pt"]:
        (game.get("data") as Dictionary).settings.language = lang
        game.set("turn",1)
        game.call("draw")
        if status != null:
            check(status.text.contains("Du bist dran" if lang == "de" else "É a tua vez"),"localized human turn " + lang)
        if details != null:
            check(details.text.contains("Züge gesamt" if lang == "de" else "Jogadas no total"),"localized total moves " + lang)
            check(details.text.contains("14/96"),"localized number unchanged " + lang)

    game.set("result",2)
    game.call("draw")
    if status != null: check(status.text == Story.text_for("pt","loss"),"post-match boss result is not overwritten")
    if details != null: check(details.text.contains("14/96"),"final occupied count stays visible")
    check((game.get("cells") as Array) == marks,"HUD presentation never edits game state")
    game.queue_free()
    await process_frame

    if had_save:
        var out: FileAccess = FileAccess.open(save,FileAccess.WRITE)
        if out != null:
            out.store_buffer(backup)
            out.close()
    elif FileAccess.file_exists(save):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(save))
    print("STORY TURN HUD FAILURES=",failures)
    quit(0 if failures == 0 else 1)
