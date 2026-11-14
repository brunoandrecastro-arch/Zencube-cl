extends Node3D
# Standalone 4x4 scene so no Classic board, AI or rules are replaced.
const Mode = preload("res://core/ZenAscend.gd")
const BotAuto = preload("res://core/ZenBotAutoLevel.gd")
const Locale = preload("res://core/ZenLocalization.gd")
const MusicPolicy = preload("res://core/ZenMusicPolicy.gd")
const WorldMusic = preload("res://core/ZenWorldMusic.gd")
const RealmMusic = preload("res://core/ZenRealmMusic.gd")
const FullyAware = preload("res://ui/ZenFullyAwareCeremony.gd")
const Achievements = preload("res://core/ZenAscendAchievements.gd")
const UnlockCeremony = preload("res://ui/ZenUnlockCeremony.gd")
const RealmPortal = preload("res://ui/ZenRealmTravelCeremony.gd")
const Realms = preload("res://core/ZenAscendRealms.gd")
const RealmBot = preload("res://core/ZenAscendRealmBot.gd")
# ZENCUBE WORLD MUSIC PATCH 1
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
var quote_label: Label
var instructions: Label
var layer: Control
var menu_dialog: ConfirmationDialog
var world_music: AudioStreamPlayer
var realm_music_fade: AudioStreamPlayer
var realm_music_tween: Tween
var realm_backdrop: TextureRect
var match_realm: int = 0
var match_blocked_threat: bool = false
var bot_level: int = 1
var last_realm_awards: Dictionary = {}
var last_match_leaf_reward: int = 0
var queued_unlocks: Array = []
var pending_fully_aware: bool = false
var move_sound: AudioStreamPlayer
var win_sound: AudioStreamPlayer
var active_realm_dialog: Control
var active_realm_scroll: ScrollContainer
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
    Realms.ensure(data)
    Achievements.ensure(data)
    match_realm = int(data.ascend.realm_state.selected)
    # Older versions unlocked later Realms early. Restore a legal selection
    # without deleting statistics, achievements, bought hints or Zen Leaves.
    var previous_selection: int = match_realm
    while match_realm > 0 and not Realms.unlocked(data,match_realm):
        match_realm -= 1
    if previous_selection != match_realm:
        Realms.state(data)["selected"] = match_realm
        SaveManager.save_data(data)
    # Restore the correct fixed bot after the legacy selection is validated.
    bot_level = Realms.fixed_bot_level(match_realm)
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
    build_feedback_audio()
    cube.set_skin(int(data.economy.get("equipped",0)))
    start_world_music()
    draw()
    # The explanation is guaranteed on first entry, including in the test build.
    if not bool(data.ascend.help_seen):
        data.ascend.help_seen = true
        SaveManager.save_data(data)
        call_deferred("show_rules")
    else:
        call_deferred("show_mode_picker")

# Existing shop IDs 0..13 always remain unchanged. In Base mode 4x4 uses
# its own realm soundtrack; a manually owned track overrides it everywhere.
func desired_realm_stream() -> AudioStream:
    if MusicPolicy.mode(data) == "base":
        return RealmMusic.stream_for(realm_index())
    var selected: int = MusicPolicy.selected_track(data)
    return WorldMusic.stream_for(selected)

func start_world_music() -> void:
    sync_realm_music(true)

func sync_realm_music(initial: bool = false) -> void:
    if not bool(data.settings.get("music", false)):
        if realm_music_tween != null and realm_music_tween.is_running():
            realm_music_tween.kill()
        if is_instance_valid(world_music): world_music.stop()
        if is_instance_valid(realm_music_fade): realm_music_fade.stop()
        return
    var song: AudioStream = desired_realm_stream()
    if song == null:
        push_warning("Zen Ascend: realm soundtrack missing")
        return
    if world_music != null and world_music.stream == song:
        if not world_music.playing: world_music.play()
        return
    if realm_music_tween != null and realm_music_tween.is_running():
        realm_music_tween.kill()
    if is_instance_valid(realm_music_fade):
        realm_music_fade.stop()
        realm_music_fade.queue_free()
        realm_music_fade = null
    var incoming: AudioStreamPlayer = AudioStreamPlayer.new()
    incoming.name = "ZenAscendRealmMusic"
    incoming.stream = song
    incoming.volume_db = -48.0
    add_child(incoming)
    incoming.play()
    if world_music != null and world_music.playing and not initial:
        var outgoing: AudioStreamPlayer = world_music
        world_music = incoming
        realm_music_fade = outgoing
        realm_music_tween = create_tween().set_parallel(true)
        realm_music_tween.tween_property(incoming, "volume_db", -2.0, 1.8)
        realm_music_tween.tween_property(outgoing, "volume_db", -48.0, 1.8)
        realm_music_tween.finished.connect(func():
            if is_instance_valid(outgoing):
                outgoing.stop()
                outgoing.queue_free()
            if realm_music_fade == outgoing: realm_music_fade = null
        )
    else:
        if is_instance_valid(world_music):
            world_music.stop()
            world_music.queue_free()
        world_music = incoming
        incoming.volume_db = -2.0

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
    label_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
    b.mouse_filter = Control.MOUSE_FILTER_PASS
    b.pressed.connect(fn)
    parent.add_child(b)
    return b

