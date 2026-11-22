extends SceneTree
## Real navigation, restored matches, Act gates and optional onboarding.
const Journey = preload("res://story/ZenJourney.gd")
const Video = preload("res://ui/ZenMoonShadowVideo.gd")
const Fracture = preload("res://story/ZenFractureState.gd")
var failures: int = 0
var checks: int = 0
var backups: Dictionary = {}

func check(ok: bool, description: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        printerr("HOME FAIL: " + description)

func named(node: Node, target: String) -> Node:
    if node.name == target: return node
    for child in node.get_children():
        var found: Node = named(child, target)
        if found != null: return found
    return null

func caption(node: Node, target: String) -> Button:
    if node is Button and node.text == target: return node
    for child in node.get_children():
        var found: Button = caption(child, target)
        if found != null: return found
    return null

func _initialize() -> void:
    call_deferred("run")

func complete_act(act: int) -> void:
    var model: Script = Journey.MODELS[act - 1]
    var rules := RulesEngine.new()
    var board: BoardModel = model.new_board()
    var line: Array = rules.lines[0]
    for index in range(4):
        check(rules.play(board, int(line[index])), "fixture X move")
        if index == 3: break
        for cell in range(54):
            if line.has(cell) or board.cells[cell] != 0: continue
            var simulated: Array = board.cells.duplicate()
            simulated[cell] = 2
            if not rules.victories(simulated, 2).is_empty(): continue
            if rules.play(board, cell): break
    var progress: Dictionary = model.fresh()
    model.capture(progress, board)
    progress.acknowledged = true
    progress.complete = true
    progress.page = 12
    check(model.save_progress(progress) and bool(model.load_progress().complete), "fixture saves a validated Act victory")

func shot(path: String) -> void:
    if DisplayServer.get_name() == "headless": return
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png(path) == OK, "rendered UI preview")

