extends Node3D
# Standalone 4x4 scene so no Classic board, AI or rules are replaced.
const Mode = preload("res://core/ZenAscend.gd")
const Locale = preload("res://core/ZenLocalization.gd")
var data: Dictionary = {}
var lines: Array = []
var cells: Array = []
var turn: int = 1
var owners: Array = [0,1]
var result: int = 0
var recorded: bool = false
var against_bot: bool = true
var busy: bool = false
var cube: AscendRenderer
var vp: SubViewport
var cube_surface: TextureRect
var status_label: Label
var details_label: Label
var rank_label: Label
var instructions: Label
var layer: Control
var menu_dialog: ConfirmationDialog
var touch_positions: Dictionary = {}
var touch_down: Vector2 = Vector2.ZERO
var touched_cell: int = -1
var dragged: bool = false
var mouse_pressed: bool = false
var heard_touch: bool = false

func lang() -> String:
    return str(data.get("settings",{}).get("language","de"))
func Z(source: String) -> String:
    return Mode.t(source,lang())
func _ready() -> void:
    data = SaveManager.load_data()
    ZenAscension.ensure(data)
    ZenCollection.ensure(data)
    Mode.ensure(data)
    if not Mode.unlocked(data):
        get_tree().call_deferred("change_scene_to_file","res://Main.tscn")
        return
    lines = Mode.generate_lines()
    if lines.size() != 204:
        push_error("Zen Ascend: expected 204 win lines, got " + str(lines.size()))
        return_home()
        return
    cells.resize(Mode.CELLS)
    cells.fill(0)
    vp = SubViewport.new()
    vp.size = Vector2i(960,960)
    vp.transparent_bg = true
    vp.own_world_3d = true
    vp.msaa_3d = Viewport.MSAA_4X
    vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(vp)
    cube = AscendRenderer.new()
    vp.add_child(cube)
    build_interface()
    cube.set_skin(int(data.economy.get("equipped",0)))
    draw()
    # The explanation is guaranteed on first entry, including in the test build.
    if not bool(data.ascend.help_seen):
        data.ascend.help_seen = true
        SaveManager.save_data(data)
        call_deferred("show_rules")
    else:
        call_deferred("show_mode_picker")

func style(color: Color, radius: int = 17) -> StyleBoxFlat:
    var box: StyleBoxFlat = StyleBoxFlat.new()
    box.bg_color = color
    box.border_color = Color("c49f65",0.8)
    box.set_border_width_all(2)
    box.set_corner_radius_all(radius)
    box.set_content_margin_all(11.0)
    return box
func text(parent: Node, value: String, size: int = 16, color: Color = Color("ead8b9")) -> Label:
    var label_node: Label = Label.new()
    label_node.text = value
    label_node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label_node.add_theme_font_size_override("font_size",size)
    label_node.add_theme_color_override("font_color",color)
    label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    parent.add_child(label_node)
    return label_node
func action(parent: Node, value: String, fn: Callable, primary: bool = false) -> Button:
    var b: Button = Button.new()
    b.text = value
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.custom_minimum_size.y = 54
    b.add_theme_stylebox_override("normal",style(Color("4e674f") if primary else Color("ead8bb")))
    b.add_theme_stylebox_override("pressed",style(Color("5d774f")))
    b.add_theme_stylebox_override("hover",style(Color("729073") if primary else Color("f2e5d0")))
    var fc: Color = Color("fff9e7") if primary else Color("3d3028")
    for kind in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
        b.add_theme_color_override(kind, fc)
    b.pressed.connect(fn)
    parent.add_child(b)
    return b