# Soft original placement tone and a calm victory chime, same settings as Classic.
func _feedback_stream(frequency: float, seconds: float, volume: float) -> AudioStreamWAV:
    var sound: AudioStreamWAV = AudioStreamWAV.new()
    sound.format = AudioStreamWAV.FORMAT_16_BITS
    sound.mix_rate = 22050
    var frames: int = int(22050.0 * seconds)
    var bytes: PackedByteArray = PackedByteArray()
    bytes.resize(frames * 2)
    for n in range(frames):
        var t: float = float(n) / 22050.0
        var envelope: float = minf(1.0, t * 90.0) * exp(-t * 18.0)
        var sample: int = int(sin(t * TAU * frequency) * envelope * volume)
        bytes.encode_s16(n * 2, sample)
    sound.data = bytes
    return sound

func build_feedback_audio() -> void:
    move_sound = AudioStreamPlayer.new()
    move_sound.stream = _feedback_stream(520.0, 0.19, 7000.0)
    move_sound.volume_db = -4.5
    add_child(move_sound)
    win_sound = AudioStreamPlayer.new()
    win_sound.stream = _feedback_stream(784.0, 0.30, 6800.0)
    win_sound.volume_db = -3.0
    add_child(win_sound)

func feedback_on_place(human_move: bool, won: bool) -> void:
    if bool(data.settings.get("sound", true)):
        if move_sound != null:
            move_sound.stop()
            move_sound.play()
        if won and win_sound != null:
            win_sound.stop()
            win_sound.play()
    if human_move and bool(data.settings.get("haptics", true)) and OS.get_name() == "Android":
        Input.vibrate_handheld(80 if won else 28)

# Scroll touch events from inside custom realm cards reliably on Android.
func _input(event: InputEvent) -> void:
    if active_realm_scroll == null or not is_instance_valid(active_realm_scroll): return
    if event is InputEventScreenDrag and active_realm_scroll.get_global_rect().has_point(event.position):
        active_realm_scroll.scroll_vertical = maxi(0, active_realm_scroll.scroll_vertical - int(event.relative.y))

func _close_realm_dialog(dialog: Control) -> void:
    if active_realm_dialog == dialog:
        active_realm_dialog = null
        active_realm_scroll = null
    if is_instance_valid(dialog): dialog.queue_free()

func _realm_tone(index: int) -> Color:
    var colors: Array[Color] = [Color("1b2a3a"), Color("362421"), Color("192f3f"), Color("19352d")]
    return colors[clampi(index,0,3)]

func build_interface() -> void:
    var canvas: CanvasLayer = CanvasLayer.new()
    canvas.layer = 2
    add_child(canvas)
    layer = Control.new()
    canvas.add_child(layer)
    layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var backdrop: TextureRect = TextureRect.new()
    realm_backdrop = backdrop
    backdrop.texture = load(Realms.REALM_ART[realm_index()])
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
    var header_row: HBoxContainer = HBoxContainer.new()
    header_row.add_theme_constant_override("separation",8)
    header.add_child(header_row)
    var menu_button: Button = action(header_row,"☰",show_ascend_menu)
    menu_button.custom_minimum_size = Vector2(50,54)
    menu_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    menu_button.tooltip_text = "Zen Ascend menu"
    var title_box: VBoxContainer = VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header_row.add_child(title_box)
    rank_label = text(title_box,"",27,Color("f9e7b7"))
    text(title_box,Z("Zen Ascend 4×4"),18,Color("e8d1a9"))
    text(title_box,L("subtitle"),12,Color("d6bfa4"))
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
    var realm_actions: HBoxContainer = HBoxContainer.new()
    realm_actions.add_theme_constant_override("separation",6)
    column.add_child(realm_actions)
    action(realm_actions,L("realms"),show_realms)
    action(realm_actions,L("challenges"),show_challenges,true)
    action(realm_actions,_achievements_label(),show_realm_titles)
    var quote_box: PanelContainer = PanelContainer.new()
    quote_box.add_theme_stylebox_override("panel",style(Color("302820",0.94),13))
    column.add_child(quote_box)
    quote_label = text(quote_box,"",12,Color("f4dfbd"))

