extends Node3D
var board = BoardModel.new()
var rules = RulesEngine.new()
var data: Dictionary
var renderer: CubeRenderer
var input_control: InputController
var ui: Control
var column: VBoxContainer
var status: Label
var detail: Label
var help_text: Label
var swap_row: HBoxContainer
var tutorial_row: HBoxContainer
var viewport: SubViewport
var popup: PanelContainer
var preview: Array = []
var preview_index: int = 0
var tutorial: TutorialController
var saved_training: Dictionary = {}
var worker: Thread
var generation = 0
var worker_generation = -1
var ai_running = false
var sound_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var net_buttons: Array = []
var net_active = false
var tutorial_from_welcome = false
var welcome_open = false
var toast = ""
var toast_until = 0
const ZenLocale = preload("res://core/ZenLocalization.gd")
func language_code() -> String:
    if data == null: return "de"
    return str(data.settings.get("language", "de"))
func T(source: String) -> String:
    return ZenLocale.english(source) if language_code() == "en" else source
func translate_ui_tree(node: Node) -> void:
    if node.has_meta("zen_source_text"):
        if node is Button or node is Label:
            node.text = T(str(node.get_meta("zen_source_text")))
    for child in node.get_children():
        translate_ui_tree(child)
func choose_language(code: String) -> void:
    if not code in ["de", "en"]: return
    data.settings.language = code
    close_modal()
    translate_ui_tree(ui)
    refresh()
    if not bool(data.settings.get("intro_seen", false)):
        open_welcome()
    else:
        open_menu()
func change_language(code: String) -> void:
    choose_language(code)
    if bool(data.settings.get("intro_seen", false)):
        open_settings()
func open_language_choice() -> void:
    var box = modal("Choose language · Sprache wählen")
    # The first-run language decision must be made before starting the tutorial.
    box.get_child(1).hide()
    label("Select your language / Wähle deine Sprache", box, 18)
    button("Deutsch", box, choose_language.bind("de"), false, true)
    button("English", box, choose_language.bind("en"), false, true)
    label("You can change this later in Settings. / Du kannst dies später ändern.", box, 13)
func _ready() -> void:
    data = SaveManager.load_data()
    if SaveManager.valid_game(data.game):
        board.restore(data.game)
        board.history = data.game.get("history",[])
        board.win_lines = rules.victories(board.cells,1)+rules.victories(board.cells,2)
    else:
        board.swap_enabled = bool(data.settings.swap)
    build_ui()
    build_sound()
    refresh()
    if not str(data.settings.get("language", "")) in ["de", "en"]:
        open_language_choice()
    elif not bool(data.settings.get("intro_seen",false)):
        # Visual examples are shown before the very first game.
        open_welcome()
func theme_style(bg: Color, radius: int = 18) -> StyleBoxFlat:
    var st = StyleBoxFlat.new()
    st.bg_color = bg
    st.border_color = Color("c99f64",0.82)
    st.set_border_width_all(2)
    st.set_corner_radius_all(radius)
    st.content_margin_left = 13
    st.content_margin_right = 13
    st.content_margin_top = 10
    st.content_margin_bottom = 10
    st.shadow_color = Color("3a2a17",0.18)
    st.shadow_size = 5
    st.shadow_offset = Vector2(0,3)
    return st
func button(text: String, parent: Node, callback: Callable, small: bool = false, primary: bool = false) -> Button:
    var b = Button.new()
    b.text = T(text)
    b.set_meta("zen_source_text", text)
    b.custom_minimum_size.y = 44 if small else 52
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.focus_mode = Control.FOCUS_NONE
    if primary:
        b.add_theme_stylebox_override("normal",theme_style(Color("53643e"),18))
        b.add_theme_stylebox_override("hover",theme_style(Color("63754b"),18))
        b.add_theme_stylebox_override("pressed",theme_style(Color("3c4d2c"),18))
        for color_key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
            b.add_theme_color_override(color_key,Color("fff3d5"))
    b.pressed.connect(callback)
    parent.add_child(b)
    return b
