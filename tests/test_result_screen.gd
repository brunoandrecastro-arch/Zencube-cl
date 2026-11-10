extends SceneTree
# Headless regression for the real win/result UI, no modification to the game rules.
var failures: int = 0
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        printerr("RESULT UI FAIL: " + message)
func find_button(node: Node, text: String) -> Button:
    if node is Button and node.text == text:
        return node
    for child in node.get_children():
        var match_button: Button = find_button(child, text)
        if match_button != null:
            return match_button
    return null
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var packed = load("res://Main.tscn") as PackedScene
    check(packed != null, "main scene")
    if packed == null:
        quit(1)
        return
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame
    game.data.settings.swap = false
    game.start_mode(0)
    var winning: Array = game.rules.lines[0]
    var filler: Array = []
    for i in range(54):
        if not winning.has(i):
            filler.append(i)
    for i in range(4):
        game.place(int(winning[i]))
        if i < 3:
            game.place(int(filler[i]))
    check(game.board.winner == 1, "X wins with a legitimate cross-edge line")
    await process_frame
    check(game.popup != null, "result modal opens after match")
    if game.popup != null:
        check(find_button(game.popup, game.T("Noch eine Partie")) != null, "replay button")
        check(find_button(game.popup, game.T("Hauptmenü")) != null, "main menu button")
    game.play_again_after_result()
    check(game.board.winner == 0 and game.board.move_count() == 0, "replay resets board")
    check(game.popup == null, "result modal closes on replay")
    game.open_menu()
    check(game.popup != null, "main menu opens")
    if game.popup != null:
        check(find_button(game.popup, game.T("Spielen")) != null, "play entry")
    game.open_play_menu()
    check(find_button(game.popup, game.T("Zen-Bot · Leicht")) != null, "easy bot")
    check(find_button(game.popup, game.T("Zen-Bot · Mittel")) != null, "medium bot")
    check(find_button(game.popup, game.T("Zen-Bot · Schwer")) != null, "hard bot")
    game.close_modal()
    game.queue_free()
    await process_frame
    print("ZEN 9.3 RESULT SCREEN FAILURES=", failures)
    quit(0 if failures == 0 else 1)