func realm_quote() -> String:
    var index: int = realm_index()
    var en: Array[String] = [
        "Even the deepest shadow can reveal a path.",
        "A steady mind outlasts the brightest flame.",
        "Above the clouds, calm opens the way forward.",
        "In stillness, every move finds its meaning."
    ]
    var de: Array[String] = [
        "Auch der tiefste Schatten kann einen Weg zeigen.",
        "Ein ruhiger Geist überdauert jede Flamme.",
        "Über den Wolken öffnet Gelassenheit neue Wege.",
        "In der Stille erhält jeder Zug Bedeutung."
    ]
    var pt: Array[String] = [
        "Até a sombra mais profunda pode revelar um caminho.",
        "Uma mente serena resiste à chama mais forte.",
        "Acima das nuvens, a calma abre o caminho.",
        "Na quietude, cada jogada ganha sentido."
    ]
    var pool: Array[String] = de if lang() == "de" else (pt if lang() == "pt" else en)
    return "“" + pool[index] + "”"

func _bot_difficulty_name() -> String:
    var levels: Array[String] = ["Leicht", "Mittel", "Schwer", "Meister", "Großmeister"]
    return Locale.translate(levels[clampi(bot_level,0,4)],lang())

func zen_ascend_bot_name() -> String:
    return "Zen Ascend Bot · " + _bot_difficulty_name()

func show_ascend_menu() -> void:
    var parts: Dictionary = _realm_dialog("Zen Ascend · Menu",520)
    var body: VBoxContainer = parts.box
    action(body,Z("Neue Partie"),show_mode_picker,true)
    action(body,Z("Statistik & Rang"),show_statistics)
    action(body,Z("Regeln ansehen"),show_rules)
    action(body,L("realms"),show_realms)
    action(body,L("challenges"),show_challenges)
    action(body,_achievements_label(),show_realm_titles)
    action(body,Z("Hauptmenü"),return_home)
    _open_realm_dialog(parts)

func pname(owner: int) -> String:
    if against_bot and owner == 1: return zen_ascend_bot_name()
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
    rank_label.text = Realms.realm_name(realm_index(),lang())
    if quote_label != null: quote_label.text = realm_quote()
    if result == 3:
        status_label.text = Z("Unentschieden!")
    elif result > 0:
        if against_bot and result == 2:
            status_label.text = zen_ascend_bot_name() + " · " + Z("hat gewonnen!")
        else:
            status_label.text = pname(int(owners[result-1]))+" "+Z("hat gewonnen!")
    elif busy:
        status_label.text = zen_ascend_bot_name() + " · " + Z("überlegt …")
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

func start_game(bot: bool, level: int = -1) -> void:
    against_bot = bot
    # Explicit level choices never override fixed Realm difficulty.
    match_realm = realm_index()
    bot_level = Realms.fixed_bot_level(match_realm)
    match_blocked_threat = false
    last_realm_awards = {}
    last_match_leaf_reward = 0
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
    if against_bot and turn == 1 and Realms.prevents_immediate_win(cells,lines,turn,cell):
        match_blocked_threat = true
    var human_move: bool = not against_bot or turn == 1
    cells[cell] = turn
    var complete: Array = Mode.winning_lines(cells,lines,turn)
    if not complete.is_empty(): result = turn
    elif not cells.has(0): result = 3
    feedback_on_place(human_move, result in [1,2])
    if result == 0: turn = 3-turn
    else: finish()
    draw()