func label(text: String, parent: Node, size: int = 16, color: Color = Color("74614c")) -> Label:
    var l = Label.new()
    l.text = T(text)
    l.set_meta("zen_source_text", text)
    l.add_theme_font_size_override("font_size",size)
    l.add_theme_color_override("font_color",color)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(l)
    return l
func row(parent: Node) -> HBoxContainer:
    var r = HBoxContainer.new()
    r.add_theme_constant_override("separation",8)
    parent.add_child(r)
    return r
func build_ui() -> void:
    var layer = CanvasLayer.new()
    layer.layer = 2
    add_child(layer)
    ui = Control.new()
    layer.add_child(ui)
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.mouse_filter = Control.MOUSE_FILTER_PASS

    # A dedicated original illustration, with NO baked-in buttons or cube.
    var garden = TextureRect.new()
    garden.name = "GardenBackground"
    garden.texture = load("res://assets/zen_garden_scene.webp")
    garden.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    garden.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    garden.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(garden)
    garden.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var veil = ColorRect.new()
    veil.color = Color("f2dfbb",0.13)
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(veil)
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var th = Theme.new()
    th.default_font_size = 17
    th.set_stylebox("normal","Button",theme_style(Color("faecd3"),18))
    th.set_stylebox("hover","Button",theme_style(Color("f6dfbb"),18))
    th.set_stylebox("pressed","Button",theme_style(Color("e9cda6"),18))
    th.set_stylebox("focus","Button",theme_style(Color("eed4ab"),18))
    for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
        th.set_color(key,"Button",Color("493521"))
    for typ in ["Label","CheckButton","OptionButton","LineEdit"]:
        th.set_color("font_color",typ,Color("493521"))
    th.set_color("font_hover_color","CheckButton",Color("493521"))
    ui.theme = th

    var margin = MarginContainer.new()
    ui.add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,12)
    margin.add_theme_constant_override("margin_top",12)
    margin.add_theme_constant_override("margin_bottom",12)
    column = VBoxContainer.new()
    column.add_theme_constant_override("separation",6)
    margin.add_child(column)

    # Carved-wood title panel inspired by the approved reference design.
    var title_panel = PanelContainer.new()
    title_panel.add_theme_stylebox_override("panel",theme_style(Color("4b3020",0.96),25))
    column.add_child(title_panel)
    var title_row = row(title_panel)
    var brand = VBoxContainer.new()
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    brand.add_theme_constant_override("separation",1)
    title_row.add_child(brand)
    var title_text = label("ZenCube 3D",brand,27,Color("f9e5b8"))
    title_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var sub = label("— Zen Garden Edition —",brand,12,Color("e6c99d"))
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var menu = button("☰",title_row,open_menu,true)
    menu.custom_minimum_size.x = 46
    menu.size_flags_horizontal = Control.SIZE_SHRINK_END
    var tagline = label("A calm strategy game of balance, space and focus.",column,11,Color("4a3423"))
    tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    var ribbon = PanelContainer.new()
    ribbon.add_theme_stylebox_override("panel",theme_style(Color("fff1d7",0.91),18))
    column.add_child(ribbon)
    var header = VBoxContainer.new()
    header.add_theme_constant_override("separation",1)
    ribbon.add_child(header)
    status = label("",header,20,Color("453329"))
    detail = label("",header,12,Color("80684e"))

    # Live 3D cube floats over the real garden scene. No static screenshot
    # can intercept cube gestures or pretend to be the board.
    var game_card = PanelContainer.new()
    var transparent_panel = theme_style(Color("f8ebcf",0.07),20)
    transparent_panel.border_color = Color("8d6b43",0.28)
    game_card.add_theme_stylebox_override("panel",transparent_panel)
    game_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(game_card)
    var game_stack = VBoxContainer.new()
    game_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
    game_card.add_child(game_stack)
    var container = SubViewportContainer.new()
    container.mouse_filter = Control.MOUSE_FILTER_STOP
    container.stretch = true
    container.custom_minimum_size = Vector2(0,225)
    container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    game_stack.add_child(container)
    viewport = SubViewport.new()
    viewport.size = Vector2i(440,440)
    viewport.transparent_bg = true
    viewport.own_world_3d = true
    viewport.msaa_3d = Viewport.MSAA_4X
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    container.add_child(viewport)
    renderer = CubeRenderer.new()
    viewport.add_child(renderer)
    input_control = InputController.new(renderer,on_cell)
    container.gui_input.connect(input_control.handle)

    help_text = label("Ziehen: drehen  ·  Tippen: setzen  ·  2 Finger: zoomen",column,12,Color("543d27"))
    help_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    swap_row = row(column)
    button("X übernehmen",swap_row,func(): resolve_swap(true))
    button("O behalten",swap_row,func(): resolve_swap(false))
    tutorial_row = row(column)
    button("Zurück",tutorial_row,func(): tutorial_step(-1),true)
    button("Weiter",tutorial_row,func(): tutorial_step(1),true)
    button("Spielen",tutorial_row,end_tutorial,true,true)
    var views = row(column)
    button("Ansicht",views,func(): renderer.reset_view(),true)
    button("Alle Seiten",views,open_net,true)
    button("Hinweis",views,open_help,true)
    var actions = row(column)
    button("Rückgängig",actions,undo)
    button("Neue Partie",actions,confirm_new,true,true)
    var meta = label("6 SEITEN · 54 FELDER · 108 VIERERLINIEN",column,11,Color("5b4430"))
    meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