func run() -> void:
    var paths: Array[String] = [SaveManager.PATH, Fracture.PATH]
    for model in Journey.MODELS: paths.append(model.SAVE_FILE)
    for path in paths:
        backups[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
        if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    var saved: Dictionary = SaveManager.defaults()
    saved.settings.language = "en"
    saved.settings.intro_seen = true
    saved.settings.campaign_intro_seen = true
    saved.settings.music = false
    check(SaveManager.save_data(saved), "fresh localized profile")
    var game: Node = load("res://Main.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    await process_frame
    await process_frame
    var chronicles: Node = root.get_node("ZenChronicles")
    check(game.home_visible and not game.column.visible, "home hides in-game HUD")
    var play: Button = named(game.popup, "HomeCampaign") as Button
    check(play != null and play.text == "Start Campaign", "campaign is the primary first-run action")
    var story: Button = named(game.popup, "MainMenuZenChronicles") as Button
    check(story != null and story.get_parent() == play.get_parent() and story.get_index() == play.get_index() + 1, "Chronicles immediately follows the campaign button")
    check(named(game.popup, "HomeZenAscend") != null and named(game.popup, "HomeWorlds") != null and named(game.popup, "HomeAchievements") != null, "home exposes Worlds, Zen Ascend and Achievements")
    check(named(game.popup, "HomeHowToPlay") != null, "How to Play is always reachable")
    var original: Dictionary = game.board.snapshot()
    for language in ["de", "en", "pt"]:
        game.data.settings.language = language
        game.open_menu()
        var button: Button = named(game.popup, "HomeCampaign") as Button
        check(button.text == game.T("Kampagne starten"), "localized campaign CTA " + language)
        check((named(game.popup, "HomeHowToPlay") as Button).text == game.T("Spielanleitung"), "localized help " + language)
        await shot("res://docs/menu-preview-" + language + ".png")
        var help: Control = named(game.popup, "HomeHowToPlay") as Control
        check(help.get_global_rect().end.y <= root.size.y, "primary navigation fits on a phone without scrolling " + language)
    game.data.settings.language = "en"
    game.persist()
    game.open_menu()
    (named(game.popup, "HomeHowToPlay") as Button).pressed.emit()
    check(not game.home_visible and caption(game.popup, "Start mini tutorial") != null, "full illustrated help opens on demand")
    caption(game.popup, "Back to main menu").pressed.emit()
    check(game.home_visible, "help returns to home")
    (named(game.popup, "HomeGameModes") as Button).pressed.emit()
    check(caption(game.popup, "Free Play") != null and caption(game.popup, "Zen Ascend") == null, "game modes group play choices without spoilers")
    caption(game.popup, game.T("Zwei Spieler lokal")).pressed.emit()
    check(game.popup == null and game.column.visible and int(game.data.settings.mode) == 0, "local play enters the board")
    check(game.board.snapshot() == original, "menu navigation preserves the original empty board")

    game.open_menu()
    game.resume_campaign()
    check(chronicles.get("_screen_name") == "act-one-reader" and chronicles.get("_prequel_act") == 1, "one campaign action opens the current Act directly")
    check(game.board.snapshot() == original, "reading a story does not replace the Classic board")
    chronicles.open_library()
    await shot("res://docs/unlock-preview-en.png")
    chronicles.close_chronicles()
    game.open_menu()
    game.data.settings.campaign_intro_seen = false
    game.resume_campaign()
    check(caption(game.popup, "Learn to Play") != null and caption(game.popup, "Skip and Start Campaign") != null, "first campaign offers a short, skippable introduction")
    caption(game.popup, "Learn to Play").pressed.emit()
    check(game.tutorial != null and game.tutorial_quick, "short interactive tutorial starts")
    game.tutorial_step(1)
    game.tutorial_step(1)
    check(game.tutorial.step == 2 and game.help_text.text.begins_with("3 / 3"), "short tutorial has three steps")
    game.tutorial_step(1)
    check(game.tutorial == null and chronicles.get("_screen_name") == "act-one-reader", "tutorial returns to the campaign")
    chronicles.close_chronicles()

    complete_act(1)
    var step: Dictionary = Journey.next_step(game.data)
    check(step.kind == "matches" and int(step.world) == 0 and int(step.level) == 0, "Act II task uses accessible Zen Garden and Easy")
    check(Journey.gate_hint(game.data, 2, "en").contains("Win 3 matches on Easy difficulty in Zen Garden."), "explicit task includes the playable World")
    check(Journey.gate_hint(game.data, 2, "en").contains("Progress: 0/3"), "explicit current progress")
    game.start_mode(1, 0)
    game.place(4)
    var unfinished: Dictionary = game.board.snapshot()
    game.open_menu()
    game.resume_campaign()
    check(game.popup == null and game.board.snapshot() == unfinished, "Continue Campaign resumes a matching unfinished match")
    game.data.settings.mode = 0
    game.open_menu()
    game.resume_campaign()
    check(game.popup != null and caption(game.popup, "Resume match") != null, "different unfinished match requires a choice before replacement")
    caption(game.popup, "Resume match").pressed.emit()
    check(game.board.snapshot() == unfinished, "keeping an unfinished match preserves every move")
    game.open_menu()
    game.resume_campaign()
    caption(game.popup, "Start campaign match").pressed.emit()
    check(game.board.move_count() == 0 and int(game.data.settings.mode) == 1 and int(game.data.settings.level) == 0 and int(game.data.ascension.world) == 0, "accepted objective starts the correct World and difficulty")

    game.data.stats.ai_wins[0] = 3
    ZenAscension.ensure(game.data)
    game.persist()
    step = Journey.next_step(game.data)
    check(step.kind == "story" and int(step.act) == 2, "completed wins point directly to Act II")
    var page: Dictionary = Journey.MODELS[1].fresh()
    page.page = 4
    Journey.MODELS[1].save_progress(page)
    game.resume_campaign()
    check(chronicles.get("_prequel_act") == 2 and int(chronicles.get("_act_one_progress").page) == 4, "campaign continuation restores the saved Manhwa page")
    chronicles.close_chronicles()
    complete_act(2)
    game.data.stats.ai_wins[1] = 2
    step = Journey.next_step(game.data)
    check(step.kind == "matches" and int(step.world) == 1 and int(step.level) == 1 and int(step.target) == 5, "Act III task uses Bamboo Path and Medium")
    check(Journey.gate_hint(game.data, 3, "en").contains("Progress: 2/5"), "existing wins are retained")
    check(Journey.gate_task(4, "en") == "Win 7 matches on Hard difficulty in Mountain Temple.", "Act IV task uses the preceding unlocked World")
    for language in ["de", "en", "pt"]:
        for act in [2, 3, 4]:
            var hint: String = Journey.gate_hint(game.data, act, language)
            check(not hint.contains("%d") and not hint.contains("%s"), "formatted unlock copy " + language)
    check(Video.media_ready(), "approved video is present and loadable in this source branch")
    check(not Fracture.awakening_seen(), "navigation does not unlock the next dimension")
    complete_act(3)
    complete_act(4)
    game.data.stats.ai_wins = [3, 5, 7, 0, 0]
    ZenAscension.ensure(game.data)
    game.persist()
    game.resume_campaign()
    check(int(chronicles.get("_prequel_act")) == 4 and not Fracture.awakening_seen(), "interrupted finale resumes Act IV before revealing Realms")
    chronicles.close_chronicles()
    var fourth: Dictionary = Journey.MODELS[3].load_progress()
    fourth.complete = false
    fourth.page = 12 # The real result acknowledgment stores page twelve before opening the reader.
    Journey.MODELS[3].save_progress(fourth)
    chronicles.open_act_four()
    var player: VideoStreamPlayer = named(root, "MoonShadow3x3To4x4") as VideoStreamPlayer
    check(player != null and player.is_playing(), "real approved video starts after Act IV boss victory")
    check(bool(chronicles.get("_act_four_interlude_running")), "page twelve waits for the interlude")
    var skip: Button = named(root, "SkipMoonShadowVideo") as Button
    check(skip != null, "video remains skippable")
    if skip != null: skip.pressed.emit()
    check(Fracture.interlude_seen() and not Fracture.awakening_seen(), "video checkpoint is independent of Shadow unlock")
    check(int(Journey.MODELS[3].load_progress().page) == 12 and not bool(Journey.MODELS[3].load_progress().complete), "video continues to page twelve before final completion")
    await process_frame
    chronicles.call("_act_one_turn", -1)
    chronicles.call("_act_one_turn", 1)
    skip = named(root, "SkipMoonShadowVideo") as Button
    check(skip != null and int(Journey.MODELS[3].load_progress().page) == 11, "manual page eleven waits for the video before turning")
    if skip != null: skip.pressed.emit()
    check(int(Journey.MODELS[3].load_progress().page) == 12, "manual video replay continues to page twelve")
    chronicles.close_chronicles()
    game.queue_free()
    await process_frame
    await process_frame
    for path in paths:
        if backups[path] == null:
            if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
        else:
            var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
            file.store_buffer(backups[path])
            file.close()
    print("HOME NAVIGATION: ", checks, " checks, ", failures, " failures")
    quit(0 if failures == 0 else 1)