func build_interface() -> void:
    var canvas: CanvasLayer = CanvasLayer.new()
    canvas.layer = 2
    add_child(canvas)
    layer = Control.new()
    canvas.add_child(layer)
    layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var backdrop: TextureRect = TextureRect.new()
    backdrop.texture = ZenAscension.WORLD_TEXTURES[clampi(int(data.ascension.world),0,4)]
    backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(backdrop)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shade: ColorRect = ColorRect.new()
    shade.color = Color("241f1a",0.24)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(shade)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var margin: MarginContainer = MarginContainer.new()
    layer.add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left",12)
    margin.add_theme_constant_override("margin_right",12)
    margin.add_theme_constant_override("margin_top",18)
    margin.add_theme_constant_override("margin_bottom",18)
    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation",8)
    margin.add_child(column)
    var header: PanelContainer = PanelContainer.new()
    header.add_theme_stylebox_override("panel",style(Color("392a25",0.96),22))
    column.add_child(header)
    var title_box: VBoxContainer = VBoxContainer.new()
    header.add_child(title_box)
    text(title_box,Z("Zen Ascend 4×4"),25,Color("f9e7b7"))
    rank_label = text(title_box,"",13,Color("c5d6bd"))
    var scoreboard: PanelContainer = PanelContainer.new()
    scoreboard.add_theme_stylebox_override("panel",style(Color("fff1d9",0.95)))
    column.add_child(scoreboard)
    var score_box: VBoxContainer = VBoxContainer.new()
    scoreboard.add_child(score_box)
    status_label = text(score_box,"",17,Color("473b2d"))
    details_label = text(score_box,"",13,Color("6f6254"))
    var cube_card: PanelContainer = PanelContainer.new()
    cube_card.add_theme_stylebox_override("panel",style(Color("e7dac7",0.06),24))
    cube_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(cube_card)
    cube_surface = TextureRect.new()
    cube_surface.texture = vp.get_texture()
    cube_surface.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    cube_surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    cube_surface.mouse_filter = Control.MOUSE_FILTER_STOP
    cube_surface.custom_minimum_size.y = 290
    cube_surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
    cube_surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cube_card.add_child(cube_surface)
    cube_surface.gui_input.connect(cube_input)
    var tip: PanelContainer = PanelContainer.new()
    tip.add_theme_stylebox_override("panel",style(Color("302820",0.96),13))
    column.add_child(tip)
    instructions = text(tip,Z("Ziehen: drehen · Tippen: setzen · Zwei Finger: zoomen"),13)
    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override("separation",6)
    column.add_child(row)
    action(row,Z("Neue Partie"),show_mode_picker)
    action(row,Z("Regeln ansehen"),show_rules)
    var footer: HBoxContainer = HBoxContainer.new()
    footer.add_theme_constant_override("separation",6)
    column.add_child(footer)
    action(footer,Z("Statistik & Rang"),show_statistics)
    action(footer,Z("Hauptmenü"),return_home,true)

func pname(owner: int) -> String:
    if against_bot and owner == 1: return "Zen-Bot"
    var names: Array = data.settings.names
    return str(names[clampi(owner,0,1)])
func move_count() -> int:
    return Mode.CELLS - cells.count(0)
func draw() -> void:
    if cube == null: return
    var wins: Array = []
    if result in [1,2]:
        for line in Mode.winning_lines(cells,lines,result):
            for c in line:
                if not wins.has(c): wins.append(c)
    cube.repaint(cells,wins)
    rank_label.text = Z("Zen-Rang")+": "+Locale.translate(str(ZenAscension.RANKS[int(data.ascension.rank)]),lang())
    if result == 3:
        status_label.text = Z("Unentschieden!")
    elif result > 0:
        if against_bot and result == 2:
            status_label.text = Z("Zen-Bot hat gewonnen!")
        else:
            status_label.text = pname(int(owners[result-1]))+" "+Z("hat gewonnen!")
    elif busy:
        status_label.text = Z("Zen-Bot überlegt …")
    else:
        status_label.text = pname(int(owners[turn-1]))+" · "+Z("Du bist am Zug")+" · "+("X" if turn==1 else "O")
    details_label.text = "%s X  ·  %s O  ·  %d/96" % [pname(int(owners[0])),pname(int(owners[1])),move_count()]

func _pick_position(pos: Vector2) -> int:
    if cube_surface == null or cube == null: return -1
    var square: float = minf(cube_surface.size.x,cube_surface.size.y)
    if square < 1.0: return -1
    var offset: Vector2 = (cube_surface.size - Vector2(square,square))*0.5
    var inside: Vector2 = (pos-offset) / square
    if inside.x < 0.0 or inside.x >= 1.0 or inside.y < 0.0 or inside.y >= 1.0: return -1
    return cube.pick(inside * 960.0)