func bot_turn() -> void:
    await get_tree().create_timer(0.26).timeout
    if not is_inside_tree() or result != 0 or not against_bot: return
    var cell: int = RealmBot.next_move(cells,lines,2,bot_level,match_realm == 0)
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
                last_match_leaf_reward = ZenCollection.reward_bot(data,bot_level)
            else:
                data.ascend.bot_losses += 1
                data.ascend.current_streak = 0
                last_match_leaf_reward = ZenCollection.reward_loss(data)
        else:
            data.ascend.current_streak = 0
    var celebrate_fully_aware: bool = false
    pending_fully_aware = false
    queued_unlocks.clear()
    if against_bot:
        var outcome: int = 0
        if result != 3: outcome = 1 if int(owners[result-1]) == 0 else -1
        var lines_won: Array = Mode.winning_lines(cells,lines,result) if outcome == 1 else []
        last_realm_awards = Realms.record_bot_match(data,match_realm,outcome,bot_level,move_count(),lines_won,match_blocked_threat)
        for secret in Achievements.claim_after_match(data,match_realm):
            queued_unlocks.append({"kind":"achievement","realm":match_realm,"name":str(secret.name),"quote":str(secret.quote)})
        if bool(last_realm_awards.get("realm_completed",false)):
            queued_unlocks.append({"kind":"achievement","realm":match_realm,"name":Achievements.MAIN_TITLES[match_realm],"quote":Achievements.main_quote(match_realm)})
        # Realm access may unlock earlier, but AUTOMATIC travel requires all 8
        # challenges completed in the current Realm. Once-only persisted gate.
        if match_realm < 3 and Realms.count(data,match_realm) == 8 and Realms.unlocked(data,match_realm+1):
            var journey: Dictionary = Realms.state(data)
            if not journey.get("auto_transitions") is Dictionary:
                journey["auto_transitions"] = {}
            if not bool(journey.auto_transitions.get(str(match_realm),false)):
                journey.auto_transitions[str(match_realm)] = true
                var destination: int = match_realm + 1
                queued_unlocks.push_front({"kind":"realm","realm":destination,"name":Realms.REALM_NAMES[destination],"quote":"A new path opens beyond the known world."})
                journey["selected"] = destination
                if realm_backdrop != null: realm_backdrop.texture = load(Realms.REALM_ART[destination])
        var realm_state: Dictionary = Realms.state(data)
        if match_realm == 3 and bool(last_realm_awards.get("realm_completed", false)) and Realms.current_title(data,3) == "Fully Aware" and not bool(realm_state.get("fully_aware_ceremony_seen", false)):
            realm_state["fully_aware_ceremony_seen"] = true
            celebrate_fully_aware = true
    if not against_bot: data.ascend.next_start = 1-int(data.ascend.next_start)
    pending_fully_aware = celebrate_fully_aware
    SaveManager.save_data(data)
    if not queued_unlocks.is_empty():
        call_deferred("_show_next_unlock")
    elif celebrate_fully_aware:
        call_deferred("show_fully_aware",last_realm_awards.duplicate(true))
    else:
        call_deferred("show_match_result")

func _show_next_unlock() -> void:
    if not is_inside_tree(): return
    if queued_unlocks.is_empty():
        sync_realm_music()
        if pending_fully_aware:
            pending_fully_aware = false
            call_deferred("show_fully_aware",last_realm_awards.duplicate(true))
        else:
            call_deferred("show_match_result")
        return
    var item: Dictionary = queued_unlocks.pop_front()
    if str(item.kind) == "realm":
        var journey: ZenRealmTravelCeremony = RealmPortal.new()
        add_child(journey)
        journey.finished.connect(func():
            if is_inside_tree(): call_deferred("_show_next_unlock")
        )
        journey.present(Realms.REALM_ART[match_realm],
            Realms.REALM_ART[int(item.realm)], Realms.realm_name(int(item.realm),lang()),
            true, bool(data.settings.get("sound",true)), [world_music], lang())
        return
    var unlock: ZenUnlockCeremony = UnlockCeremony.new()
    add_child(unlock)
    unlock.finished.connect(func():
        if is_inside_tree(): call_deferred("_show_next_unlock")
    )
    unlock.present(str(item.kind),str(Realms.REALM_ART[int(item.realm)]),str(item.name),str(item.quote),bool(data.settings.get("sound",true)),[world_music])

func show_fully_aware(awards: Dictionary) -> void:
    if not is_inside_tree(): return
    var celebration: ZenFullyAwareCeremony = FullyAware.new()
    add_child(celebration)
    celebration.finished.connect(func():
        if is_inside_tree():
            call_deferred("show_match_result")
    )
    celebration.present(lang(),bool(data.settings.get("sound",true)),[world_music])

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
    # Exactly the same premium controls used by the bot-selection dialog.
    var parts: Dictionary = _realm_dialog(Z("Zen Ascend 4×4"),570)
    var body: VBoxContainer = parts.box
    var hero: TextureRect = TextureRect.new()
    hero.texture = load(Realms.REALM_ART[realm_index()])
    hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    hero.custom_minimum_size.y = 180
    hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
    body.add_child(hero)
    text(body,Z("Neuer Modus: 6 Seiten mit je 4×4 Feldern (96 Felder)."),18,Color("f9e4b0"))
    text(body,Z("Gewinne mit vier X oder O in einer Reihe: waagerecht, senkrecht oder diagonal auf einer Fläche ODER gerade über eine Würfelkante (1+3, 2+2, 3+1)."),15)
    text(body,Z("204 mögliche Gewinnlinien. Die klassische 3×3-Version bleibt unverändert."),15)
    action(body,Z("Neue Partie"),_start_picker_after_rules.bind(parts.dialog),true)
    _open_realm_dialog(parts)

func _start_picker_after_rules(dialog: Control) -> void:
    _close_realm_dialog(dialog)
    show_mode_picker()

