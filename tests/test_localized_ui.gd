extends SceneTree
# Runtime smoke test for all three languages, including Challenges and persistence.
var failures: int = 0
func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        printerr("I18N FAIL: " + message)
func find_button(node: Node, caption: String) -> Button:
    if node is Button and node.text == caption:
        return node
    for child in node.get_children():
        var candidate = find_button(child, caption)
        if candidate != null:
            return candidate
    return null
func find_option(node: Node) -> OptionButton:
    if node is OptionButton:
        return node
    for child in node.get_children():
        var candidate = find_option(child)
        if candidate != null:
            return candidate
    return null
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var packed = load("res://Main.tscn") as PackedScene
    check(packed != null, "Main scene loads")
    if packed == null:
        quit(1)
        return
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame
    var classic_board = game.board.snapshot()
    for lang in ["de","en","pt"]:
        game.choose_language(lang)
        check(game.language_code()==lang, "Language changed to " + lang)
        check(SaveManager.load_data().settings.language==lang, "Language saved for " + lang)
        var new_match = game.T("Neue Partie")
        check(new_match==({"de":"Neue Partie","en":"New match","pt":"Nova partida"})[lang], "New game translation " + lang)
        game.open_menu()
        check(find_button(game.popup, ({"de":"Gegen Bot spielen","en":"Play vs Bot","pt":"Jogar contra o bot"})[lang]) != null, "Main menu localized " + lang)
        game.open_settings()
        check(find_button(game.popup, ({"de":"Musikprobe abspielen","en":"Play music sample","pt":"Ouvir uma amostra da música"})[lang]) != null, "Settings localized " + lang)
        var lang_picker = find_option(game.popup)
        check(lang_picker!=null and lang_picker.item_count==3 and lang_picker.selected==["de","en","pt"].find(lang), "Language picker " + lang)
        check(game.music_player!=null and game.music_player.stream!=null, "Music retained " + lang)
        game.close_modal()
        game.begin_challenges()
        check(game.challenge_active, "Challenges active " + lang)
        check(game.challenge_role_label.text==({"de":"Du spielst X  ·  Zen-Bot spielt O","en":"You play X  ·  Zen-Bot plays O","pt":"Jogas com X  ·  O Zen-Bot joga com O"})[lang], "Player role in " + lang)
        game.notify_user("Nicht ganz – überlege, welche Kantenlinie entscheidend ist.")
        check(game.help_text.text==game.T("Nicht ganz – überlege, welche Kantenlinie entscheidend ist."), "No untranslated toast " + lang)
        check(game.challenges.puzzles.size()==100, "All puzzles present " + lang)
        game.leave_challenges()
    check(game.board.snapshot()==classic_board, "Classic board retained")
    check(game.music_player.stream!=null,"Audio stream retained")
    game.music_player.stop()
    game.queue_free()
    await process_frame
    print("Three-language UI smoke test failures: ", failures)
    quit(0 if failures == 0 else 1)