func cube_input(event: InputEvent) -> void:
    if result != 0 or busy: return
    if event is InputEventScreenTouch:
        heard_touch = true
        if event.pressed:
            touch_positions[event.index] = event.position
            if touch_positions.size() == 1:
                touch_down = event.position
                touched_cell = _pick_position(event.position)
                dragged = false
            else: dragged = true
        else:
            var single: bool = touch_positions.size() == 1
            if single and not dragged and event.position.distance_to(touch_down) < 13.0:
                var end_cell: int = _pick_position(event.position)
                if touched_cell >= 0 and touched_cell == end_cell: play(end_cell)
            touch_positions.erase(event.index)
            if touch_positions.is_empty(): touched_cell = -1
    elif event is InputEventScreenDrag:
        heard_touch = true
        if touch_positions.size() >= 2:
            var keys: Array = touch_positions.keys()
            var first_before: Vector2 = touch_positions[keys[0]]
            var second_before: Vector2 = touch_positions[keys[1]]
            var before: float = first_before.distance_to(second_before)
            touch_positions[event.index] = event.position
            var first_after: Vector2 = touch_positions[keys[0]]
            var second_after: Vector2 = touch_positions[keys[1]]
            var after: float = first_after.distance_to(second_after)
            if before > 4.0 and after > 4.0: cube.zoom(before/after)
            dragged = true
        elif touch_positions.size() == 1:
            touch_positions[event.index] = event.position
            if event.position.distance_to(touch_down) > 12.0: dragged = true
            if dragged: cube.rotate_cube(event.relative)
    elif event is InputEventMouseButton:
        if heard_touch or OS.get_name() == "Android": return
        if event.button_index == MOUSE_BUTTON_WHEEL_UP: cube.zoom(0.93)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: cube.zoom(1.07)
        elif event.button_index == MOUSE_BUTTON_LEFT:
            mouse_pressed = event.pressed
            if event.pressed:
                touch_down = event.position
                touched_cell = _pick_position(event.position)
                dragged = false
            elif not dragged and event.position.distance_to(touch_down) < 13.0:
                var end_cell: int = _pick_position(event.position)
                if touched_cell >= 0 and touched_cell == end_cell: play(end_cell)
    elif event is InputEventMouseMotion and mouse_pressed and not heard_touch:
        if event.position.distance_to(touch_down) > 12.0: dragged = true
        if dragged: cube.rotate_cube(event.relative)

func start_game(bot: bool) -> void:
    against_bot = bot
    cells.fill(0)
    result = 0
    recorded = false
    turn = 1
    owners = [0,1] if bot else [int(data.ascend.next_start),1-int(data.ascend.next_start)]
    busy = false
    cube.reset_view()
    draw()

func play(cell: int) -> void:
    if result != 0 or busy or cell < 0 or cell >= Mode.CELLS or int(cells[cell]) != 0: return
    if against_bot and turn == 2: return
    _commit(cell)
    if against_bot and result == 0 and turn == 2:
        busy = true
        draw()
        call_deferred("bot_turn")
func _commit(cell: int) -> void:
    cells[cell] = turn
    var complete: Array = Mode.winning_lines(cells,lines,turn)
    if not complete.is_empty(): result = turn
    elif not cells.has(0): result = 3
    if result == 0: turn = 3-turn
    else: finish()
    draw()

func bot_turn() -> void:
    await get_tree().create_timer(0.26).timeout
    if not is_inside_tree() or result != 0 or not against_bot: return
    var cell: int = Mode.next_move(cells,lines,2)
    busy = false
    if cell >= 0: _commit(cell)
    draw()

