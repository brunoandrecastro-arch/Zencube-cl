extends SceneTree
# Representative Alpha 2.3 VERSION=3 data through a real updated Main scene.
# The Android in-place update still needs device verification with Play signing.
const Story = preload("res://story/ZenRealmChronicles.gd")
const Campaign = preload("res://story/ZenCampaign.gd")
var failures: int = 0
var backups: Dictionary = {}
var paths: Array = [SaveManager.PATH, ZenChallenges.PROGRESS_PATH, Story.SAVE, Campaign.SAVE_FILE]

func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        printerr("PLAY SAVE COMPATIBILITY FAIL: ", message)

func write_json(path: String, value: Dictionary) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(JSON.stringify(value))
    file.close()

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    for path in paths:
        if FileAccess.file_exists(path): backups[path] = FileAccess.get_file_as_bytes(path)
    var old: Dictionary = SaveManager.defaults()
    old.version = 3
    old.settings.merge({"language":"pt", "intro_seen":true, "tutorial_seen":true,
        "names":["Bruno","Lumi"], "mode":0, "music_mode":"manual", "music_track":8,
        "sound":false, "haptics":false, "alternate":true, "next_start":1}, true)
    old.stats.merge({"played":51, "p1":28, "p2":20, "draw":3,
        "ai_wins":[8,7,9,0,0], "ai_losses":[2,3,4,0,0]}, true)
    old.ascension.merge({"completed":[true,true,true,false,false], "rank":3, "world":2}, true)
    old.economy.merge({"leaves":1234, "owned":[0,2,7], "equipped":7,
        "owned_music":[5,8], "ascend_owned":true, "migrated":true}, true)
    var board := BoardModel.new()
    board.cells[0] = 1
    board.cells[8] = 2
    board.cells[20] = 1
    board.turn = 2
    board.last_cell = 20
    board.swap_enabled = false
    old.game = board.snapshot()
    var progress: Dictionary = {"1":true,"22":true,"43":true}
    write_json(ZenChallenges.PROGRESS_PATH, progress)
    var challenge_bytes := FileAccess.get_file_as_bytes(ZenChallenges.PROGRESS_PATH)
    write_json(SaveManager.PATH, old)
    for path in [Story.SAVE, Campaign.SAVE_FILE]:
        if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    var scene := load("res://Main.tscn") as PackedScene
    var main: Node = scene.instantiate()
    root.add_child(main)
    await process_frame
    var updated: Dictionary = main.get("data")
    check(int(updated.version) == 3, "classic save schema stays version 3")
    check(int(updated.economy.leaves) == 1234, "wallet is neither reset nor credited twice")
    check(int(updated.economy.equipped) == 7 and updated.economy.owned.size() == 3,
        "owned skins and equipped skin retained")
    check(ZenCollection.music_unlocked(updated,8) and updated.settings.music_track == 8,
        "purchased music and manual selection retained")
    check(updated.settings.language == "pt" and updated.settings.names == ["Bruno","Lumi"],
        "language and both player names retained")
    check(not bool(updated.settings.sound) and not bool(updated.settings.haptics),
        "audio and vibration preferences retained")
    check(int(updated.stats.played) == 51 and int(updated.stats.p1) == 28 and int(updated.stats.draw) == 3,
        "historical statistics retained")
    check(int(updated.ascension.rank) == 3 and int(updated.ascension.world) == 2,
        "earned Zen Master and selected world retained")
    check(ZenAscend.unlocked(updated), "existing 4x4 entitlement retained")
    var restored: BoardModel = main.get("board")
    check(restored.cells == board.cells and restored.turn == 2 and restored.last_cell == 20,
        "existing 54-cell board and current player restored")
    var puzzles: ZenChallenges = main.get("challenges")
    check(puzzles.solved.size() == 3, "Classic challenge achievements retained")
    main.call("persist")
    var again: Dictionary = SaveManager.load_data()
    check(int(again.economy.leaves) == 1234 and SaveManager.valid_game(again.game),
        "updated save remains loadable without losing wallet or board")
    check(FileAccess.get_file_as_bytes(ZenChallenges.PROGRESS_PATH) == challenge_bytes,
        "opening and saving Classic never rewrites challenge progress")
    check(not FileAccess.file_exists(Story.SAVE) and not FileAccess.file_exists(Campaign.SAVE_FILE),
        "new campaigns do not create or overwrite progress merely on Classic startup")
    main.queue_free()
    await process_frame

    var fresh: Dictionary = SaveManager.defaults()
    check(not ZenAscend.unlocked(fresh) and not ZenAscend.test_access_enabled(),
        "new players receive no QA unlock")
    fresh.economy.ascend_owned = true
    check(ZenAscend.unlocked(fresh), "previous shop entitlement works below Zen Master")
    for path in paths:
        if backups.has(path):
            var file := FileAccess.open(path, FileAccess.WRITE)
            file.store_buffer(backups[path])
            file.close()
        elif FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    if failures == 0:
        print("PASS: Alpha 2.3 VERSION=3 wallet, shop, Classic board, rank, settings and challenges survive actual updated scene startup/save; fresh installs remain locked")
    quit(1 if failures else 0)
