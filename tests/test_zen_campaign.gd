extends SceneTree

const Campaign = preload("res://story/ZenCampaign.gd")
const WIN_LINE := [2, 1, 0, 20]
const OTHER_LINE := [5, 4, 3, 23]

var game: Node
var library: Node
var previous_files: Dictionary = {}
var failures := 0

func _initialize() -> void:
    call_deferred("verify")

func check(ok: bool, message: String) -> void:
    if not ok:
        printerr("FAIL: ", message)
        failures += 1

func verify() -> void:
    library = root.get_node("ZenChronicles")
    for path in [SaveManager.PATH, Campaign.SAVE_FILE]:
        previous_files[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
    if FileAccess.file_exists(Campaign.SAVE_FILE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(Campaign.SAVE_FILE))

    verify_bot_personalities()
    verify_migration()
    await verify_story()
    await verify_night()
    await verify_languages()
    library.call("close_chronicles")
    await close_game()

    for path in previous_files:
        var backup: Variant = previous_files[path]
        if backup == null:
            if FileAccess.file_exists(path):
                DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
        else:
            var file := FileAccess.open(path, FileAccess.WRITE)
            file.store_buffer(backup)
            file.close()
    if failures == 0:
        print("PASS: all five Zen Campaign chapters, eleven encounters, two endings and isolated local epilogue")
    quit(0 if failures == 0 else 1)

func verify_bot_personalities() -> void:
    var board := BoardModel.new()
    var seen := {}
    for seed_value in range(48):
        var move := Campaign.pick_move(board.cells, 0, seed_value)
        check(move in range(54), "The Startle selects a legal opening")
        seen[move] = true
    check(seen.size() > 18, "The Startle varies its opening faces and cells")
    var rules := RulesEngine.new()
    check(rules.lines.size() == 108, "Campaign uses 108 canonical lines")
    check(WIN_LINE in rules.lines, "Campaign accepts a canonical cross-edge line")
    check(OTHER_LINE in rules.lines, "Offence test uses a valid second line")
    # Split three stones across the edge so there is exactly one winning square.
    for cell in [WIN_LINE[0], WIN_LINE[2], WIN_LINE[3]]:
        board.cells[cell] = 1
    var skipped_block := false
    var blocked := false
    for seed_value in range(32):
        if Campaign.pick_move(board.cells, 1, seed_value) == WIN_LINE[1]:
            blocked = true
        else:
            skipped_block = true
        check(Campaign.pick_move(board.cells, 2, seed_value) == WIN_LINE[1], "The Frozen One blocks immediate defeat")
    check(skipped_block and blocked, "The Hungry One only occasionally blocks")
    for cell in [OTHER_LINE[0], OTHER_LINE[2], OTHER_LINE[3]]:
        board.cells[cell] = 2
    check(Campaign.pick_move(board.cells, 1, 3) == OTHER_LINE[1], "The Hungry One takes its own win")
    board = BoardModel.new()
    board.cells[4] = 1
    check(Campaign.pick_move(board.cells, 3, 1, 2, 4) == 13, "The Double echoes the opposite face")
    var openings := Campaign.defaults().openings as Array
    openings[31] = 10
    check(Campaign.pick_move(board.cells, Campaign.SELF, 1, 2, 4, [], openings) == 31, "The Self uses saved opening habits")
    for stage in range(Campaign.EPILOGUE):
        var move := Campaign.pick_move(board.cells, stage, 23, 2, 4, [1, 2], openings)
        check(move in range(54) and move != 4, "Legal move from encounter %d" % stage)

func verify_migration() -> void:
    var old_board := BoardModel.new()
    old_board.swap_enabled = false
    RulesEngine.new().play(old_board, 42)
    if not write_v1(1, old_board.snapshot()):
        check(false, "Can set up v1 in-progress save")
        return
    var migrated := Campaign.load_progress()
    check(migrated.version == Campaign.VERSION and migrated.stage == 1 and int(migrated.game.cells[42]) == 1,
        "v1 match and stage are migrated")
    check(write_v1(2, old_board.snapshot()), "Can set up v1 completed save")
    var finished_chapter := Campaign.load_progress()
    check(finished_chapter.stage == 2 and finished_chapter.prologue_seen and finished_chapter.game.is_empty(),
        "A v1 Chapter 1 completion unlocks Chapter 2")
    check(Campaign.save_progress(Campaign.defaults()), "Reset scratch campaign for story test")

func write_v1(stage: int, snapshot: Dictionary) -> bool:
    var file := FileAccess.open(Campaign.SAVE_FILE, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify({"version": 1, "stage": stage, "game": snapshot}))
    file.close()
    return true

func new_classic(lang: String) -> Dictionary:
    var classic := SaveManager.defaults()
    classic.settings.language = lang
    classic.settings.intro_seen = true
    classic.settings.mode = 0
    classic.settings.music = false
    classic.settings.haptics = false
    classic.stats.played = 14
    classic.economy.leaves = 126
    classic.economy.owned = [0, 1]
    classic.economy.migrated = true
    classic.ascension.rank = 2
    classic.ascension.world = 2
    classic.ascension.completed = [true, true, false, false, false]
    classic.ascend.realm = 1
    var board := BoardModel.new()
    board.swap_enabled = false
    RulesEngine.new().play(board, 27)
    classic.game = board.snapshot()
    classic.game.history = board.history
    return classic

func open_game() -> void:
    game = (load("res://Main.tscn") as PackedScene).instantiate()
    root.add_child(game)
    current_scene = game
    await process_frame
    game.set_process(false)

func close_game() -> void:
    if is_instance_valid(game):
        game.queue_free()
        await process_frame

func verify_story() -> void:
    check(SaveManager.save_data(new_classic("en")), "Create a Classic save with rank, shop and running game")
    await open_game()
    var saved_classic := FileAccess.get_file_as_bytes(SaveManager.PATH)
    var original_board: BoardModel = game.get("board")
    var renderer: CubeRenderer = game.get("renderer")
    renderer.rotate_cube(Vector2(12, -30))
    var original_orientation: Basis = renderer.pivot.basis
    library.call("open_library")
    check(_press(Campaign.text_for("en", "hub_read")), "Webcomic remains in the Chronicles menu")
    library.call("open_chapter", 0)
    await process_frame
    var comic: TextureRect = library.get("_page_image")
    check(is_instance_valid(comic) and comic.texture != null, "The first of the original 20 comics still opens")
    library.call("open_library")
    check(_press(Campaign.text_for("en", "hub_play")), "Campaign opens from Zen Chronicles")
    await process_frame
    verify_overview_art()
    check(_press(Campaign.text_for("en", "start_campaign")), "Overview enters the prologue")
    check(game.get("zen_campaign_active"), "Campaign is active on the real scene")
    check(_has_picture(Campaign.PROLOGUE), "Prologue illustration loads in the story")
    check(_press(Campaign.text_for("en", "next")), "Read the prologue")
    check(_has_picture(Campaign.FIRST_DEMON), "First encounter illustration loads")
    check(_press(Campaign.text_for("en", "begin")), "Begin The Startle")
    game.call("on_cell", 21)
    game.set_process(true)
    await create_timer(1.15).timeout
    game.set_process(false)
    var live_board: BoardModel = game.get("board")
    check(live_board.move_count() == 2 and live_board.cells.count(2) == 1, "The existing worker plays a demon move")
    var resume_cells := live_board.cells.duplicate()
    game.call("_zen_campaign_leave")
    check(game.get("board") == original_board and renderer.pivot.basis.is_equal_approx(original_orientation),
        "Leaving restores the exact original board and view")
    check(FileAccess.get_file_as_bytes(SaveManager.PATH) == saved_classic, "Campaign never writes the Classic file")
    await close_game()
    await open_game()
    game.call("start_zen_campaign")
    var restored: BoardModel = game.get("board")
    check(restored.cells == resume_cells, "Saved campaign positions survive a fresh scene")
    check(_press(Campaign.text_for("en", "resume")), "Resume the match")
    finish_with(2)
    game.call("_zen_campaign_advance")
    check(Campaign.load_progress().stage == 0, "A defeat cannot advance a regular encounter")
    game.call("_zen_campaign_retry")
    game.call("_zen_campaign_begin")
    make_draw()
    game.call("_zen_campaign_advance")
    check(Campaign.load_progress().stage == 0, "A draw cannot advance a regular encounter")
    game.call("_zen_campaign_retry")
    for stage in range(Campaign.EPILOGUE):
        game.call("_zen_campaign_begin")
        if stage == Campaign.LORD:
            var lord_board: BoardModel = game.get("board")
            check(lord_board.turn == 1 and lord_board.current_owner() == 1, "The Lord opens as X")
        finish_with(2 if stage == Campaign.LORD else 1)
        game.call("_zen_campaign_show_section")
        if stage == Campaign.SLAIN:
            check(_press(Campaign.text_for("en", "next")), "The Slain's revelation cannot be skipped after an early win")
        game.call("_zen_campaign_advance")
        var progress := Campaign.load_progress()
        check(progress.stage == stage + 1 and progress.game.is_empty(), "Victory unlocks encounter %d" % (stage + 1))
    check(Campaign.load_progress().night_result == "win", "The Still Hand result survives later chapters")
    game.call("_zen_campaign_begin")
    var local: BoardModel = game.get("board")
    game.call("on_cell", 4)
    game.call("on_cell", 13)
    check(local.cells[4] == 1 and local.cells[13] == 2, "Shin and Kuze can both play locally")
    finish_with(1)
    game.call("_zen_campaign_advance")
    check(Campaign.load_progress().stage == Campaign.COMPLETE, "The epilogue closes the story")
    game.call("_zen_campaign_leave")
    check(FileAccess.get_file_as_bytes(SaveManager.PATH) == saved_classic, "Eleven encounters and the epilogue preserve Classic data")
    library.call("close_chronicles")
    game.call("open_store")
    check(game.get("popup") != null and game.get("data").economy.leaves == 126, "The existing shop opens with its saved balance")
    await close_game()

func verify_night() -> void:
    for expected in ["loss", "draw", "timeout"]:
        var night := Campaign.defaults()
        night.stage = Campaign.NIGHT
        night.prologue_seen = true
        check(Campaign.save_progress(night), "Prepare Night fixture")
        await open_game()
        game.call("start_zen_campaign")
        game.call("_zen_campaign_begin")
        if expected == "timeout":
            game.call("_zen_campaign_tick", 12.5)
            game.call("_zen_campaign_leave")
            game.call("start_zen_campaign")
            check(is_equal_approx(float(game.get("zen_campaign_progress").seconds_left), 9.5),
                "The Night turn clock survives leaving and resuming")
            game.call("_zen_campaign_resume")
            game.call("_zen_campaign_tick", 10.0)
        elif expected == "draw":
            make_draw()
        else:
            finish_with(2)
        var decided := Campaign.load_progress()
        check(decided.night_result == expected, "The Night stores %s immediately" % expected)
        game.call("_zen_campaign_retry")
        check(Campaign.load_progress().game == decided.game, "The Night cannot be replayed")
        game.call("_zen_campaign_leave")
        await close_game()
        await open_game()
        game.call("start_zen_campaign")
        check(game.call("_zen_campaign_outcome") == expected, "Locked Night outcome reloads after restart")
        game.call("_zen_campaign_advance")
        var kept := Campaign.load_progress()
        check(kept.stage == Campaign.LORD and kept.night_result == expected, "The Red Hand route advances with its saved result")
        game.call("_zen_campaign_leave")
        await close_game()

func verify_languages() -> void:
    for lang in ["de", "en", "pt"]:
        var progress := Campaign.load_progress()
        progress.game = {}
        check(Campaign.save_progress(progress), "Prepare a new match for language " + lang)
        check(SaveManager.save_data(new_classic(lang)), "Set Classic language " + lang)
        await open_game()
        library.call("open_library")
        check(_press(Campaign.text_for(lang, "hub_play")), "Localized launch in " + lang)
        check(_press(Campaign.text_for(lang, "continue_campaign")), "Localized resume in " + lang)
        check(_press(Campaign.text_for(lang, "begin")), "Localized Next encounter in " + lang)
        var status: Label = game.get("status")
        check(status.text == Campaign.text_for(lang, "bot_turn") % [Campaign.stage_title(lang, Campaign.LORD), "X"],
            "Board honors the selected language " + lang)
        game.call("_zen_campaign_leave")
        await close_game()

func verify_overview_art() -> void:
    check(_has_picture(Campaign.POSTER), "Poster is connected to the campaign overview")
    for path in Campaign.CHAPTER_ART:
        check(_has_picture(path), "Chapter overview displays " + path.get_file())
    var poster: TextureRect = library.get("_screen").find_child(Campaign.POSTER.get_file().get_basename(), true, false)
    if is_instance_valid(poster):
        check(poster.size.x <= 480.0 and poster.size.y >= 178.0, "Poster fits the portrait viewport")
    for path in [Campaign.PROLOGUE, Campaign.FIRST_DEMON]:
        check(ResourceLoader.exists(path), "Story illustration is a Godot resource")

func _has_picture(path: String) -> bool:
    var screen: ColorRect = library.get("_screen")
    if not is_instance_valid(screen):
        return false
    var view := screen.find_child(path.get_file().get_basename(), true, false) as TextureRect
    return is_instance_valid(view) and view.texture != null

func _press(text: String) -> bool:
    var screen: ColorRect = library.get("_screen")
    if not is_instance_valid(screen):
        return false
    for button in screen.find_children("*", "Button", true, false):
        if button.text == text and not button.disabled:
            button.pressed.emit()
            return true
    return false

func finish_with(mark: int) -> void:
    var active: BoardModel = game.get("board")
    active.cells.fill(0)
    active.winner = 0
    for cell in WIN_LINE.slice(0, 3):
        active.cells[cell] = mark
    active.turn = mark
    game.call("place", WIN_LINE[3])
    check(active.winner == mark and active.win_lines.has(WIN_LINE), "Campaign result uses the cross-edge rule")

func make_draw() -> void:
    var cells: Array = JSON.parse_string(FileAccess.get_file_as_string("res://reports/draw_fixture.json"))
    var active: BoardModel = game.get("board")
    active.cells = cells.map(func(mark): return int(mark))
    var last := active.cells.find(2)
    active.cells[last] = 0
    active.turn = 2
    active.winner = 0
    game.call("place", last)
    check(active.winner == 3, "Canonical full-board fixture draws in Campaign")
