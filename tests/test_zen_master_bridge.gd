extends SceneTree
# Headless real-scene smoke test of the Satori victory -> mirror break flow.
var failures: int = 0
func check(ok: bool, description: String) -> void:
    if not ok:
        failures += 1
        printerr("ZEN MASTER BRIDGE FAIL: " + description)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var scene: PackedScene = load("res://ZenMasterBridgeTest.tscn") as PackedScene
    check(scene != null, "standalone Satori bridge scene loads")
    if scene != null:
        var game: Node = scene.instantiate()
        root.add_child(game)
        await process_frame
        var cells: Array = game.get("cells") as Array
        check(cells.size() == 96, "real 4x4 has 96 cells")
        check(cells.slice(0,4) == [1,1,1,0], "three X and one empty cell guarantee simple win")
        check(int(cells[70]) == 2, "easy bot begins in unrelated distant position")
        check(not bool(game.get("transition_started")), "fracture not active before victory")
        check((game.get("tiles") as Array).size() == 96, "real Satori board has 96 3D tiles")
        game.call("_on_tap",3)
        check(bool(game.get("transition_started")), "real 4x4 win starts fracture")
        var shatter: Node = game.get("mirror")
        check(shatter != null, "mirror animation exists")
        if shatter != null:
            check(bool(shatter.get("running")), "mirror animation is actually playing")
        game.queue_free()
        await process_frame
    check(ZenAscend.generate_lines().size() == 204, "normal 4x4 line count unchanged")
    check(ZenMaster.generate_lines().size() == 312, "normal 5x5 line count unchanged")
    print("ZEN MASTER BRIDGE FAILURES=",failures)
    quit(0 if failures == 0 else 1)