func show_mode_picker() -> void:
    var parts: Dictionary = _realm_dialog(Z("Zen Ascend 4×4"),510)
    var dialog: Control = parts.dialog
    var body: VBoxContainer = parts.box
    text(body,"This Realm has a fixed Zen Ascend Bot difficulty.",15)
    text(body,Realms.realm_name(realm_index(),lang()) + " · " + Achievements.main_title(data,realm_index()),15,Color("e5ca93"))
    var fixed_level: int = Realms.fixed_bot_level(realm_index())
    var labels: Array[String] = ["Leicht", "Mittel", "Schwer", "Meister", "Großmeister"]
    text(body,"Zen Ascend Bot · " + Locale.translate(labels[fixed_level],lang()),18,Color("f4dfbd"))
    action(body,"Play Zen Ascend Bot · " + Locale.translate(labels[fixed_level],lang()),_start_realm_match.bind(true,fixed_level,dialog),true)
    action(body,Z("Zu zweit spielen"),_start_realm_match.bind(false,0,dialog))
    _open_realm_dialog(parts)

func _start_realm_match(bot: bool, level: int, dialog: Control) -> void:
    dialog.queue_free()
    start_game(bot,level)

func show_statistics() -> void:
    # Prestige card instead of a native gray Godot AcceptDialog.
    Mode.ensure(data)
    var s: Dictionary = data.ascend
    var total: int = int(s.played)
    var rate: float = 100.0*float(s.bot_wins)/float(maxi(1,int(s.bot_played)))
    var rank: int = clampi(int(data.ascension.rank),0,5)
    var parts: Dictionary = _realm_dialog(Z("Statistik & Rang"),700)
    var body: VBoxContainer = parts.box
    var illustration: TextureRect = TextureRect.new()
    illustration.texture = ZenAscension.WORLD_TEXTURES[mini(rank,4)]
    illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    illustration.custom_minimum_size.y = 220
    illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
    body.add_child(illustration)
    text(body,Locale.translate(str(ZenAscension.RANKS[rank]),lang()),25,Color("ffe3a2"))
    text(body,Achievements.main_title(data,realm_index()),20,Color("c8e4b8"))
    text(body,Realms.realm_name(realm_index(),lang()),15,Color("e4cb97"))
    if rank < 5:
        var progress: int = ZenAscension.progress(data,rank)
        var goal: int = ZenAscension.target(rank)
        text(body,"Next rank  ·  %d / %d" % [progress,goal],16)
        _progress_meter(body,progress,goal)
    text(body,"Matches %d   ·   Wins %d   ·   Draws %d" % [total,int(s.p1),int(s.draw)],15)
    text(body,"Win rate %.1f%%   ·   Best streak %d" % [rate,int(s.best_streak)],15)
    text(body,"Current streak %d   ·   Total moves %d" % [int(s.current_streak),int(s.moves)],15)
    text(body,"Fastest win %d   ·   Average moves %.1f" % [int(s.fastest_win),float(s.moves)/float(maxi(1,total))],15)
    action(body,_achievements_label(),show_realm_titles,true)
    _open_realm_dialog(parts)

func return_home() -> void:
    if get_tree() != null: get_tree().change_scene_to_file("res://Main.tscn")

# ---- Standalone 4x4 Realms UI; all original Classic screens remain untouched. ----
func L(key: String) -> String:
    return Realms.t(key,lang())

func _achievements_label() -> String:
    return "Erfolge" if lang() == "de" else ("Conquistas" if lang() == "pt" else "Achievements")

func _progress_meter(parent: Node, current: int, goal: int) -> void:
    var bar: ProgressBar = ProgressBar.new()
    bar.max_value = float(maxi(1,goal))
    bar.value = float(current)
    bar.show_percentage = false
    bar.custom_minimum_size.y = 15
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bar.add_theme_stylebox_override("background",style(Color("142825"),8))
    bar.add_theme_stylebox_override("fill",style(Color("829e76"),8))
    parent.add_child(bar)

func realm_index() -> int:
    return int(Realms.state(data).selected)

func _realm_dialog(title: String, height: int = 660) -> Dictionary:
    # Draw custom premium overlay directly within the game, not Godot's gray Window.
    if is_instance_valid(active_realm_dialog): active_realm_dialog.queue_free()
    var root: Control = Control.new()
    root.name = "ZenRealmPremiumOverlay"
    root.mouse_filter = Control.MOUSE_FILTER_STOP
    layer.add_child(root)
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var tint: ColorRect = ColorRect.new()
    tint.color = Color("101b21",0.73)
    tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(tint)
    tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var frame: PanelContainer = PanelContainer.new()
    frame.add_theme_stylebox_override("panel",style(Color("1b302d",0.985),24))
    root.add_child(frame)
    frame.anchor_left = 0.045
    frame.anchor_right = 0.955
    frame.anchor_top = 0.23 if height <= 430 else 0.105
    frame.anchor_bottom = 0.77 if height <= 430 else 0.885
    frame.offset_left = 0
    frame.offset_right = 0
    frame.offset_top = 0
    frame.offset_bottom = 0
    var stack: VBoxContainer = VBoxContainer.new()
    stack.add_theme_constant_override("separation",12)
    frame.add_child(stack)
    var heading: HBoxContainer = HBoxContainer.new()
    heading.add_theme_constant_override("separation",8)
    stack.add_child(heading)
    var heading_text: Label = text(heading,title,19,Color("f1d8a3"))
    heading_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    heading_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var close_btn: Button = action(heading,"✕",_close_realm_dialog.bind(root))
    close_btn.custom_minimum_size = Vector2(48,48)
    close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
    var golden_rule: ColorRect = ColorRect.new()
    golden_rule.color = Color("c39d61",0.73)
    golden_rule.custom_minimum_size.y = 2
    golden_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_child(golden_rule)
    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.mouse_filter = Control.MOUSE_FILTER_PASS
    stack.add_child(scroll)
    var content: VBoxContainer = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation",13)
    content.mouse_filter = Control.MOUSE_FILTER_PASS
    scroll.add_child(content)
    var back: Button = action(stack,L("return"),_close_realm_dialog.bind(root),true)
    back.custom_minimum_size.y = 53
    active_realm_dialog = root
    active_realm_scroll = scroll
    return {"dialog":root,"box":content,"scroller":scroll}