func mode_name() -> String:
    var mode = int(data.settings.mode)
    if mode == 1: return T("Du gegen Zen-Bot · ")+T(["Leicht","Mittel","Schwer"][int(data.settings.level)])
    if mode == 2: return T("Lernmodus")
    return T("Zwei Spieler lokal")
func player_name(owner: int) -> String:
    if int(data.settings.mode) == 1:
        return "Zen-Bot" if owner == 1 else T("Du")
    var pname = str(data.settings.names[owner])
    return T(pname)
func refresh(animate: int = -1) -> void:
    var sym := "X" if board.turn == 1 else "O"
    var owner := board.current_owner()
    if int(data.settings.mode) == 1:
        status.text = T("Zen-Bot denkt nach …") if owner == 1 else T("Du bist am Zug  ·  ")+sym
    else:
        status.text = player_name(owner)+T(" ist am Zug  ·  ")+sym
    status.add_theme_color_override("font_color", Color("453329") if board.turn == 1 else Color("a75f43"))
    if board.swap_pending: status.text = player_name(board.owners[1])+T(" · Farbe wählen")
    if board.winner != 0:
        status.text = T("Unentschieden · gut gespielt!") if board.winner == 3 else player_name(board.owners[board.winner-1])+T(" gewinnt!")
        status.add_theme_color_override("font_color", Color("67785b"))
    detail.text = mode_name()+T("  ·  Zug ")+str(board.move_count())
    if ai_running: detail.text += T("  ·  Zen-Bot überlegt …")
    swap_row.visible = board.swap_pending and not (int(data.settings.mode) == 1 and board.current_owner() == 1 and tutorial == null)
    tutorial_row.visible = tutorial != null
    if tutorial != null:
        help_text.text = str(tutorial.step+1)+" / "+str(TutorialController.TEXTS.size())+"  ·  "+T(TutorialController.TEXTS[tutorial.step])
    else:
        help_text.text = toast if Time.get_ticks_msec()<toast_until else T("Ziehen: drehen  ·  Tippen: setzen  ·  2 Finger: zoomen")
    renderer.selected = board.last_cell
    renderer.paint(board,bool(data.settings.hints) or tutorial != null,preview,animate)
    if tutorial == null: persist()
    if net_active: update_net()
func persist() -> void:
    if tutorial != null:
        data.game = saved_training.board.duplicate(true)
        data.game["history"] = saved_training.history.duplicate(true)
    else:
        data.game = board.snapshot()
        data.game["history"] = board.history.duplicate(true)
    if not SaveManager.save_data(data): notify_user("Speichern fehlgeschlagen: Speicherplatz prüfen.")
