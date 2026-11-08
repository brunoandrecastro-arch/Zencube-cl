extends SceneTree
func _initialize() -> void:
    call_deferred("verify")
func verify() -> void:
    var script = load("res://ui/GameController.gd") as Script
    if script == null:
        printerr("FATAL MAIN SCRIPT: Could not load ui/GameController.gd. Inspect parser errors above.")
        quit(1)
        return
    var error = script.reload()
    if error != OK or not script.can_instantiate():
        printerr("FATAL MAIN SCRIPT: compilation failed: ",error_string(error))
        quit(1)
        return
    var scene = load("res://Main.tscn") as PackedScene
    if scene == null:
        printerr("FATAL: Main.tscn missing or invalid")
        quit(1)
        return
    var main = scene.instantiate()
    if main.get_script() == null or not main.has_method("open_welcome"):
        printerr("FATAL: Main.tscn did not attach GameController.gd; root=",main.get_class())
        main.free()
        quit(1)
        return
    print("PASS: Main.tscn attached GameController.gd with open_welcome()")
    main.free()
    quit(0)
