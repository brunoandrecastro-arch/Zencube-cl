extends SceneTree
# Regression for the German/English/Portuguese 4x4 mode picker.
# Tests every fixed Realm level and never edits a real player's saved progress.
const RealmData = preload("res://core/ZenAscendRealms.gd")
var failures: int = 0

func check(ok: bool, description: String) -> void:
    if not ok:
        failures += 1
        printerr("REALM PICKER LOCALIZATION FAIL: ", description)

func _initialize() -> void:
    call_deferred("run")

func _collect(node: Node, labels: Array, buttons: Array) -> void:
    if node is Label:
        labels.append((node as Label).text)
    elif node is Button:
        buttons.append(node)
    for child in node.get_children():
        _collect(child, labels, buttons)

func run() -> void:
    var path: String = SaveManager.PATH
    var saved_before: bool = FileAccess.file_exists(path)
    var previous: PackedByteArray = FileAccess.get_file_as_bytes(path) if saved_before else PackedByteArray()
    var data: Dictionary = SaveManager.defaults()
    data.ascension.rank = 3
    data.ascension.completed = [true, true, true, false, false]
    data.ascend.help_seen = true
    data.settings.language = "de"
    check(SaveManager.save_data(data), "temporary Zen Master entitlement")
    var scene: PackedScene = load("res://Ascend.tscn") as PackedScene
    check(scene != null, "game scene can load")
    if scene == null:
        quit(1)
        return

    var game: Node = scene.instantiate()
    root.add_child(game)
    await process_frame
    var expected_intros: Dictionary = {
        "de": "In diesem Reich ist die Schwierigkeit des Zen Ascend Bots fest vorgegeben.",
        "en": "This realm has a fixed Zen Ascend Bot difficulty.",
        "pt": "Neste reino, a dificuldade do Zen Ascend Bot é fixa."
    }
    var level_names: Dictionary = {
        "de": ["Mittel","Schwer","Meister","Großmeister"],
        "en": ["Medium","Hard","Master","Grandmaster"],
        "pt": ["Médio","Difícil","Mestre","Grão-Mestre"]
    }
    for language in ["de","en","pt"]:
        for realm in range(4):
            (game.get("data") as Dictionary).settings.language = language
            var selected: Dictionary = RealmData.state(game.get("data") as Dictionary)
            selected["selected"] = realm
            game.set("match_realm",realm)
            game.set("realm_story_active",false)
            game.call("show_mode_picker")
            var dialog: Node = game.get("active_realm_dialog")
            check(dialog != null, "4x4 picker appears " + language + " Realm " + str(realm))
            if dialog == null: continue
            var labels: Array = []
            var buttons: Array = []
            _collect(dialog,labels,buttons)
            check(labels.has(expected_intros[language]), "localized intro " + language)
            var expected_realm: String = RealmData.realm_name(realm,language)
            check(labels.has(expected_realm), "localized realm without unearned title dash " + language + " realm " + str(realm))
            var expected_bot: String = "Zen Ascend Bot · " + str(level_names[language][realm])
            check(labels.has(expected_bot), "localized difficulty " + language + " realm " + str(realm))
            var play_action: String = "Gegen %s spielen" % expected_bot if language == "de" else (("Play against %s" if language == "en" else "Jogar contra %s") % expected_bot)
            var found: bool = false
            for item in buttons:
                var button: Button = item as Button
                if button.text == play_action:
                    found = true
                    check(button.pressed.get_connections().size() > 0,"play action is functional")
            check(found,"localized play action " + language + " realm " + str(realm))
            if language == "de":
                check(not labels.has("This Realm has a fixed Zen Ascend Bot difficulty."), "no English intro in German UI")
                for item in buttons:
                    check(not str((item as Button).text).begins_with("Play Zen Ascend Bot"), "no English play verb")
    game.queue_free()
    await process_frame
    if saved_before:
        var back: FileAccess = FileAccess.open(path, FileAccess.WRITE)
        if back != null:
            back.store_buffer(previous)
            back.close()
    elif FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("REALM PICKER LOCALIZATION FAILURES=",failures)
    quit(0 if failures == 0 else 1)
