extends SceneTree

const Campaign = preload("res://story/ZenCampaign.gd")

var failures := 0
var scene: PackedScene
var game: Node
var reader: Node
var fixture_save: Dictionary = {}

func _initialize() -> void:
    call_deferred("_verify")

func _check(passed: bool, message: String) -> void:
    if not passed:
        failures += 1
        printerr("FAIL: " + message)

func _verify() -> void:
    root.size = Vector2i(480, 900)
    for path in [SaveManager.PATH, Campaign.SAVE_FILE]:
        if FileAccess.file_exists(path):
            fixture_save[path] = FileAccess.get_file_as_bytes(path)
            DirAccess.remove_absolute(path)
    _verify_save_migration()
    var classic := SaveManager.defaults()
    classic.settings.merge({"language": "de", "intro_seen": true, "mode": 0, "music": false}, true)
    classic.stats.played = 18
    classic.stats.p1 = 7
    classic.ascension.completed[0] = true
    classic.ascension.world = 1
    classic.economy.merge({"leaves": 124, "owned": [0, 1], "equipped": 1, "migrated": true}, true)
    classic.ascend = {"unlocked": true, "realm": 1}
    _check(SaveManager.save_data(classic), "seed Classic account")
    scene = load("res://Main.tscn")
    reader = root.get_node("ZenChronicles")
    await _load_main()
    game.close_modal()
    game.on_cell(29)
    var classic_board: Dictionary = game.board.snapshot()
    var on_disk := FileAccess.get_file_as_string(SaveManager.PATH)

    game.open_menu()
    _press(game.popup, game.T("Zen Realm Chronicles 📖"))
    _press(reader._screen, "📚 Original Zen Webcomic")
    var read: Button = _button(reader._screen, "Lesen  ›")
    _check(read != null and not read.disabled, "webcomic has its original unlocked chapter")
    reader.open_chapter(0)
    _check(reader._page_image.texture != null and reader._page_counter.text == "1 / 4", "original comic has working pages")
    reader.open_library()
    _press(reader._screen, "📖 Original Zen Campaign · 3×3")
    await process_frame
    _check(bool(reader.is_open()), "campaign overview is reachable")
    _check(_art_count(reader._screen) == 6, "complete hero art and five thumbnail textures are bound to controls")
    var full_hero: TextureRect = reader._screen.find_child("zen_campaign_prologue", true, false) as TextureRect
    _check(full_hero != null and full_hero.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED,
        "campaign header displays complete hero illustration without cropped head")
    _check(str(ProjectSettings.get_setting("display/window/stretch/aspect", "")) == "expand",
        "Godot stretches into tall Android screens without black letterbox bands")
    root.size = Vector2i(480, 1060)
    await process_frame
    _check(reader._screen.size.y >= 1030.0,
        "campaign overview uses the extra height of a tall Android display")
    root.size = Vector2i(480, 900)
    await process_frame
    _press(reader._screen, Campaign.text_for("de", "start_campaign"))
    _check(bool(game.zen_campaign_active), "launch through the Chronicles and campaign overview")
    _check(game.board.cells.size() == 54 and game.rules.lines.size() == 108, "actual cube rules and board")
    _check(_art_count(game.popup) == 1, "prologue illustration is visible")
    _press(game.popup, Campaign.text_for("de", "continue"))
    _check(_art_count(game.popup) == 1, "first demon illustration is visible")
    _press(game.popup, Campaign.text_for("de", "begin"))
    game.on_cell(4)
    _press(game.popup, Campaign.text_for("de", "continue"))
    game.zen_campaign_bot_ready = 0
    await _wait_for_bot()
    _check(game.board.move_count() == 2 and game.board.cells.count(2) == 1, "The Startle responds through the real AI worker")
    var campaign_board: Dictionary = game.board.snapshot()
    var saved_history: Array = Campaign.load_progress().game.history
    _check(saved_history.size() == 2, "both campaign moves written to disk")
    _check(FileAccess.get_file_as_string(SaveManager.PATH) == on_disk, "Classic save untouched during play")

    await _load_main()
    _check(game.board.snapshot() == classic_board, "new session loads the running Classic match")
    var classic_data: Dictionary = game.data.duplicate(true)
    var restored_on_disk := FileAccess.get_file_as_string(SaveManager.PATH)
    game.start_zen_campaign()
    _check(game.board.snapshot() == campaign_board, "new session can resume the exact campaign board")
    _press(game.popup, Campaign.text_for("de", "resume"))
    game._zen_campaign_leave()
    _check(game.board.snapshot() == classic_board and game.data == classic_data, "return restores Classic board, shop, ranks and Realm data")

    _verify_ai()
    game.set_process(false)
    _verify_results()
    _verify_chapters_2_3()
    _verify_chapters_4_5()
    _verify_route()
    _check(FileAccess.get_file_as_string(SaveManager.PATH) == restored_on_disk, "all campaign branches leave the Classic save untouched")
    _verify_languages()

    reader.close_chronicles()
    game.queue_free()
    await process_frame
    for path in [SaveManager.PATH, Campaign.SAVE_FILE]:
        if fixture_save.has(path):
            FileAccess.open(path, FileAccess.WRITE).store_buffer(fixture_save[path])
        elif FileAccess.file_exists(path):
            DirAccess.remove_absolute(path)
    print("Campaign verification: %d failure(s)" % failures)
    quit(0 if failures == 0 else 1)