func notify_user(message: String) -> void:
    toast = T(message)
    toast_until = Time.get_ticks_msec()+4000
    if help_text != null: help_text.text = message
func on_cell(cell: int) -> void:
    if cell < 0 or (popup != null and not net_active): return
    if ai_running or (tutorial == null and int(data.settings.mode) == 1 and board.current_owner() == 1): return
    if tutorial != null:
        if tutorial.step in [0,5,6]: return
        if tutorial.step in [2,3,4] and (not preview.has(cell) or board.cells[cell] != 0):
            notify_user("Tippe das freie, markierte Feld an.")
            return
    place(cell)
func place(cell: int) -> void:
    if not rules.play(board,cell):
        if board.swap_pending: notify_user("Zuerst X übernehmen oder O behalten wählen.")
        return
    renderer.selected = cell
    generation += 1
    play_sound(board.winner != 0)
    if board.winner != 0:
        if tutorial == null and int(data.settings.mode) != 2: record_result()
        if not board.win_lines.is_empty(): focus_line(board.win_lines[0])
    refresh(cell)
func record_result() -> void:
    if board.result_recorded: return
    board.result_recorded = true
    data.stats.played += 1
    if bool(data.settings.alternate): data.settings.next_start = 1-board.starter_owner
    if board.winner == 3:
        data.stats.draw += 1
        data.stats.starter_draws += 1
    else:
        var owner = int(board.owners[board.winner-1])
        if owner == board.starter_owner: data.stats.starter_wins += 1
        else: data.stats.second_wins += 1
        data.stats["p1" if owner == 0 else "p2"] += 1
        if int(data.settings.mode) == 1:
            data.stats["ai_wins" if owner == 0 else "ai_losses"][int(data.settings.level)] += 1
func resolve_swap(accept: bool) -> void:
    if rules.swap(board,accept):
        generation += 1
        refresh()
func new_game() -> void:
    generation += 1
    board = BoardModel.new()
    board.swap_enabled = bool(data.settings.swap) and int(data.settings.mode) == 0
    board.starter_owner = int(data.settings.next_start) if bool(data.settings.alternate) else 0
    board.owners = [board.starter_owner,1-board.starter_owner]
    preview = []
    renderer.selected = -1
    renderer.reset_view()
    refresh()
func confirm_new() -> void:
    if tutorial != null:
        load_tutorial()
        return
    if board.move_count() == 0 or board.winner != 0:
        new_game()
        return
    var box = modal("Neue Partie?")
    label("Die laufende Partie wird verworfen. Abgeschlossene Ergebnisse bleiben erhalten.",box)
    button("Neu starten",box,func():
        close_modal()
        new_game()
    )
func undo() -> void:
    if tutorial != null:
        load_tutorial()
        return
    if board.result_recorded:
        notify_user("Abgeschlossene Ergebnisse bleiben erhalten. Starte eine neue Partie.")
        return
    generation += 1
    if rules.undo(board):
        if int(data.settings.mode) == 1:
            while not board.history.is_empty() and (board.current_owner() == 1 or board.swap_pending): rules.undo(board)
        preview = []
        renderer.selected = -1
        refresh()
func _process(_delta: float) -> void:
    if data == null: return
    if worker != null and not worker.is_alive():
        var move = worker.wait_to_finish()
        worker = null
        ai_running = false
        if worker_generation == generation and tutorial == null and board.winner == 0 and not board.swap_pending: place(int(move))
        else: refresh()
    if tutorial != null or int(data.settings.mode) != 1 or board.winner != 0: return
    if board.swap_pending:
        if board.current_owner() == 1: resolve_swap(true)
        else: return
    if worker == null and board.current_owner() == 1:
        worker = Thread.new()
        worker_generation = generation
        ai_running = true
        var cells = board.cells.duplicate()
        var player = board.turn
        var level = int(data.settings.level)
        var seed_value = int(Time.get_ticks_usec())
        worker.start(func(): return AIEngine.new(seed_value).choose(cells,player,level,220))
        refresh()
func _exit_tree() -> void:
    if worker != null: worker.wait_to_finish()
