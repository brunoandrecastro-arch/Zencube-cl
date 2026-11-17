extends SceneTree
# Device-friendly settings QA: readable native controls, separate scroll body,
# fixed Done footer and DE/EN/PT labels without changing gameplay or saves.
var failures: int = 0

func check(ok: bool, note: String) -> void:
    if not ok:
        failures += 1
        printerr("SETTINGS CONTRAST FAIL: " + note)

func _initialize() -> void:
    call_deferred("run")

func _lightness(c: Color) -> float:
    return c.r*0.2126 + c.g*0.7152 + c.b*0.0722

func run() -> void:
    var path: String = SaveManager.PATH
    var had_save: bool = FileAccess.file_exists(path)
    var backup: PackedByteArray = FileAccess.get_file_as_bytes(path) if had_save else PackedByteArray()
    var initial: Dictionary = SaveManager.defaults()
    initial.settings.intro_seen = true
    initial.settings.language = "de"
    check(SaveManager.save_data(initial),"isolated settings QA save")
    var scene: PackedScene = load("res://Main.tscn") as PackedScene
    check(scene != null,"classic scene available")
    if scene == null:
        quit(1)
        return
    var game: Node = scene.instantiate()
    root.add_child(game)
    await process_frame

    for language in ["de","en","pt"]:
        game.call("choose_language",language)
        game.call("open_settings")
        await process_frame
        var panel: PanelContainer = game.get("popup") as PanelContainer
        check(panel != null,"settings dialog shows in " + language)
        if panel == null: continue

        var layout: VBoxContainer = panel.find_child("SettingsDialogLayout",true,false) as VBoxContainer
        var footer: MarginContainer = panel.find_child("SettingsStickyFooter",true,false) as MarginContainer
        var done: Button = panel.find_child("SettingsDoneSticky",true,false) as Button
        check(layout != null and footer != null and done != null,"fixed footer exists in " + language)
        if layout != null and footer != null and done != null:
            check(layout.get_child_count() == 2,"only scroll region and sticky footer")
            var scroll: ScrollContainer = layout.get_child(0) as ScrollContainer
            check(scroll != null,"scroll region kept in settings layout")
            if scroll != null:
                check(scroll.get_parent() == layout and done.get_parent() == footer,"Done sits outside scrolling content")
                check(scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO,"settings scroll on Android")
            check(done.visible and done.custom_minimum_size.y >= 50,"Done tap target visible and large")
            var inside: Rect2 = panel.get_global_rect()
            var finish_rect: Rect2 = done.get_global_rect()
            check(finish_rect.size.y >= 44 and finish_rect.end.y <= inside.end.y + 3.0,"Done inside screen at bottom " + language)

        var names: Array = ["SettingsPlayerName1","SettingsPlayerName2"]
        for name in names:
            var edit: LineEdit = panel.find_child(name,true,false) as LineEdit
            check(edit != null,"editable player name exists: " + name)
            if edit != null:
                var bg: StyleBoxFlat = edit.get_theme_stylebox("normal") as StyleBoxFlat
                var text_color: Color = edit.get_theme_color("font_color")
                check(bg != null and _lightness(bg.bg_color) > 0.7,"bright name field " + name)
                check(_lightness(text_color) < 0.35,"dark name text " + name)
                check(edit.editable,"player field not accidentally disabled")
                check(edit.custom_minimum_size.y >= 50,"player field tap area")

        for name in ["SettingsLanguage","SettingsBotDifficulty","SettingsMusicTrack"]:
            var option: OptionButton = panel.find_child(name,true,false) as OptionButton
            check(option != null,"settings picker " + name)
            if option != null:
                var bg: StyleBoxFlat = option.get_theme_stylebox("normal") as StyleBoxFlat
                check(bg != null and _lightness(bg.bg_color) < 0.40,"jade picker surface " + name)
                check(_lightness(option.get_theme_color("font_color")) > 0.65,"light picker text " + name)
                check(option.custom_minimum_size.y == 54.0,"consistent picker heights")
                var menu: PopupMenu = option.get_popup()
                check(menu != null and menu.theme != null,"dropdown popup themed " + name)
                if menu != null and menu.theme != null:
                    check(_lightness(menu.theme.get_color("font_color","PopupMenu")) > 0.65,"dropdown items readable " + name)

        for name in ["SettingsBackgroundMusic","SettingsSoundEffects","SettingsVibration",
                     "SettingsHints","SettingsAlternateStarter","SettingsSymbolSwap"]:
            var toggle: CheckButton = panel.find_child(name,true,false) as CheckButton
            check(toggle != null,"switch present " + name)
            if toggle != null:
                check(_lightness(toggle.get_theme_color("font_color")) > 0.65,"switch bright text " + name)
                check(_lightness(toggle.get_theme_color("font_disabled_color")) > 0.55,"disabled switch legible " + name)
                check(toggle.custom_minimum_size.y == 54.0,"consistent switch heights")

        var expected: Dictionary = {"de":"Bot-Schwierigkeit","en":"Bot difficulty","pt":"Dificuldade do bot"}
        check(str(game.call("T","Bot-Schwierigkeit")) == str(expected[language]),"translated difficulty heading " + language)
        check(done != null and done.text == str(({"de":"Fertig","en":"Done","pt":"Concluído"})[language]),"localized fixed Done " + language)
        if done != null: done.pressed.emit()
        check(game.get("popup") == null,"Done actually closes settings in " + language)

    game.queue_free()
    await process_frame
    if had_save:
        var restore: FileAccess = FileAccess.open(path,FileAccess.WRITE)
        if restore != null:
            restore.store_buffer(backup)
            restore.close()
    elif FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("SETTINGS CONTRAST FAILURES=",failures)
    quit(0 if failures == 0 else 1)