func _verify_save_migration() -> void:
    var legacy := {"version": 1, "stage": 2, "game": BoardModel.new().snapshot()}
    FileAccess.open(Campaign.SAVE_FILE, FileAccess.WRITE).store_string(JSON.stringify(legacy))
    var moved := Campaign.load_progress()
    _check(moved.stage == 2 and moved.game.is_empty(), "finished Chapter 1 draft migrates to Bamboo Forest")
    var started := BoardModel.new()
    started.swap_enabled = false
    started.cells[4] = 1
    started.turn = 2
    var later := {"version": 2, "stage": Campaign.SELF, "night_result": "draw", "game": started.snapshot()}
    FileAccess.open(Campaign.SAVE_FILE, FileAccess.WRITE).store_string(JSON.stringify(later))
    moved = Campaign.load_progress()
    _check(moved.night == "red" and moved.game.cells[4] == 1 and moved.game.owners == [0, 1],
        "prior campaign save retains the Night branch and active board ownership")
    DirAccess.remove_absolute(Campaign.SAVE_FILE)

func _load_main() -> void:
    reader.close_chronicles()
    if is_instance_valid(game):
        game.queue_free()
        await process_frame
    game = scene.instantiate()
    root.add_child(game)
    current_scene = game
    await process_frame

func _button(node: Node, text: String) -> Button:
    if node == null:
        return null
    if node is Button and node.text == text and node.visible:
        return node
    for child in node.get_children():
        var found := _button(child, text)
        if found != null:
            return found
    return null

func _press(node: Node, text: String) -> void:
    var button := _button(node, text)
    _check(button != null and not button.disabled, "visible enabled button: " + text)
    if button != null and not button.disabled:
        button.pressed.emit()

func _art_count(node: Node) -> int:
    if node == null:
        return 0
    var total := int(node is TextureRect and node.texture != null)
    for child in node.get_children():
        total += _art_count(child)
    return total

func _wait_for_bot() -> void:
    var deadline := Time.get_ticks_msec() + 2500
    while game.board.move_count() == 1 and Time.get_ticks_msec() < deadline:
        await process_frame

func _verify_ai() -> void:
    var board := BoardModel.new()
    var line: Array = game.rules.lines[22]
    for c in line.slice(0, 3):
        board.cells[c] = 1
    var threats: Array = game.rules.threats(board.cells, 1)
    var weak_blocks := 0
    var startle_choices := {}
    for seed in range(1, 48):
        var weak_move := Campaign.pick_move(board.cells, 1, seed)
        var startle_move := Campaign.pick_move(board.cells, 0, seed)
        weak_blocks += int(threats.has(weak_move))
        startle_choices[startle_move] = true
        _check(threats.has(Campaign.pick_move(board.cells, 2, seed)), "Frozen One reliably blocks a forced threat")
    _check(weak_blocks > 0 and weak_blocks < 24, "Hungry One sometimes overlooks a block")
    _check(startle_choices.size() > 20, "Startle spreads its moves across the cube")
    for stage in range(Campaign.SELF + 1):
        var fresh := BoardModel.new()
        var move := Campaign.pick_move(fresh.cells, stage, 87, {"openings": {"24": 3}})
        _check(move >= 0 and move < 54, "stage %d AI makes legal opening" % stage)
        if stage == Campaign.SELF:
            _check(move == 24, "The Self mirrors the player's most frequent opening")
    var hungry := BoardModel.new()
    for c in line.slice(0, 3):
        hungry.cells[c] = 2
    _check(game.rules.threats(hungry.cells, 2).has(Campaign.pick_move(hungry.cells, 1, 73)), "Hungry One finishes its own line")