func modal(title: String) -> VBoxContainer:
    close_modal()
    popup = PanelContainer.new()
    popup.mouse_filter = Control.MOUSE_FILTER_STOP
    ui.add_child(popup)
    popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    popup.offset_left = 14
    popup.offset_right = -14
    popup.offset_top = 22
    popup.offset_bottom = -22
    popup.add_theme_stylebox_override("panel",theme_style(Color("fff2da",0.975),24))
    popup.modulate.a = 0.0
    popup.create_tween().tween_property(popup,"modulate:a",1.0,0.18)
    var scroll = ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.mouse_filter = Control.MOUSE_FILTER_STOP
    popup.add_child(scroll)
    var box = VBoxContainer.new()
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_theme_constant_override("separation",12)
    scroll.add_child(box)
    label(title,box,24,Color("453329"))
    button("Zurück zum Spiel",box,close_modal,true)
    return box
func close_modal() -> void:
    net_active = false
    net_buttons.clear()
    if popup != null:
        popup.queue_free()
        popup = null
func open_menu() -> void:
    var box = modal("Deine Zen-Pause")
    label("Wähle, wie du spielen möchtest. Kein Zeitdruck – nur Ruhe und Strategie.",box,15,Color("74614c"))
    button("Schnell starten  ·  gegen Zen-Bot",box,func(): start_mode(1,0),false,true)
    button("Gegen Bot spielen",box,func(): start_mode(1,int(data.settings.level)))
    button("Zwei Spieler lokal",box,func(): start_mode(0,0))
    button("Viererlinien lernen",box,start_tutorial)
    button("Freies Training",box,func(): start_mode(2,0))
    button("Einstellungen",box,open_settings)
    button("Deine Spielstatistik",box,open_stats)
    button("Regeln & Balance",box,open_balance)
    label("ZenCube 3D · 108 mögliche Viererlinien\nOffline · ohne Werbung · ohne Anmeldung",box,12)
func open_balance() -> void:
    var box = modal("Vier Steine. Zwei Seiten.")
    label("So gewinnt man",box,20,Color("7b886d"))
    label("Vier zusammenhängende X oder O über zwei benachbarte Seiten: 3+1, 2+2 oder 1+3.",box,15)
    add_rule_example(box,"3+1",3)
    add_rule_example(box,"2+2",2)
    label("Die Linie muss beim Aufklappen senkrecht zur gemeinsamen Kante verlaufen. Vier auf einer einzelnen Fläche oder über drei Seiten zählen nicht.",box,14)
    label("108 mögliche Gewinnlinien. Die Viererregel soll kurze Siege erschweren, mathematische Fairness ist noch nicht nachgewiesen. Wir wechseln das Startrecht zwischen Partien.",box,14)
func open_stats() -> void:
    var box = modal("Deine Partien")
    label(T("%d gespielt\n%d Siege für Spieler 1\n%d Siege für Spieler 2 / Computer\n%d Unentschieden") % [data.stats.played,data.stats.p1,data.stats.p2,data.stats.draw],box,20)
    label("STARTSPIELER / ZWEITSPIELER · SIEGE",box,12)
    label(T("%d / %d  ·  Unentschieden: %d") % [data.stats.starter_wins,data.stats.second_wins,data.stats.starter_draws],box,16)
    label("GEGEN DIE KI · SIEGE / NIEDERLAGEN",box,12)
    for i in range(3): label("%s: %d / %d" % [T(["Einfach","Mittel","Schwer"][i]),data.stats.ai_wins[i],data.stats.ai_losses[i]],box)
    label("Ergebnisse zählen die Spieleridentität auch nach einem Farbtausch. Training und Tutorial werden nicht gezählt. Abgeschlossene Partien können nicht rückgängig gemacht werden. Abgebrochene Partien zählen nicht.",box,14)
