extends SceneTree
# Release regression: no English-only system text in German/Portuguese
# 4x4 statistics, secret achievements, challenges or main menus.
# The test uses a temporary user save and restores the original bytes.
const Realms = preload("res://core/ZenAscendRealms.gd")
const Achievements = preload("res://core/ZenAscendAchievements.gd")
var failures: int = 0

func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        printerr("FINAL 2.0 LOCALIZATION FAIL: ",message)

func _initialize() -> void:
    call_deferred("run")

func _collect(node: Node, output: Array) -> void:
    if node is Label or node is Button:
        output.append(str(node.get("text")))
    for child in node.get_children():
        _collect(child,output)

func visible_text(node: Node) -> String:
    var all: Array = []
    _collect(node,all)
    return " | ".join(all)

func run() -> void:
    var path: String = SaveManager.PATH
    var previous_exists: bool = FileAccess.file_exists(path)
    var previous_bytes: PackedByteArray = FileAccess.get_file_as_bytes(path) if previous_exists else PackedByteArray()
    var data: Dictionary = SaveManager.defaults()
    data.ascension.rank = 3
    data.ascension.completed = [true,true,true,false,false]
    data.ascend.help_seen = true
    data.settings.language = "de"
    check(SaveManager.save_data(data),"temporary Zen-Master test save")

    var scene: PackedScene = load("res://Ascend.tscn") as PackedScene
    check(scene != null,"4x4 scene loads")
    if scene == null:
        quit(1)
        return
    var game: Node = scene.instantiate()
    root.add_child(game)
    await process_frame
    var expected: Dictionary = {
        "de":{"menu":"Zen Ascend · Menü","stats":"Partien ","stats2":"Siegquote ",
              "stats3":"Schnellster Sieg ","next":"Nächster Rang","secrets":"Geheime Erfolge",
              "view":"Realm-Titel ansehen","hidden":"Freischaltbedingung verborgen",
              "challenge":"Erster Schritt im Schatten","realm":"Schattenreich",
              "quote":"Jede lange Reise beginnt dort, wo das Licht endet.",
              "achieved":"Erfolg freigeschaltet","condition":"Gewinne 2 Partien im Shadow Realm."},
        "en":{"menu":"Zen Ascend · Menu","stats":"Matches ","stats2":"Win rate ",
              "stats3":"Fastest win ","next":"Next rank","secrets":"Secret achievements",
              "view":"View Realm title","hidden":"Unlock condition hidden",
              "challenge":"First Step into Shadow","realm":"Shadow Realm",
              "quote":"Every long journey begins where the light ends.",
              "achieved":"Achievement unlocked","condition":"Win 2 matches in Shadow Realm."},
        "pt":{"menu":"Zen Ascend · Menu","stats":"Partidas ","stats2":"Taxa de vitórias ",
              "stats3":"Vitória mais rápida ","next":"Próximo nível","secrets":"Conquistas secretas",
              "view":"Ver título do reino","hidden":"Condição de desbloqueio oculta",
              "challenge":"Primeiro Passo nas Sombras","realm":"Reino das Sombras",
              "quote":"Toda a longa viagem começa onde a luz termina.",
              "achieved":"Conquista desbloqueada","condition":"Ganha 2 partidas no Shadow Realm."}
    }
    for language in ["de","en","pt"]:
        (game.get("data") as Dictionary).settings.language = language
        var wanted: Dictionary = expected[language]
        game.call("show_ascend_menu")
        var shown: String = visible_text(game.get("active_realm_dialog"))
        check(shown.contains(str(wanted.menu)),"localized menu title " + language)

        game.call("show_statistics")
        shown = visible_text(game.get("active_realm_dialog"))
        for key in ["stats","stats2","stats3","next"]:
            check(shown.contains(str(wanted[key])),"localized statistics %s / %s" % [language,key])
        if language != "en":
            check(not shown.contains("Next rank") and not shown.contains("Win rate"),"no English stats in " + language)

        game.call("show_challenges")
        shown = visible_text(game.get("active_realm_dialog"))
        check(shown.contains(str(wanted.challenge)),"translated Challenge name in " + language)
        check(shown.contains(str(wanted.realm)),"localized Realm heading in " + language)

        game.call("show_realm_titles")
        shown = visible_text(game.get("active_realm_dialog"))
        check(shown.contains(str(wanted.secrets)),"localized achievements count in " + language)
        check(shown.contains(str(wanted.view)),"localized realm-title action in " + language)

        game.call("_show_achievement_details",0,Achievements.SECRETS[0],true)
        shown = visible_text(game.get("active_realm_dialog"))
        check(shown.contains(str(wanted.achieved)),"localized Achievement heading in " + language)
        check(shown.contains(str(wanted.quote)),"localized earned Achievement quote in " + language)
        check(shown.contains(str(wanted.condition)),"exact local unlock condition in " + language)

        game.call("_show_achievement_details",0,Achievements.SECRETS[1],false)
        shown = visible_text(game.get("active_realm_dialog"))
        check(shown.contains(str(wanted.hidden)),"secret conditions stay hidden in " + language)
        check(not shown.contains(str(Achievements.SECRETS[1].condition)),"no premature reveal of secret conditions in " + language)
        check(Achievements.hint_text("keeper_silence",language).length() > 12,"translated purchased hints in " + language)

    check(not (game.get("data") as Dictionary).get("economy",{}).get("ascend_owned",false),
          "viewing screens does not purchase a Realm")
    game.queue_free()
    await process_frame
    if previous_exists:
        var restored: FileAccess = FileAccess.open(path,FileAccess.WRITE)
        if restored != null:
            restored.store_buffer(previous_bytes)
            restored.close()
    elif FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("FINAL 2.0 LOCALIZATION FAILURES=",failures)
    quit(0 if failures == 0 else 1)