func _start_fixture(stage: int, fields: Dictionary = {}) -> void:
    if game.zen_campaign_active:
        game._zen_campaign_leave()
    var progress := Campaign.new_progress()
    progress.stage = stage
    progress.prologue_seen = true
    progress.merge(fields, true)
    _check(Campaign.save_progress(progress), "seed isolated campaign stage")
    game.start_zen_campaign()

func _finish_match(winner: int) -> void:
    game._zen_campaign_begin()
    var owner_mark: int = game.board.owners.find(winner) + 1
    var path: Array = game.rules.lines[9].duplicate()
    var fillers: Array = [49, 45, 53, 47]
    var count := 0
    while game.board.winner == 0 and count < 8:
        var cell: int = path.pop_front() if game.board.turn == owner_mark else fillers.pop_front()
        game.place(cell)
        while game._zen_campaign_has_story_beat():
            game._zen_campaign_story_beat_read()
        count += 1
    _check(game.board.winner == owner_mark and game.board.win_lines.size() >= 1, "real four-in-a-row finish")

func _finish_draw() -> void:
    game._zen_campaign_begin()
    var draw: Array = JSON.parse_string(FileAccess.get_file_as_string("res://reports/draw_fixture.json"))
    for i in range(54):
        for c in range(54):
            if game.board.cells[c] == 0 and int(draw[c]) == game.board.turn:
                game.place(c)
                break
    _check(game.board.winner == 3 and game.board.move_count() == 54, "real full-board draw")

func _verify_results() -> void:
    _start_fixture(1)
    _finish_match(1)
    var loss: Dictionary = Campaign.load_progress()
    game._zen_campaign_advance()
    _check(game.zen_campaign_stage == 1, "defeat cannot advance")
    game._zen_campaign_leave()
    game.start_zen_campaign()
    _check(game.board.winner == int(loss.game.winner), "unacknowledged defeat survives reopening")
    game._zen_campaign_retry()
    _finish_draw()
    game._zen_campaign_advance()
    _check(game.zen_campaign_stage == 1, "draw cannot advance Chapter 1")
    game._zen_campaign_retry()
    _finish_match(0)
    game._zen_campaign_advance()
    _check(game.zen_campaign_stage == 2, "Hungry One victory unlocks Bamboo Forest")

    _start_fixture(Campaign.NIGHT)
    game._zen_campaign_begin()
    game.on_cell(20)
    var before: Dictionary = game.board.snapshot()
    game.undo()
    game.confirm_new()
    _check(game.board.snapshot() == before, "Eleventh Night cannot undo or restart")
    game._zen_campaign_leave()
    game.start_zen_campaign()
    _check(game.board.snapshot() == before, "Eleventh Night resumes the same board")
    _start_fixture(Campaign.NIGHT)
    game._zen_campaign_begin()
    game._zen_campaign_tick(Campaign.NIGHT_SECONDS + 1.0)
    _check(Campaign.load_progress().night == "red", "timer expiry durably resolves the Red Hand")
    game._zen_campaign_retry()
    _check(game.board.winner != 0, "decisive result cannot be replayed")
    game._zen_campaign_leave()
    game.start_zen_campaign()
    _check(_button(game.popup, Campaign.text_for("de", "next_chapter")) != null, "branch story resumes after timeout")
    _press(game.popup, Campaign.text_for("de", "next_chapter"))
    _check(game.zen_campaign_stage == Campaign.LORD and game.board.current_owner() == 1, "Lord opens on the next board")
    _check(Campaign.load_progress().night == "red", "Red Hand survives transition")
    _start_fixture(Campaign.NIGHT)
    _finish_draw()
    _check(Campaign.load_progress().night == "still", "draw resolves the Still Hand per the mechanics outline")