func open_help() -> void:
    var box = modal("Ein wenig Orientierung")
    var hints = CheckButton.new()
    hints.text = T("Unmittelbare Gewinnfelder markieren")
    hints.button_pressed = bool(data.settings.hints)
    hints.toggled.connect(func(v):
        data.settings.hints = v
        refresh()
    )
    box.add_child(hints)
    label("Salbei markiert eine mögliche Viererlinie für X, Terrakotta für O – jeweils mit drei bereits gesetzten Steinen.",box,14)
    button("Kamera zur nächsten Bedrohung",box,func():
        close_modal()
        for p in [1,2]:
            var threats = rules.threats(board.cells,p)
            for line in rules.lines:
                if not threats.is_empty() and line.has(threats[0]):
                    var count = 0
                    for c in line:
                        if board.cells[c] == p: count += 1
                    if count == 3:
                        focus_line(line)
                        return
        notify_user("Im Moment keine unmittelbare Bedrohung."))
    button("Seite gezielt ansehen",box,open_faces)
    if int(data.settings.mode) == 2 or tutorial != null:
        button("Nächste gültige Linie",box,func():
            preview_index = (preview_index+1)%rules.lines.size()
            preview = rules.lines[preview_index]
            close_modal()
            focus_line(preview)
            refresh()
        )
        button("Vorschau ausblenden",box,func():
            preview = []
            close_modal()
            refresh()
        )
    label("Tipp: 3+1 und 2+2 funktionieren nur auf zwei benachbarten Seiten und ohne übersprungene Felder.",box,14)
func focus_line(line: Array) -> void:
    var faces = []
    for c in line:
        var f = CubeGeometry.face(int(c))
        if not faces.has(f): faces.append(f)
    renderer.focus_faces(faces)
func focus_and_close(face: int) -> void:
    renderer.focus_faces([face])
    close_modal()
func open_faces() -> void:
    var box = modal("Seite wählen")
    for f in range(6):
        button(CubeGeometry.NAMES[f],box,focus_and_close.bind(f))
func open_net() -> void:
    var box = modal("Alle sechs Seiten")
    label("Alle Würfelseiten auf einen Blick. Tippe ein freies Feld, um zu setzen; der 3D-Würfel bleibt das Hauptspielfeld.",box,14)
    var grid = GridContainer.new()
    grid.columns = 4
    grid.add_theme_constant_override("h_separation",4)
    grid.add_theme_constant_override("v_separation",12)
    box.add_child(grid)
    for f in [-1,4,-1,-1,2,0,3,1,-1,5,-1,-1]:
        var group = VBoxContainer.new()
        group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        grid.add_child(group)
        if f < 0: continue
        label(CubeGeometry.NAMES[f],group,11)
        var cells = GridContainer.new()
        cells.columns = 3
        cells.add_theme_constant_override("h_separation",1)
        cells.add_theme_constant_override("v_separation",1)
        group.add_child(cells)
        for c in range(f*9,f*9+9):
            var b = Button.new()
            b.custom_minimum_size = Vector2(28,34)
            b.add_theme_font_size_override("font_size",14)
            var cell_style = theme_style(Color("e0cfb7"),4)
            cell_style.content_margin_left = 2
            cell_style.content_margin_right = 2
            b.add_theme_stylebox_override("normal",cell_style)
            b.pressed.connect(func(): on_cell(c))
            cells.add_child(b)
            net_buttons.append([b,c])
    net_active = true
    update_net()
func update_net() -> void:
    for pair in net_buttons:
        pair[0].text = ["·","X","O"][int(board.cells[pair[1]])]
        pair[0].add_theme_color_override("font_color", Color("453329") if board.cells[pair[1]] == 1 else Color("a75f43") if board.cells[pair[1]] == 2 else Color("74614c"))
func start_tutorial(onboarding: bool = false) -> void:
    close_modal()
    tutorial_from_welcome = onboarding
    if tutorial == null: saved_training = {"board":board.snapshot(),"history":board.history.duplicate(true)}
    generation += 1
    tutorial = TutorialController.new()
    board = BoardModel.new()
    load_tutorial()
func load_tutorial() -> void:
    preview = tutorial.setup(board,rules.lines)
    if preview.is_empty(): renderer.reset_view()
    else: focus_line(preview)
    refresh()
