extends SceneTree
# Smoke test for the isolated playable Zen Chronicles campaign.
func _initialize() -> void:
    call_deferred("verify")

func verify() -> void:
    var campaign_script: Script = load("res://story/ZenCampaign.gd") as Script
    if campaign_script == null or campaign_script.reload() != OK:
        printerr("Zen Campaign script failed to compile")
        quit(1)
        return
    var scene: PackedScene = load("res://Main.tscn") as PackedScene
    if scene == null:
        printerr("Zen Campaign main scene missing")
        quit(1)
        return
    var main: Node = scene.instantiate()
    root.add_child(main)
    await process_frame
    if not main.has_method("start_zen_campaign"):
        printerr("Zen Campaign entry point missing")
        quit(1)
        return
    main.call("start_zen_campaign")
    if not bool(main.get("zen_campaign_active")):
        printerr("Zen Campaign did not become active")
        quit(1)
        return
    var previous_progress: Dictionary = campaign_script.load_progress()
    var empty_cells: Array = []
    empty_cells.resize(54)
    empty_cells.fill(0)
    var first_move: int = campaign_script.pick_move(empty_cells, 0, 42)
    var second_move: int = campaign_script.pick_move(empty_cells, 1, 43)
    if first_move < 0 or first_move >= 54 or second_move < 0 or second_move >= 54:
        printerr("Zen Campaign demon AI proposed an illegal opening")
        quit(1)
        return
    var original_world: int = int(main.get("zen_campaign_classic_world"))
    main.call("_zen_campaign_leave")
    if bool(main.get("zen_campaign_active")) or int(main.data.ascension.world) != original_world:
        printerr("Zen Campaign failed to restore Classic world")
        quit(1)
        return
    campaign_script.save_progress(int(previous_progress.get("stage", 0)), previous_progress.get("game", {}))
    print("PASS: 3D campaign entry, demon AI, isolated save, world restored")
    quit(0)