func _open_realm_dialog(items: Dictionary) -> void:
    # An in-scene overlay is immediately visible, already sized to the viewport.
    var dialog: Control = items.dialog
    dialog.visible = true

func _realm_unlocked_hint(realm: int) -> String:
    return Realms.missing_reason(data,realm,lang())

func show_realms() -> void:
    Realms.ensure(data)
    var ui_parts: Dictionary = _realm_dialog("Zen Ascend · " + L("realms"))
    var body: VBoxContainer = ui_parts.box
    text(body,L("subtitle"),15,Color("567b72"))
    text(body,L("total") + ": %d/32 · " % Realms.total_count(data) + Realms.overall_title_local(data,lang()),16,Color("bf9d65"))
    for i in range(4):
        var number: int = i
        var allowed: bool = Realms.unlocked(data,i)
        var card: PanelContainer = PanelContainer.new()
        card.add_theme_stylebox_override("panel",style(_realm_tone(i),18))
        body.add_child(card)
        var column: VBoxContainer = VBoxContainer.new()
        column.add_theme_constant_override("separation",5)
        card.add_child(column)
        text(column,Realms.realm_name(i,lang()) + ("  🔒" if not allowed else ""),20,Color("f7dfaa"))
        var thumb: TextureRect = TextureRect.new()
        thumb.texture = load(Realms.REALM_ART[i])
        thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        thumb.custom_minimum_size = Vector2(0,112)
        thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        column.add_child(thumb)
        var amount: int = Realms.count(data,i)
        text(column,L("progress") + ": %d/8  ·  " % amount + L("matches") + ": %d" % int(Realms.state(data).stats[i].wins),14)
        var rank_name: String = Realms.title_for_realm(data,i,lang())
        if rank_name != "—": text(column,rank_name,14,Color("e2ca8c"))
        if amount == 8: text(column,"🏵 " + L("realm_complete") + " · 🍃 250",13,Color("c9e6b1"))
        if not allowed: text(column,L("locked") + ": " + _realm_unlocked_hint(i),13)
        var selected: bool = i == realm_index()
        var choose: Button
        if not allowed:
            choose = action(column,"🔒  " + ("Freischaltung ansehen" if lang() == "de" else "View unlock requirements"),_show_realm_requirements.bind(number),false)
        else:
            choose = action(column,L("selected") if selected else L("select"),_choose_realm_from_dialog.bind(number,ui_parts.dialog),true)
            choose.disabled = selected or (move_count() > 0 and result == 0)
    text(body,L("bot_only"),13,Color("d5ba85"))
    _open_realm_dialog(ui_parts)

func _show_realm_requirements(realm: int) -> void:
    var parts: Dictionary = _realm_dialog(Realms.realm_name(realm,lang()),620)
    var body: VBoxContainer = parts.box
    var hero: TextureRect = TextureRect.new()
    hero.texture = load(Realms.REALM_ART[realm])
    hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    hero.custom_minimum_size.y = 200
    hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
    body.add_child(hero)
    text(body,"🔒  " + Realms.missing_reason(data,realm,lang()),17,Color("f6daa0"))
    var source_realm: int = realm - 1
    for previous in range(realm):
        if Realms.count(data,previous) < 8:
            source_realm = previous
            break
    if source_realm >= 0:
        var done: int = Realms.count(data,source_realm)
        text(body,Realms.realm_name(source_realm,lang()) + " · %d/8 " % done + L("challenges"),16)
        _progress_meter(body,done,8)
    action(body,L("realms"),show_realms,true)
    _open_realm_dialog(parts)

func _choose_realm_from_dialog(number: int, dialog: Control) -> void:
    if select_realm(number): dialog.queue_free()