func tutorial_step(delta: int) -> void:
    if tutorial == null: return
    if tutorial.step + delta >= TutorialController.TEXTS.size():
        end_tutorial()
        return
    tutorial.step = clampi(tutorial.step+delta,0,TutorialController.TEXTS.size()-1)
    load_tutorial()
func end_tutorial() -> void:
    if tutorial == null: return
    tutorial = null
    generation += 1
    preview = []
    if tutorial_from_welcome:
        tutorial_from_welcome = false
        start_mode(1,0,true)
        return
    board = BoardModel.new()
    board.restore(saved_training.board)
    board.history = saved_training.history
    refresh()
func start_mode(mode: int, level: int = 0, from_welcome: bool = false) -> void:
    close_modal()
    if tutorial != null:
        tutorial = null
        preview = []
        tutorial_from_welcome = false
    data.settings.mode = mode
    data.settings.level = clampi(level,0,2)
    data.settings.intro_seen = true
    if from_welcome:
        data.settings.next_start = 0
    if mode == 1:
        data.settings.swap = false
    new_game()

func open_welcome() -> void:
    welcome_open = true
    var box = modal("Willkommen im Zen-Garten")
    popup.anchor_top = 0.35
    popup.offset_top = 0
    box.get_child(1).hide()
    label("Atme durch. Drehe den Würfel. Entdecke neue Wege zu gewinnen.",box,15,Color("6d6550"))
    label("VIER STEINE  ·  ZWEI WÜRFELSEITEN",box,13,Color("8a755b"))
    add_rule_example(box,"3 + 1",3)
    add_rule_example(box,"2 + 2",2)
    label("Ein Finger zieht den Würfel. Ein kurzes Tippen setzt deinen Stein. Erreiche vier verbundene Felder über zwei benachbarte Würfelseiten.",box,14)
    button("Mini-Tutorial starten",box,func(): start_tutorial(true),false,true)
    button("Direkt gegen Zen-Bot spielen",box,func(): start_mode(1,0,true))
    label("Dein erster Gegner ist Zen-Bot auf Leicht. Lokale Zwei-Spieler-Partien sind später im Menü verfügbar.",box,13,Color("78644c"))

func add_rule_example(parent: Node, caption_text: String, left_marks: int) -> void:
    var panel = PanelContainer.new()
    panel.add_theme_stylebox_override("panel",theme_style(Color("f0e6d5"),16))
    parent.add_child(panel)
    var stack = VBoxContainer.new()
    panel.add_child(stack)
    label(caption_text+T("  ·  eine Gewinnlinie"),stack,16,Color("483729"))
    var surfaces = HBoxContainer.new()
    surfaces.add_theme_constant_override("separation",4)
    stack.add_child(surfaces)
    for face in range(2):
        var side = VBoxContainer.new()
        side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        surfaces.add_child(side)
        label("SEITE A" if face == 0 else "SEITE B",side,11,Color("806c54"))
        var cells = GridContainer.new()
        cells.columns = 3
        cells.add_theme_constant_override("h_separation",2)
        cells.add_theme_constant_override("v_separation",2)
        side.add_child(cells)
        for r in range(3):
            for col in range(3):
                var marked := r == 1 and ((face == 0 and col >= 3-left_marks) or (face == 1 and col < 4-left_marks))
                var tile = PanelContainer.new()
                tile.custom_minimum_size = Vector2(28,28)
                tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
                tile.add_theme_stylebox_override("panel",theme_style(Color("d2bda2") if marked else Color("e7d9c5"),5))
                cells.add_child(tile)
                if marked:
                    var token = Label.new()
                    token.text = "X"
                    token.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                    token.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
                    token.add_theme_color_override("font_color",Color("4b3629"))
                    token.add_theme_font_size_override("font_size",16)
                    tile.add_child(token)
    label("Im Würfel verbunden – hier aufgeklappt gezeigt.",stack,11,Color("7e684f"))

