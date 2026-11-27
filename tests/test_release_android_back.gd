extends SceneTree
## Exercise Android Back notifications through the real autoload and Tower UI.
const Tower = preload("res://core/ZenTower.gd")
const Soundtrack = preload("res://core/ZenStorySoundtrack507.gd")
var failures: int = 0
var checks: int = 0

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        printerr("BACK/MUSIC FAIL: " + message)

func _initialize() -> void:
    call_deferred("run")

func back(chronicles: Node) -> void:
    chronicles.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
    await process_frame
    await process_frame

func run() -> void:
    var saved: Dictionary = SaveManager.defaults()
    saved.settings.merge({"language": "en", "intro_seen": true, "campaign_intro_seen": true, "music": true, "mode": 0}, true)
    check(SaveManager.save_data(saved), "seed isolated profile")
    var game: Node = load("res://Main.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    await process_frame
    await process_frame
    var chronicles: Node = root.get_node("ZenChronicles")
    check(not quit_on_go_back, "automatic Android exit is disabled")
    var state: Dictionary = Tower.ensure(game.data)
    var guardian: Dictionary = Tower.manifest().guardians[0]
    state.cards.append(str(guardian.id))
    game.open_zen_tower()
    await process_frame
    await process_frame
    var player: AudioStreamPlayer = game.music_player
    var stream: AudioStream = player.stream
    check(player.playing and int(player.get_meta("track")) == Soundtrack.track_id("tower_menu"), "real Tower menu stream plays")
    player.seek(20.0)
    game.open_tower_gallery()
    await process_frame
    for reverse in [false, true]:
        game._tower_card(guardian, reverse)
        await process_frame
        await process_frame
        check(game.popup.name == "HDGuardianCard", "loot card face opens")
        check(game.music_player == player and player.stream == stream, "loot card keeps the same audio player and stream")
        check(player.playing and player.get_playback_position() >= 19.0, "loot card does not restart menu music")
        await back(chronicles)
        check(is_instance_valid(game) and game.popup.name == "HDGuardianGallery", "Android Back returns from loot to gallery")
    game._tower_preview(guardian)
    await process_frame
    await back(chronicles)
    check(game.popup.name == "HDGuardianGallery", "Android Back returns from portrait to gallery")
    await back(chronicles)
    check(game.popup.name == "HDTowerEntry", "Android Back returns from gallery to Tower menu")
    check(game.music_player == player and player.stream == stream and player.get_playback_position() >= 19.0, "menu navigation preserves continuous playback")
    await back(chronicles)
    check(game.popup.name == "HomeScreen", "Android Back returns from Tower to main menu")
    await back(chronicles)
    check(is_instance_valid(game) and game.popup.name == "HDExitConfirm", "main menu Back asks before exiting")
    await back(chronicles)
    check(is_instance_valid(game) and game.popup.name == "HomeScreen", "Back cancels the exit confirmation")
    check(not quit_on_go_back, "Back handling never enables automatic exit")
    player = null
    stream = null
    game.queue_free()
    await process_frame
    await process_frame
    await create_timer(0.1).timeout
    print("ANDROID BACK/MUSIC CHECKS: %d; FAILURES: %d" % [checks, failures])
    quit(0 if failures == 0 else 1)