func select_realm(number: int) -> bool:
    if move_count() > 0 and result == 0: return false
    var from_realm: int = realm_index()
    if not Realms.select(data,number): return false
    match_realm = number
    # Prevent stale Medium UI/AI after switching from Shadow to Ember.
    bot_level = Realms.fixed_bot_level(number)
    if realm_backdrop != null:
        realm_backdrop.texture = load(Realms.REALM_ART[number])
    SaveManager.save_data(data)
    draw()
    if from_realm != number:
        call_deferred("_show_manual_realm_journey",from_realm,number)
    else:
        sync_realm_music()
    return true

func _show_manual_realm_journey(from_realm: int, to_realm: int) -> void:
    if not is_inside_tree(): return
    var journey: ZenRealmTravelCeremony = RealmPortal.new()
    add_child(journey)
    journey.finished.connect(func():
        if is_inside_tree(): sync_realm_music()
    )
    journey.present(Realms.REALM_ART[from_realm],Realms.REALM_ART[to_realm],
        Realms.realm_name(to_realm,lang()),false,
        bool(data.settings.get("sound",true)),[world_music],lang())

func _challenge_items(list: VBoxContainer, realm: int) -> void:
    for node in list.get_children(): node.queue_free()
    var unlocked: bool = Realms.unlocked(data,realm)
    var heading: PanelContainer = PanelContainer.new()
    heading.add_theme_stylebox_override("panel",style(_realm_tone(realm),18))
    list.add_child(heading)
    var head_box: VBoxContainer = VBoxContainer.new()
    heading.add_child(head_box)
    var hero: TextureRect = TextureRect.new()
    hero.texture = load(Realms.REALM_ART[realm])
    hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    hero.custom_minimum_size.y = 160
    hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
    head_box.add_child(hero)
    text(head_box,Realms.REALM_NAMES[realm] + ("  🔒" if not unlocked else ""),20,Color("f5dca8"))
    text(head_box,L("progress") + ": %d/8" % Realms.count(data,realm),14)
    _progress_meter(head_box,Realms.count(data,realm),8)
    if not unlocked:
        text(head_box,L("locked") + ": " + _realm_unlocked_hint(realm),13)
    var done: Dictionary = Realms.state(data).completed
    for task in Realms.TASKS[realm]:
        var earned: bool = bool(done.get(str(task.id),false))
        var card: PanelContainer = PanelContainer.new()
        card.add_theme_stylebox_override("panel",style(Color("294a3c") if earned else _realm_tone(realm),16))
        card.mouse_filter = Control.MOUSE_FILTER_PASS
        list.add_child(card)
        var inside: VBoxContainer = VBoxContainer.new()
        inside.add_theme_constant_override("separation",8)
        inside.mouse_filter = Control.MOUSE_FILTER_PASS
        card.add_child(inside)
        text(inside,("✓  " if earned else "◇  ") + str(task.title),18,Color("f3ddb2"))
        text(inside,Realms.task_description(task,lang()),14,Color("d7d5c9"))
        text(inside,(L("earned") if earned else L("reward")) + "  ·  🍃 %d" % int(task.leaves),14,Color("bce3af"))
    text(list,L("bot_only"),13,Color("cdbd9d"))

func show_challenges() -> void:
    # The Realm is chosen in Realms, not again in Challenges. More space for cards.
    var parts: Dictionary = _realm_dialog("Zen Ascend · " + L("challenges"))
    var body: VBoxContainer = parts.box
    var tasks_box: VBoxContainer = VBoxContainer.new()
    tasks_box.add_theme_constant_override("separation",14)
    body.add_child(tasks_box)
    _challenge_items(tasks_box,realm_index())
    _open_realm_dialog(parts)

func show_realm_titles() -> void:
    # Achievements are independent of the Realm Challenges. Only one main
    # title can be earned per Realm, through full Realm mastery (8/8).
    var parts: Dictionary = _realm_dialog("Zen Ascend · " + _achievements_label())
    var body: VBoxContainer = parts.box
    text(body,"Secret Achievements   ·   %d / %d" % [Achievements.secret_count(data),Achievements.SECRETS.size()],18,Color("f3dca4"))
    for realm in range(4):
        var group: PanelContainer = PanelContainer.new()
        group.add_theme_stylebox_override("panel",style(_realm_tone(realm),18))
        group.mouse_filter = Control.MOUSE_FILTER_PASS
        body.add_child(group)
        var inside: VBoxContainer = VBoxContainer.new()
        inside.add_theme_constant_override("separation",9)
        group.add_child(inside)
        text(inside,Realms.realm_name(realm,lang()),21,Color("f7dda5"))
        var picture: TextureRect = TextureRect.new()
        picture.texture = load(Realms.REALM_ART[realm])
        picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        picture.custom_minimum_size.y = 160
        picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
        inside.add_child(picture)
        var master: String = Achievements.MAIN_TITLES[realm]
        var title_earned: bool = Realms.count(data,realm) == 8
        text(inside,("✦ " if title_earned else "🔒 ") + master + ("  ·  8/8" if title_earned else "  ·  Locked"),18,Color("d1eabd") if title_earned else Color("d9c8ac"))
        action(inside,"View Realm Title",_show_achievement_details.bind(realm,{"id":"main","name":master,"condition":"Complete all 8 Realm Challenges.","quote":Achievements.main_quote(realm)},title_earned),false)
        for secret in Achievements.SECRETS:
            if int(secret.realm) != realm: continue
            var unlocked: bool = Achievements.earned(data,str(secret.id))
            var display: String = ("✦  " + str(secret.name)) if unlocked else "◇  ???  ·  Secret Achievement"
            action(inside,display,_show_achievement_details.bind(realm,secret,unlocked),unlocked)
    _open_realm_dialog(parts)