func _verify_chapters_2_3() -> void:
    for stage in [2, 3, 4, 5]:
        var art_path: String = Campaign.encounter_art(stage)
        _check(ResourceLoader.exists(art_path), "chapter 2-3 illustration exists: " + art_path)
        var art: Texture2D = load(art_path) as Texture2D
        _check(art != null and art.get_width() >= 800 and art.get_height() >= 500,
            "chapter 2-3 illustration imports at full resolution: " + art_path)
        _start_fixture(stage)
        _check(game.zen_campaign_stage == stage, "chapter 2-3 boss is accessible in campaign")
        _check(_art_count(game.popup) == 1,
            "chapter 2-3 artwork is shown in real encounter intro: " + art_path)
        if stage == 3:
            _check(not game._zen_campaign_can_undo(), "The Double physically disables undo")
            game._zen_campaign_begin()
            for cell in [0, 18, 1, 27, 2, 36]:
                game.place(cell)
            _check(game.zen_campaign_battle_line == Campaign.text_for("de", "combat_3_question"),
                "The Double asks a contextual question during the real match")
    _start_fixture(3)
    _finish_match(0)
    game._zen_campaign_advance()
    _check(game.zen_campaign_stage == 4 and Campaign.load_progress().pending == "chapter_2_end",
        "Bamboo Forest completion leads to a saved cinematic chapter ending")
    _check(_art_count(game.popup) == 1, "chapter 2 ending has the world illustration")
    game._zen_campaign_leave()
    game.start_zen_campaign()
    _check(_button(game.popup, Campaign.text_for("de", "next_chapter")) != null,
        "chapter 2 ending resumes correctly after relaunch")
    _press(game.popup, Campaign.text_for("de", "next_chapter"))
    _check(Campaign.load_progress().pending == "" and game.zen_campaign_stage == 4,
        "chapter 3 begins only after confirming Bamboo finale")
    _start_fixture(5)
    _finish_match(0)
    game._zen_campaign_advance()
    _check(game.zen_campaign_stage == Campaign.NIGHT and Campaign.load_progress().pending == "chapter_3_end",
        "Temple completion saves the story ending before the Eleventh Night")
    _check(_art_count(game.popup) == 1, "chapter 3 ending uses temple artwork")
    _press(game.popup, Campaign.text_for("de", "next_chapter"))
    _check(Campaign.load_progress().pending == "" and game.zen_campaign_stage == Campaign.NIGHT,
        "temple finale reveals the one-time Eleventh Night only once")

func _verify_chapters_4_5() -> void:
    for stage in [Campaign.LORD, Campaign.SLAIN, Campaign.DAWN, Campaign.SELF, Campaign.EPILOGUE]:
        var image_path: String = Campaign.encounter_art(stage)
        _check(ResourceLoader.exists(image_path), "chapter 4-5 illustration is bundled: " + image_path)
        var texture: Texture2D = load(image_path) as Texture2D
        _check(texture != null and texture.get_width() >= 800 and texture.get_height() >= 500,
            "chapter 4-5 image imports at full landscape resolution: " + image_path)
        _start_fixture(stage, {"night": "still"})
        _check(game.zen_campaign_stage == stage, "late-game encounter is playable at stage %d" % stage)
        _check(_art_count(game.popup) == 1, "illustrated late-game intro stage %d" % stage)
        if stage == Campaign.SLAIN:
            _check(game.board.cells.size() == 54 and game.rules.lines.size() == 108,
                "The Slain still plays on the authentic 54-cell 108-line cube")
        if stage == Campaign.SELF:
            _check(game.zen_campaign_progress.openings is Dictionary,
                "The Self has persisted player opening preferences")
    # World 4 has two win milestones for the Lord and one for the Slain;
    # its completion interlude survives closing and reopening the game.
    _start_fixture(Campaign.SLAIN, {"night": "still"})
    _finish_match(0)
    game._zen_campaign_advance()
    _check(game.zen_campaign_stage == Campaign.DAWN and Campaign.load_progress().pending == "chapter_4_end",
        "Still Water ending is saved before moving to the summit")
    _check(_art_count(game.popup) == 1, "Still Water ending uses a chapter illustration")
    game._zen_campaign_leave()
    game.start_zen_campaign()
    _check(_button(game.popup, Campaign.text_for("de", "next_chapter")) != null,
        "Still Water ending resumes from its saved checkpoint")
    _press(game.popup, Campaign.text_for("de", "next_chapter"))
    _check(game.zen_campaign_stage == Campaign.DAWN and Campaign.load_progress().pending == "",
        "False Dawn begins only after acknowledging World 4")
    # The Self can be replayed at the final rank; bowing alone completes
    # the campaign and grants no Classic rank or shop currency.
    _start_fixture(Campaign.SELF, {"night": "red", "wins": 4})
    _finish_match(0)
    game._zen_campaign_bow()
    _check(Campaign.load_progress().pending == "chapter_5_end"
        and Campaign.load_progress().stage == Campaign.EPILOGUE,
        "Bow saves World 5's true ending and unlocks the island")
    _check(_art_count(game.popup) == 1, "summit ending has atmospheric chapter artwork")
    game._zen_campaign_leave()
    game.start_zen_campaign()
    _press(game.popup, Campaign.text_for("de", "next_chapter"))
    _check(Campaign.load_progress().pending == "epilogue",
        "chapter 5 completion flows into island epilogue")
    _check(_art_count(game.popup) == 1, "island epilogue has its own illustration")
    _press(game.popup, Campaign.text_for("de", "continue"))
    _press(game.popup, Campaign.text_for("de", "begin"))
    game.on_cell(3)
    game.on_cell(4)
    _check(game.board.cells[3] == 1 and game.board.cells[4] == 2,
        "island conclusion is played by two local people, never against an AI")