func open_settings() -> void:
    var box = modal("Deine Einstellungen")
    label("Spiele in deinem Tempo.",box,15,Color("806c54"))
    label("Sprache / Language",box,15)
    var language_picker = OptionButton.new()
    language_picker.custom_minimum_size.y = 52
    language_picker.add_item("Deutsch", 0)
    language_picker.add_item("English", 1)
    language_picker.select(1 if language_code() == "en" else 0)
    language_picker.item_selected.connect(func(index): change_language("en" if index == 1 else "de"))
    box.add_child(language_picker)
    var level = OptionButton.new()
    for title in ["Bot: Leicht","Bot: Mittel","Bot: Schwer"]: level.add_item(T(title))
    level.selected = int(data.settings.level)
    level.custom_minimum_size.y = 52
    level.item_selected.connect(func(index):
        data.settings.level = index
        persist()
    )
    box.add_child(level)
    var music = CheckButton.new()
    music.text = T("Ruhige Zen-Garten-Musik")
    music.button_pressed = bool(data.settings.get("music",false))
    music.toggled.connect(func(enabled):
        data.settings.music = enabled
        sync_music()
        persist()
    )
    box.add_child(music)
    var sounds = CheckButton.new()
    sounds.text = T("Sanfte Spieltöne")
    sounds.button_pressed = bool(data.settings.sound)
    sounds.toggled.connect(func(enabled):
        data.settings.sound = enabled
        persist()
    )
    box.add_child(sounds)
    var hints = CheckButton.new()
    hints.text = T("Gewinnfelder als Hilfe zeigen")
    hints.button_pressed = bool(data.settings.hints)
    hints.toggled.connect(func(enabled):
        data.settings.hints = enabled
        refresh()
    )
    box.add_child(hints)
    var alternate = CheckButton.new()
    alternate.text = T("Startspieler nach jeder Runde wechseln")
    alternate.button_pressed = bool(data.settings.alternate)
    alternate.toggled.connect(func(enabled):
        data.settings.alternate = enabled
        persist()
    )
    box.add_child(alternate)
    var swap = CheckButton.new()
    swap.text = T("Farbtausch erlauben (nur lokaler Modus)")
    swap.button_pressed = bool(data.settings.swap)
    swap.toggled.connect(func(enabled):
        data.settings.swap = enabled
        persist()
    )
    box.add_child(swap)
    button("Musikprobe abspielen",box,music_preview)
    button("Fertig",box,close_modal,false,true)

func build_sound() -> void:
    sound_player = AudioStreamPlayer.new()
    add_child(sound_player)
    var wave = AudioStreamWAV.new()
    wave.format = AudioStreamWAV.FORMAT_16_BITS
    wave.mix_rate = 22050
    var samples = PackedByteArray()
    samples.resize(4410*2)
    for i in range(4410):
        var t = float(i)/22050.0
        var value = int(sin(t*TAU*520)*exp(-t*26)*minf(t*100,1)*7000)
        samples.encode_s16(i*2,value)
    wave.data = samples
    sound_player.stream = wave
    sound_player.volume_db = -9
    music_player = AudioStreamPlayer.new()
    add_child(music_player)
    var ambient = load("res://assets/zen_ambient.wav") as AudioStreamWAV
    if ambient != null:
        ambient.loop_mode = AudioStreamWAV.LOOP_FORWARD
        music_player.stream = ambient
    music_player.volume_db = -12
    sync_music()
func music_preview() -> void:
    if music_player == null or music_player.stream == null:
        notify_user("Musik konnte nicht geladen werden.")
        return
    music_player.play()
    if not bool(data.settings.get("music", false)):
        get_tree().create_timer(6.0).timeout.connect(func():
            if is_instance_valid(music_player) and not bool(data.settings.get("music", false)):
                music_player.stop()
        )
func sync_music() -> void:
    if music_player == null or music_player.stream == null: return
    if bool(data.settings.get("music",false)):
        if not music_player.playing: music_player.play()
    elif music_player.playing:
        music_player.stop()
func play_sound(win: bool) -> void:
    if not bool(data.settings.sound): return
    sound_player.pitch_scale = 1.5 if win else 1.0
    sound_player.play()