func finish() -> void:
    if recorded: return
    recorded = true
    Mode.ensure(data)
    data.ascend.played += 1
    data.ascend.moves += move_count()
    if against_bot: data.ascend.bot_played += 1
    else: data.ascend.local_played += 1
    if result == 3:
        data.ascend.draw += 1
        data.ascend.current_streak = 0
    else:
        var owner: int = int(owners[result-1])
        if owner == 0: data.ascend.p1 += 1
        else: data.ascend.p2 += 1
        if against_bot:
            if owner == 0:
                data.ascend.bot_wins += 1
                data.ascend.current_streak += 1
                data.ascend.best_streak = maxi(int(data.ascend.best_streak),int(data.ascend.current_streak))
                if int(data.ascend.fastest_win) == 0 or move_count() < int(data.ascend.fastest_win):
                    data.ascend.fastest_win = move_count()
                ZenCollection.reward_bot(data,0)
            else:
                data.ascend.bot_losses += 1
                data.ascend.current_streak = 0
        else:
            data.ascend.current_streak = 0
    if not against_bot: data.ascend.next_start = 1-int(data.ascend.next_start)
    SaveManager.save_data(data)

func _dialog(title: String, message: String) -> AcceptDialog:
    var dialog: AcceptDialog = AcceptDialog.new()
    dialog.title = title
    dialog.dialog_text = message
    dialog.dialog_autowrap = true
    dialog.min_size = Vector2i(400,300)
    dialog.get_ok_button().text = Z("Zurück")
    layer.add_child(dialog)
    dialog.confirmed.connect(dialog.queue_free)
    dialog.canceled.connect(dialog.queue_free)
    dialog.popup_centered()
    return dialog

func show_rules() -> void:
    var msg: String = Z("Neuer Modus: 6 Seiten mit je 4×4 Feldern (96 Felder).")+"\n\n"+Z("Gewinne mit vier X oder O in einer Reihe: waagerecht, senkrecht oder diagonal auf einer Fläche ODER gerade über eine Würfelkante (1+3, 2+2, 3+1).")+"\n\n"+Z("204 mögliche Gewinnlinien. Die klassische 3×3-Version bleibt unverändert.")
    var dialog: AcceptDialog = _dialog(Z("Zen Ascend 4×4"),msg)
    dialog.confirmed.connect(show_mode_picker)

func show_mode_picker() -> void:
    var dialog: ConfirmationDialog = ConfirmationDialog.new()
    dialog.title = Z("Zen Ascend 4×4")
    dialog.dialog_text = Z("Gegen Zen-Bot")+" (X)  /  "+Z("Zu zweit spielen")+" (X / O)"
    dialog.min_size = Vector2i(400,260)
    dialog.get_ok_button().text = Z("Gegen Zen-Bot")
    dialog.get_cancel_button().text = Z("Zu zweit spielen")
    layer.add_child(dialog)
    dialog.confirmed.connect(func():
        start_game(true)
        dialog.queue_free()
    )
    dialog.canceled.connect(func():
        start_game(false)
        dialog.queue_free()
    )
    dialog.popup_centered()

func show_statistics() -> void:
    Mode.ensure(data)
    var s: Dictionary = data.ascend
    var total: int = int(s.played)
    var rate: float = 100.0*float(s.bot_wins)/float(maxi(1,int(s.bot_played)))
    var avg: float = float(s.moves)/float(maxi(1,total))
    var message: String = "%s: %s\n\n%s: %d   ·   %s: %d   ·   %s: %d\n%s: %d   ·   %s: %d\n%s: %.1f%%   ·   %s: %d\n%s: %d   ·   %s: %d\n%s: %.1f   ·   %s: %d" % [
        Z("Zen-Rang"),Locale.translate(str(ZenAscension.RANKS[int(data.ascension.rank)]),lang()),
        Z("Partien"),total,Z("Siege"),int(s.p1),Z("Unentschieden"),int(s.draw),
        Z("4×4 gegen Bot"),int(s.bot_played),Z("4×4 zu zweit"),int(s.local_played),
        Z("Siegquote"),rate,Z("Beste Siegesserie"),int(s.best_streak),
        Z("Aktuelle Siegesserie"),int(s.current_streak),Z("Züge gesamt"),int(s.moves),
        Z("Züge pro Partie"),avg,Z("Schnellster Sieg"),int(s.fastest_win)]
    _dialog(Z("Statistik & Rang"),message)

func return_home() -> void:
    if get_tree() != null: get_tree().change_scene_to_file("res://Main.tscn")