func _show_achievement_details(realm: int, secret: Dictionary, unlocked: bool) -> void:
    var is_main_title: bool = str(secret.id) == "main"
    var revealed: bool = unlocked or is_main_title
    var title_text: String = str(secret.name) if revealed else "???"
    var parts: Dictionary = _realm_dialog(title_text,610)
    var body: VBoxContainer = parts.box
    var picture: TextureRect = TextureRect.new()
    picture.texture = load(Realms.REALM_ART[realm])
    picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    picture.custom_minimum_size.y = 250
    picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    body.add_child(picture)
    text(body,("✦  Achievement Unlocked" if unlocked else "🔒  Secret Achievement"),18,Color("f4dcaa"))
    text(body,title_text,23,Color("f7e4b9"))
    if revealed:
        text(body,"“" + str(secret.quote) + "”",17,Color("d8e7d4"))
        text(body,"How to unlock: " + str(secret.condition),15,Color("f1d29b"))
    else:
        text(body,"Unlock condition hidden. Discover the secret in play.",15,Color("d8e7d4"))
        if Achievements.hint_owned(data,str(secret.id)):
            text(body,"🍃  Hint: " + Achievements.hint_text(str(secret.id)),16,Color("f1d29b"))
        else:
            text(body,"Get a hint in Main menu → Zen Shop → Hints (🍃 %d)." % Achievements.HINT_PRICE,14,Color("edcfa2"))
    action(body,_achievements_label(),show_realm_titles,true)
    _open_realm_dialog(parts)

func show_match_result() -> void:
    if not is_inside_tree(): return
    var human_won: bool = result in [1,2] and int(owners[result-1]) == 0
    var title: String = Z("Unentschieden!") if result == 3 else (Z("Gewonnen!") if human_won else zen_ascend_bot_name() + " · " + Z("hat gewonnen!"))
    if not against_bot and result in [1,2]: title = pname(int(owners[result-1])) + " " + Z("hat gewonnen!")
    var parts: Dictionary = _realm_dialog(title,410)
    var body: VBoxContainer = parts.box
    var medal: PanelContainer = PanelContainer.new()
    medal.add_theme_stylebox_override("panel",style(Color("274b3c") if human_won else Color("2b3540"),20))
    body.add_child(medal)
    var info: VBoxContainer = VBoxContainer.new()
    info.add_theme_constant_override("separation",11)
    medal.add_child(info)
    text(info,("✦  " if human_won else "◇  ") + title,24,Color("ffe4a5"))
    var leaves_total: int = last_match_leaf_reward + int(last_realm_awards.get("leaves",0))
    if leaves_total > 0:
        text(info,"🍃 +%d " % leaves_total + L("leaves"),21,Color("c4edac"))
    for task_id in last_realm_awards.get("new_tasks",[]):
        for task in Realms.TASKS[clampi(match_realm,0,3)]:
            if str(task.id) == str(task_id): text(info,"✓  " + str(task.title),15,Color("f0dba7"))
    if bool(last_realm_awards.get("realm_completed",false)):
        text(info,"✦  " + L("realm_complete"),17,Color("ffe6a4"))
    if not last_realm_awards.get("new_tasks",[]).is_empty():
        if Achievements.main_title(data,match_realm) != "—":
            text(info,L("rank") + ": " + Achievements.main_title(data,match_realm),15)
    action(body,Z("Neue Partie"),_replay_after_result.bind(parts.dialog),true)
    action(body,Z("Hauptmenü"),return_home)
    _open_realm_dialog(parts)

func _replay_after_result(dialog: Control) -> void:
    _close_realm_dialog(dialog)
    start_game(against_bot,bot_level)

func show_realm_rewards(_awards: Dictionary) -> void:
    # Compatibility: rewards are part of the single themed match result now.
    show_match_result()