func _verify_route() -> void:
    _start_fixture(0)
    for stage in range(Campaign.SELF + 1):
        _check(game.zen_campaign_stage == stage, "linear campaign stage %d" % stage)
        if stage == Campaign.NIGHT:
            _finish_match(0)
            _check(Campaign.load_progress().night == "still", "win resolves the Still Hand")
            _press(game.popup, Campaign.text_for("de", "next_chapter"))
            continue
        for _round in range(Campaign.WINS_FOR_STAGE[stage]):
            _finish_match(0)
            if stage == Campaign.SELF and _round == Campaign.WINS_FOR_STAGE[stage] - 1:
                _press(game.popup, Campaign.text_for("de", "bow"))
            else:
                game._zen_campaign_advance()
        if stage in [3, 5, Campaign.SLAIN]:
            var end_scene := "chapter_2_end" if stage == 3 else ("chapter_3_end" if stage == 5 else "chapter_4_end")
            _check(Campaign.load_progress().pending == end_scene,
                "chapter finale is a persistent scene before moving forward")
            game._zen_campaign_leave()
            game.start_zen_campaign()
            _press(game.popup, Campaign.text_for("de", "next_chapter"))
            _check(Campaign.load_progress().pending == "", "chapter finale acknowledged")
        if stage == Campaign.DAWN:
            _check(Campaign.load_progress().pending == "false_ending", "false ending saved before the summit continues")
            game._zen_campaign_leave()
            game.start_zen_campaign()
            _press(game.popup, Campaign.text_for("de", "sit_again"))
            _press(game.popup, Campaign.text_for("de", "continue"))
    _check(Campaign.load_progress().complete, "bow completes all five worlds")
    _check(Campaign.load_progress().pending == "chapter_5_end", "true ending is saved after bow")
    _press(game.popup, Campaign.text_for("de", "next_chapter"))
    _check(Campaign.load_progress().pending == "epilogue", "island interlude follows the true ending")
    _press(game.popup, Campaign.text_for("de", "continue"))
    _press(game.popup, Campaign.text_for("de", "begin"))
    game.on_cell(1)
    game.on_cell(2)
    _check(game.board.cells[1] == 1 and game.board.cells[2] == 2 and not game._zen_campaign_bot_turn(), "epilogue uses local two-player turns")
    game._zen_campaign_leave()

func _verify_languages() -> void:
    var bundle: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Campaign.TEXT_FILE))
    for language in ["de", "en", "pt"]:
        _check(bundle[language].size() == bundle.en.size(), language + ": full key set")
        for key in bundle.en:
            _check(not str(bundle[language].get(key, "")).strip_edges().is_empty(), language + ": translated " + key)
        # Change the selected locale as the main settings menu would do.
        game.choose_language(language)
        reader.open_library()
        _check(_button(reader._screen, Campaign.text_for(language, "play")) != null, "hub follows selected language " + language)
        reader.open_campaign_overview()
        _check(_button(reader._screen, Campaign.text_for(language, "open_epilogue")) != null, "overview follows selected language " + language)
        game.start_zen_campaign()
        _check(_button(game.popup, Campaign.text_for(language, "resume")) != null, "match popup follows selected language " + language)
        game._zen_campaign_leave()
    game.choose_language("de")
