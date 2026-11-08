extends SceneTree
var failures: int = 0
func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        printerr("LOCALIZATION FAIL: " + message)
func find_button(node: Node, caption: String) -> Button:
    if node is Button and node.text == caption:
        return node
    for child in node.get_children():
        var found_btn = find_button(child, caption)
        if found_btn != null:
            return found_btn
    return null
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var scene = load("res://Main.tscn") as PackedScene
    check(scene != null, "main scene exists")
    if scene == null:
        quit(1)
        return
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    var moves = game.board.move_count()
    game.choose_language("en")
    check(game.language_code() == "en", "English selection persists")
    check(game.T("Neue Partie") == "New match", "English translation available")
    game.open_menu()
    check(find_button(game.popup, "Play vs Bot") != null, "English bot menu")
    game.open_settings()
    check(find_button(game.popup, "Play music sample") != null, "English music preview")
    check(game.music_player != null and game.music_player.stream != null, "music asset loads")
    game.music_preview()
    # Headless runs have no physical speaker. Check the player and stream instead.
    check(game.music_player.volume_db >= -15, "music volume is not near silent")
    check(game.board.move_count() == moves, "switching language preserves board")
    game.choose_language("de")
    check(game.T("Neue Partie") == "Neue Partie", "German language restored")
    game.open_menu()
    check(find_button(game.popup, "Gegen Bot spielen") != null, "German bot menu")
    game.music_player.stop()
    game.queue_free()
    await process_frame
    print("Localization and audio scene smoke test failures: ", failures)
    quit(0 if failures == 0 else 1)
