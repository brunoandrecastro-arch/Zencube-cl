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
var music_fade_player: AudioStreamPlayer
var music_transition: Tween
var net_buttons: Array = []
var net_active = false
var tutorial_from_welcome = false
var welcome_open = false
var home_visible: bool = false
var menu_context: bool = false
var tutorial_quick: bool = false
var tutorial_return_to_campaign: bool = false
var toast = ""
var toast_until = 0
# Challenge mode uses the same BoardModel, RulesEngine and 3D CubeRenderer.
var challenges: ZenChallenges
var challenge_active: bool = false
var challenge_index: int = 0
var challenge_phase: int = 0 # player move index (0-based), -1: solved
var challenge_hint_level: int = 0
var challenge_message: String = ""
var classic_backup: Dictionary = {}
var world_background: TextureRect
var rank_label: Label
var world_title_label: Label
var world_quote_label: Label
var current_world: int = -1
var last_rank_up: Dictionary = {"rank_up": false, "new_rank": 0}
var ceremony_done_for_match: bool = false
var ceremony_active: bool = false
var last_leaf_reward: int = 0
var completed_bot_level: int = -1 # Difficulty of the finished match; rank-up changes NEXT match.
const Collection = preload("res://core/ZenCollection.gd")
const Backdrops = preload("res://core/ZenBackdrops.gd")

var challenge_row: HBoxContainer
var classic_views: HBoxContainer
var classic_actions: HBoxContainer
var classic_undo_button: Button
var classic_result_button: Button
var challenge_leave_row: HBoxContainer
var challenge_role_panel: PanelContainer
var challenge_role_label: Label
const ZenLocale = preload("res://core/ZenLocalization.gd")
const UiTest = preload("res://ui/ZenUiTestTheme.gd")
const ZenType = preload("res://ui/ZenRealm2Typography.gd")
const Asc = preload("res://core/ZenAscension.gd")
# One original quote per Classic World (DE source; translated in ZenLocalization).
const WORLD_QUOTES: Array[String] = [
    "„Jeder große Weg beginnt mit einem stillen Schritt.“",
    "„Der Bambus biegt sich im Wind, doch verliert nie seine Wurzeln.“",
    "„Nicht der Gipfel schenkt dir Klarheit, sondern der Weg dorthin.“",
    "„Erst wenn das Wasser still wird, spiegelt es den Mond.“",
    "„Wer nichts mehr festhalten muss, findet die Freiheit.“"
]
const BotAuto = preload("res://core/ZenBotAutoLevel.gd")
const ZMode = preload("res://core/ZenAscend.gd")
const RANK_CEREMONY = preload("res://ui/ZenRankCeremony.gd")
const MusicPolicy = preload("res://core/ZenMusicPolicy.gd")
const ZenCampaign = preload("res://story/ZenCampaign.gd")
const ActOne = preload("res://story/ZenActOne.gd")
const ActTwo = preload("res://story/ZenActTwo.gd")
const ActThree = preload("res://story/ZenActThree.gd")
const ActFour = preload("res://story/ZenActFour.gd")
const Journey = preload("res://story/ZenJourney.gd")
const HomeMenu = preload("res://ui/ZenHomeMenu.gd")
const ProfileAchievements = preload("res://core/ZenAscendAchievements.gd")
const ProfileRealms = preload("res://core/ZenAscendRealms.gd")
var prequel_act: int = 1
var prequel_model: Script = ActOne
var act_one_active := false
var act_one_progress: Dictionary = {}
var act_one_classic_board: BoardModel
var act_one_view: Dictionary = {}
var act_one_controls: HBoxContainer
var act_one_result_button: Button
var act_one_back_previous := true
var zen_campaign_active: bool = false
var zen_campaign_stage: int = 0
var zen_campaign_progress: Dictionary = {}
var zen_campaign_classic_board: BoardModel
var zen_campaign_classic_view: Dictionary = {}
var zen_campaign_controls: HBoxContainer
var zen_campaign_undo_button: Button
var zen_campaign_bot_ready: int = 0
var zen_campaign_turn_start: int = 0
var zen_campaign_paused: bool = false
var zen_campaign_battle_line: String = ""
var zen_campaign_line_until: int = 0
var zen_campaign_last_line_move: int = -99
var zen_campaign_spoken: Dictionary = {}
@onready var chronicles: Node = get_node("/root/ZenChronicles")
# ZENCUBE WORLD MUSIC PATCH 1
func language_code() -> String:
    if data == null: return "de"
    return str(data.settings.get("language", "de"))
func T(source: String) -> String:
    return ZenLocale.translate(source, language_code())
func translate_ui_tree(node: Node) -> void:
    if node.has_meta("zen_source_text"):
        if node is Button or node is Label:
            node.text = T(str(node.get_meta("zen_source_text")))
    for child in node.get_children():
        translate_ui_tree(child)
func choose_language(code: String) -> void:
    if not code in ["de", "en", "pt"]: return
    data.settings.language = code
    # Discard transient text in the previously selected language.
    toast = ""
    toast_until = 0
    challenge_message = ""
    close_modal()
    translate_ui_tree(ui)
    refresh()
    persist() # Saves settings without replacing Classic while in Challenges.
    open_menu()
func change_language(code: String) -> void:
    choose_language(code)
    if bool(data.settings.get("intro_seen", false)):
        open_settings()
func open_language_choice() -> void:
    # Separate UI Test: real 3x3 game cube, real 2+2 winning line,
    # and native accessible language controls rather than an image mockup.
    var box: VBoxContainer = modal("ZenCube 3D")
    UiTest.show_language_selection(popup, box, Callable(self, "choose_language"))
func _ready() -> void:
    data = SaveManager.load_data()
    Asc.ensure(data)
    if SaveManager.valid_game(data.game):
        board.restore(data.game)
        board.history = data.game.get("history",[])
        board.win_lines = rules.victories(board.cells,1)+rules.victories(board.cells,2)
    else:
        board.swap_enabled = bool(data.settings.swap)
    challenges = ZenChallenges.new(rules.lines)
    Collection.ensure(data)
    # Once-only migration: previous Zen-Bot wins and solved puzzles receive leaves.
    Collection.migrate_previous_rewards(data, challenges.solved)
    build_ui()
    build_sound()
    renderer.apply_skin(int(data.economy.equipped))
    refresh()
    if not str(data.settings.get("language", "")) in ["de", "en", "pt"]:
        open_language_choice()
    else:
        open_menu()
func theme_style(bg: Color, radius: int = 18) -> StyleBoxFlat:
    var st = StyleBoxFlat.new()
    st.bg_color = bg
    st.border_color = UiTest.GOLD
    st.set_border_width_all(2)
    st.set_corner_radius_all(radius)
    st.content_margin_left = 13
    st.content_margin_right = 13
    st.content_margin_top = 10
    st.content_margin_bottom = 10
    st.shadow_color = Color("132018",0.29)
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
    # Every classic menu uses the same jade controls and gold borders as 4x4.
    var base_color: Color = Color("#315b3d") if primary else UiTest.GREEN
    b.add_theme_stylebox_override("normal",UiTest.frame(base_color,18))
    b.add_theme_stylebox_override("hover",UiTest.frame(Color("#49704c") if primary else Color("#2b5637"),18))
    b.add_theme_stylebox_override("pressed",UiTest.frame(Color("#34543b"),18))
    for color_key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
        b.add_theme_color_override(color_key,UiTest.IVORY)
    b.pressed.connect(callback)
    b.button_down.connect(func():
        b.create_tween().tween_property(b, "modulate", Color("e8dbc7"), 0.08)
    )
    b.button_up.connect(func():
        b.create_tween().tween_property(b, "modulate", Color.WHITE, 0.12)
    )
    parent.add_child(b)
    return b
func premium_button(text: String, parent: Node, callback: Callable, featured: bool = false) -> Button:
    var b: Button = button(text, parent, callback, false, false)
    b.custom_minimum_size.y = 59
    b.add_theme_font_size_override("font_size", 20)
    var normal_color: Color = Color("#315b3d") if featured else UiTest.GREEN
    var hover_color: Color = Color("#49704c") if featured else Color("#2b5637")
    b.add_theme_stylebox_override("normal", theme_style(normal_color, 18))
    b.add_theme_stylebox_override("hover", theme_style(hover_color, 18))
    b.add_theme_stylebox_override("pressed", UiTest.frame(Color("#34543b"),18))
    for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        b.add_theme_color_override(key, Color("fff0cf"))
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
    world_background = garden
    garden.name = "GardenBackground"
    garden.texture = load("res://assets/zen_garden_scene.webp")
    garden.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    garden.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    garden.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(garden)
    garden.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var veil = ColorRect.new()
    veil.color = Color("0a2218",0.16)
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ui.add_child(veil)
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var th = Theme.new()
    th.default_font = ZenType.body()
    th.default_font_size = 18
    th.set_stylebox("normal","Button",theme_style(Color("faecd3"),18))
    th.set_stylebox("hover","Button",theme_style(Color("f6dfbb"),18))
    th.set_stylebox("pressed","Button",theme_style(Color("e9cda6"),18))
    th.set_stylebox("focus","Button",theme_style(Color("eed4ab"),18))
    for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
        th.set_color(key,"Button",Color("493521"))
    for typ in ["Label","CheckButton","OptionButton","LineEdit"]:
        th.set_color("font_color",typ,Color("493521"))
    th.set_color("font_hover_color","CheckButton",Color("493521"))
    UiTest.install_main_theme(th)
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
    title_panel.add_theme_stylebox_override("panel",theme_style(Color("18291e",0.97),25))
    column.add_child(title_panel)
    var title_row = row(title_panel)
    var brand = VBoxContainer.new()
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    brand.add_theme_constant_override("separation",1)
    title_row.add_child(brand)
    # In-game header foregrounds the CURRENT World; brand remains visible below.
    world_title_label = label("Zen-Garten",brand,27,Color("f9e5b8"))
    world_title_label.add_theme_font_override("font",ZenType.heading())
    world_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var sub = label("ZenCube 3D",brand,12,Color("e6c99d"))
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var menu = button("☰",title_row,open_menu,true)
    menu.custom_minimum_size.x = 46
    menu.size_flags_horizontal = Control.SIZE_SHRINK_END

    var ribbon = PanelContainer.new()
    ribbon.add_theme_stylebox_override("panel",theme_style(Color("fff1d7",0.91),18))
    column.add_child(ribbon)
    var header = VBoxContainer.new()
    header.add_theme_constant_override("separation",1)
    ribbon.add_child(header)
    status = label("",header,20,Color("453329"))
    detail = label("",header,12,Color("80684e"))
    rank_label = label("",header,12,Color("67785b"))
    # Only challenge mode shows this explicit player/bot assignment.
    challenge_role_panel = PanelContainer.new()
    challenge_role_panel.add_theme_stylebox_override("panel",theme_style(Color("41543e",0.97),10))
    header.add_child(challenge_role_panel)
    challenge_role_label = label("",challenge_role_panel,15,Color("fff6df"))
    challenge_role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    challenge_role_panel.visible = false

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
    # Keep a real 960px SubViewport independent of the phone-sized UI.
    # SubViewportContainer(stretch=true) would silently resize it to its UI rect.
    var container = TextureRect.new()
    container.mouse_filter = Control.MOUSE_FILTER_STOP
    container.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    container.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    container.custom_minimum_size = Vector2(0,225)
    container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    container.size_flags_vertical = Control.SIZE_EXPAND_FILL
    game_stack.add_child(container)
    viewport = SubViewport.new()
    viewport.size = Vector2i(960,960)
    viewport.transparent_bg = true
    viewport.own_world_3d = true
    viewport.msaa_3d = Viewport.MSAA_4X
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    add_child(viewport)
    renderer = CubeRenderer.new()
    viewport.add_child(renderer)
    input_control = InputController.new(renderer,on_cell)
    container.texture = viewport.get_texture()
    container.gui_input.connect(_on_cube_surface_input.bind(container))

    # Accessible status strip: readable regardless of the garden background.
    var feedback_panel = PanelContainer.new()
    feedback_panel.add_theme_stylebox_override("panel",theme_style(Color("30271f",0.96),13))
    column.add_child(feedback_panel)
    help_text = label("Ziehen: drehen  ·  Tippen: setzen  ·  2 Finger: zoomen",feedback_panel,15,Color("fff3df"))
    help_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    swap_row = row(column)
    button("X übernehmen",swap_row,func(): resolve_swap(true))
    button("O behalten",swap_row,func(): resolve_swap(false))
    tutorial_row = row(column)
    button("Zurück",tutorial_row,func(): tutorial_step(-1),true)
    button("Weiter",tutorial_row,func(): tutorial_step(1),true)
    button("Spielen",tutorial_row,end_tutorial,true,true)
    challenge_row = row(column)
    button("◀",challenge_row,func(): open_challenge_number(challenge_index-1),true)
    button("Tipp",challenge_row,challenge_hint,true)
    button("Neustart",challenge_row,challenge_restart,true)
    button("Stufen",challenge_row,open_challenge_levels,true)
    button("▶",challenge_row,func(): open_challenge_number(challenge_index+1),true)
    var leave = row(column)
    button("Klassisches Spiel fortsetzen",leave,leave_challenges,true,true)
    challenge_leave_row = leave
    var views = row(column)
    classic_views = views
    button("Ansicht",views,func(): renderer.reset_view(),true)
    button("Alle Seiten",views,open_net,true)
    button("Hinweis",views,open_help,true)
    var actions = row(column)
    classic_actions = actions
    classic_undo_button = button("Rückgängig",actions,undo)
    classic_result_button = button("Ergebnis anzeigen",actions,show_result_screen)
    classic_result_button.name = "ClassicShowFinishedResult"
    classic_result_button.hide()
    button("Neue Partie",actions,confirm_new,true,true)
    zen_campaign_controls = row(column)
    zen_campaign_undo_button = button("Rückgängig", zen_campaign_controls, _zen_campaign_undo, true)
    zen_campaign_undo_button.add_theme_stylebox_override("disabled", theme_style(Color("342c25", 0.94), 18))
    zen_campaign_undo_button.add_theme_color_override("font_disabled_color", Color("d3c2a7"))
    button(_campaign_text("leave"), zen_campaign_controls, _zen_campaign_leave, true)
    zen_campaign_controls.hide()
    act_one_controls = row(column)
    act_one_result_button = button("Ergebnis anzeigen", act_one_controls, _act_one_result, true)
    button("‹", act_one_controls, _act_one_leave, true)
    act_one_controls.hide()
    var legend_panel = PanelContainer.new()
    var legend_style = theme_style(Color("30271f",0.89),9)
    legend_style.content_margin_top = 5
    legend_style.content_margin_bottom = 5
    legend_panel.add_theme_stylebox_override("panel",legend_style)
    column.add_child(legend_panel)
    # Technical line counts remain in Rules; the footer belongs to the World.
    world_quote_label = label(WORLD_QUOTES[0],legend_panel,12,Color("fff3df"))
    world_quote_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    world_quote_label.custom_minimum_size.y = 27.0
# Transform actual phone taps into the 960x960 picking coordinates.
# Drags keep physical pixel deltas so cube rotation feels the same as before.
func _on_cube_surface_input(event: InputEvent, surface: TextureRect) -> void:
    var side: float = minf(surface.size.x, surface.size.y)
    if side < 1.0: return
    var inset: Vector2 = (surface.size - Vector2(side,side)) * 0.5
    var ratio: float = float(viewport.size.x) / side
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event.duplicate() as InputEventScreenTouch
        touch.position = (event.position - inset) * ratio
        input_control.handle(touch)
    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event.duplicate() as InputEventScreenDrag
        drag.position = (event.position - inset) * ratio
        input_control.handle(drag)
    elif event is InputEventMouseButton:
        var mouse: InputEventMouseButton = event.duplicate() as InputEventMouseButton
        mouse.position = (event.position - inset) * ratio
        input_control.handle(mouse)
    elif event is InputEventMouseMotion:
        var motion: InputEventMouseMotion = event.duplicate() as InputEventMouseMotion
        motion.position = (event.position - inset) * ratio
        input_control.handle(motion)

func mode_name() -> String:
    var mode = int(data.settings.mode)
    if mode == 1:
        # Don't relabel a just-finished match as the newly unlocked difficulty.
        var displayed_level: int = clampi(int(data.settings.level),0,4)
        if board != null and board.winner != 0 and completed_bot_level >= 0:
            displayed_level = completed_bot_level
        return T("Du gegen Zen-Bot · ")+T(Asc.LEVELS[displayed_level])
    if mode == 2: return T("Lernmodus")
    return T("Zwei Spieler lokal")
func player_name(owner: int) -> String:
    if int(data.settings.mode) == 1:
        return "Zen-Bot" if owner == 1 else _display_player_name(0)
    return _display_player_name(owner)
func apply_world() -> void:
    if world_background == null or data == null: return
    var chosen: int = clampi(int(data.ascension.get("world",0)), 0, 4)
    var backdrop: int = Backdrops.selected(data)
    var background_key: int = chosen if backdrop == -1 else 100 + backdrop
    if background_key == current_world: return
    current_world = background_key
    world_background.texture = Asc.WORLD_TEXTURES[chosen] if backdrop == -1 else load(str(Backdrops.ITEMS[backdrop].path))
    # The world changes without touching the real 3D gameplay viewport.
    # A gentle fade keeps transitions calm and avoids flicker on mobile.
    world_background.modulate.a = 0.86
    create_tween().tween_property(world_background, "modulate:a", 1.0, 0.28)
    if world_title_label != null and world_quote_label != null:
        world_title_label.modulate.a = 0.55
        world_quote_label.modulate.a = 0.55
        create_tween().tween_property(world_title_label, "modulate:a", 1.0, 0.45)
        create_tween().tween_property(world_quote_label, "modulate:a", 1.0, 0.45)
    sync_music() # Auto-World theme follows the selected World.

func refresh(animate: int = -1, save_classic: bool = true) -> void:
    if act_one_active:
        _act_one_refresh(animate)
        return
    if is_instance_valid(act_one_controls): act_one_controls.hide()
    if zen_campaign_active:
        _zen_campaign_refresh(animate)
        return
    Collection.ensure(data)
    apply_world()
    # Refresh both whenever the World OR the interface language changes.
    var active_world: int = clampi(int(data.ascension.get("world",0)),0,4)
    world_title_label.text = T(Asc.WORLDS[active_world])
    world_quote_label.text = T(WORLD_QUOTES[active_world])
    rank_label.visible = not challenge_active
    if not challenge_active:
        rank_label.text = T("Zen-Rang") + ": " + T(Asc.RANKS[int(data.ascension.rank)]) + "  ·  " + T(Asc.WORLDS[int(data.ascension.world)])
    if challenge_active:
        challenge_role_label.text = T("Du spielst X  ·  Zen-Bot spielt O")
        var p: Dictionary = challenges.puzzle(challenge_index)
        var kind: String = str(p.kind)
        if challenge_phase == -1:
            status.text = T("Rätsel gelöst!")
        elif kind == "sequence":
            status.text = T("Erzwinge einen Sieg in %d Zügen") % int(p.moves)
        elif kind == "defense":
            status.text = T("Finde den einzigen rettenden Zug")
        elif kind == "win":
            status.text = T("Finde den Gewinnzug")
        elif kind == "block":
            status.text = T("Blockiere den Sieg von O")
        elif challenge_phase >= 1:
            status.text = T("Finde den zweiten Gewinnweg")
        else:
            status.text = T("Erzwinge einen Sieg in zwei Zügen")
        status.add_theme_color_override("font_color",Color("67785b") if challenge_phase == -1 else Color("453329"))
        var level: int = int(p.level)
        detail.text = T("Zen-Rätsel") + " · " + T(["Anfänger", "Fortgeschritten", "Experte", "Zen-Meister", "Großmeister"][level-1]) + " %02d/20  ·  ✓ %d/100" % [((challenge_index % 20)+1),challenges.solved.size()]
        help_text.text = (toast if Time.get_ticks_msec() < toast_until else challenge_message if challenge_message != "" else T("Drehe den Würfel und finde den richtigen Zug."))
    else:
        var sym := "X" if board.turn == 1 else "O"
        var owner := board.current_owner()
        if int(data.settings.mode) == 1:
            status.text = T("Zen-Bot denkt nach …") if owner == 1 else T("Du bist am Zug  ·  ")+sym
        else:
            status.text = player_name(owner)+T(" ist am Zug  ·  ")+sym
        status.add_theme_color_override("font_color", Color("453329") if board.turn == 1 else Color("a75f43"))
        if board.swap_pending: status.text = player_name(board.owners[1])+T(" · Farbe wählen")
        if board.winner != 0:
            if board.winner == 3:
                status.text = T("Unentschieden · gut gespielt!")
            elif int(data.settings.mode) == 1:
                status.text = T("Du hast gewonnen!") if int(board.owners[board.winner - 1]) == 0 else T("Zen-Bot hat gewonnen.")
            else:
                status.text = T("%s hat gewonnen.") % player_name(int(board.owners[board.winner - 1]))
            status.add_theme_color_override("font_color", Color("67785b"))
        detail.text = mode_name()+T("  ·  Zug ")+str(board.move_count())
        if ai_running: detail.text += T("  ·  Zen-Bot überlegt …")
        if tutorial != null:
            var total: int = 3 if tutorial_quick else TutorialController.TEXTS.size()
            help_text.text = str(tutorial.step+1)+" / "+str(total)+"  ·  "+T(TutorialController.TEXTS[tutorial.step])
        else:
            help_text.text = toast if Time.get_ticks_msec()<toast_until else T("Ziehen: drehen  ·  Tippen: setzen  ·  2 Finger: zoomen")
    swap_row.visible = not challenge_active and board.swap_pending and not (int(data.settings.mode) == 1 and board.current_owner() == 1 and tutorial == null)
    tutorial_row.visible = not challenge_active and tutorial != null
    challenge_role_panel.visible = challenge_active
    var finished_classic: bool = board.winner != 0 and not challenge_active and not zen_campaign_active and tutorial == null
    if is_instance_valid(classic_undo_button): classic_undo_button.visible = not finished_classic
    if is_instance_valid(classic_result_button):
        classic_result_button.visible = finished_classic
        classic_result_button.text = _classic_result_label()
    if finished_classic:
        help_text.text = "Partie beendet · Würfel drehen und zoomen" if language_code() == "de" else ("Partida terminada · Roda e amplia o cubo" if language_code() == "pt" else "Match finished · Rotate and zoom the cube")
    challenge_row.visible = challenge_active
    challenge_leave_row.visible = challenge_active
    classic_views.visible = not challenge_active
    classic_actions.visible = not challenge_active
    renderer.selected = board.last_cell
    renderer.paint(board,(bool(data.settings.hints) or tutorial != null) and not challenge_active,preview,animate)
    classic_views.get_child(2).show()
    zen_campaign_controls.hide()
    if save_classic and tutorial == null and not challenge_active: persist()
    if net_active: update_net()
func persist() -> void:
    if act_one_active:
        _act_one_save()
        return
    if zen_campaign_active:
        _zen_campaign_save_game()
        return
    if challenge_active:
        # Settings may be saved during a puzzle, but NEVER replace the classic save.
        if not SaveManager.save_data(data): notify_user("Speichern fehlgeschlagen: Speicherplatz prüfen.")
        return
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
    if help_text != null: help_text.text = toast
func on_cell(cell: int) -> void:
    if cell < 0 or ceremony_active or (popup != null and not net_active): return
    if act_one_active:
        if board.winner == 0 and board.turn == 1 and not ai_running and not chronicles.is_open():
            place(cell)
        return
    if board.winner != 0 and not challenge_active: return
    if zen_campaign_active:
        if not _zen_campaign_bot_turn() and not ai_running and not chronicles.is_open():
            place(cell)
        return
    if challenge_active:
        challenge_try_cell(cell)
        return
    if ai_running or (tutorial == null and int(data.settings.mode) == 1 and board.current_owner() == 1): return
    if tutorial != null:
        if tutorial.step in [0,5,6]: return
        if tutorial.step in [2,3,4] and (not preview.has(cell) or board.cells[cell] != 0):
            notify_user("Tippe das freie, markierte Feld an.")
            return
    place(cell)
func place(cell: int) -> void:
    if ceremony_active: return
    if challenge_active and not zen_campaign_active and not act_one_active:
        challenge_try_cell(cell)
        return
    var placed_by_owner: int = board.current_owner()
    if not rules.play(board,cell):
        if board.swap_pending: notify_user("Zuerst X übernehmen oder O behalten wählen.")
        return
    renderer.selected = cell
    generation += 1
    play_sound(board.winner != 0)
    if act_one_active:
        if placed_by_owner == 0: vibrate_on_move()
        if board.winner != 0 and not board.win_lines.is_empty(): focus_line(board.win_lines[0])
        _act_one_save()
        refresh(cell)
        if board.winner != 0: _act_one_result()
        return
    if zen_campaign_active:
        _zen_campaign_after_move(cell, placed_by_owner)
        return
    if placed_by_owner == 0 or int(data.settings.mode) == 0:
        vibrate_on_move()
    if board.winner != 0:
        if tutorial == null and int(data.settings.mode) != 2: record_result()
        if not board.win_lines.is_empty(): focus_line(board.win_lines[0])
    refresh(cell)
    if board.winner != 0 and tutorial == null and int(data.settings.mode) != 2:
        call_deferred("show_result_screen")
func record_result() -> void:
    if board.result_recorded: return
    last_rank_up = {"rank_up": false, "new_rank": int(data.ascension.rank)}
    last_leaf_reward = 0
    completed_bot_level = clampi(int(data.settings.level),0,4) if int(data.settings.mode) == 1 else -1
    board.result_recorded = true
    ceremony_done_for_match = false
    data.stats.played += 1
    if bool(data.settings.alternate): data.settings.next_start = 1-board.starter_owner
    if board.winner == 3:
        data.stats.draw += 1
        data.stats.starter_draws += 1
        if int(data.settings.mode) == 1:
            last_rank_up = Asc.record_match(data, clampi(int(data.settings.level),0,4), 0)
    else:
        var owner = int(board.owners[board.winner-1])
        if owner == board.starter_owner: data.stats.starter_wins += 1
        else: data.stats.second_wins += 1
        data.stats["p1" if owner == 0 else "p2"] += 1
        if int(data.settings.mode) == 1:
            var difficulty: int = clampi(int(data.settings.level),0,4)
            # Ascension evaluates the result BEFORE the win counter changes.
            # A loss resets only the active unfinished streak exam.
            last_rank_up = Asc.record_match(data, difficulty, 1 if owner == 0 else -1)
            data.stats["ai_wins" if owner == 0 else "ai_losses"][difficulty] += 1
            if owner == 0:
                last_leaf_reward = Collection.reward_bot(data, difficulty)
            else:
                last_leaf_reward = Collection.reward_loss(data)
    # Change the next default opponent only if an actual new Zen rank was earned.
    # Older manually chosen levels remain selectable at any time.
    BotAuto.apply_after_rank_up(data,last_rank_up)
func resolve_swap(accept: bool) -> void:
    if rules.swap(board,accept):
        generation += 1
        refresh()
func new_game() -> void:
    if act_one_active: return
    if zen_campaign_active: return
    ceremony_done_for_match = false
    completed_bot_level = -1
    if challenge_active:
        leave_challenges()
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
    if act_one_active: return
    if zen_campaign_active: return
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
    if act_one_active: return
    if zen_campaign_active:
        _zen_campaign_undo()
        return
    if challenge_active:
        challenge_restart()
        return
    if tutorial != null:
        load_tutorial()
        return
    if board.result_recorded or board.winner != 0:
        notify_user("Abgeschlossene Ergebnisse bleiben erhalten. Starte eine neue Partie.")
        return
    generation += 1
    if rules.undo(board):
        if int(data.settings.mode) == 1:
            while not board.history.is_empty() and (board.current_owner() == 1 or board.swap_pending): rules.undo(board)
        preview = []
        renderer.selected = -1
        refresh()
func _process(delta: float) -> void:
    if data == null: return
    var reading: bool = chronicles.is_open()
    if worker != null and not worker.is_alive():
        var move = worker.wait_to_finish()
        worker = null
        ai_running = false
        var turn_open: bool = not reading and popup == null and board.winner == 0 and not board.swap_pending
        var can_play := not zen_campaign_paused if zen_campaign_active else (not challenge_active and tutorial == null)
        if act_one_active: can_play = not zen_campaign_paused and board.turn == 2
        if worker_generation == generation and turn_open and can_play:
            place(int(move))
        else:
            refresh(-1, false)
    if act_one_active:
        _act_one_tick()
        return
    if zen_campaign_active:
        _zen_campaign_tick(delta)
        return
    if reading or challenge_active or tutorial != null or popup != null or int(data.settings.mode) != 1 or board.winner != 0: return
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
        var budgets: Array = [45, 95, 200, 330, 520]
        var budget: int = int(budgets[clampi(level,0,4)])
        worker.start(func(): return AIEngine.new(seed_value).choose(cells, player, level, budget))
        refresh()
func _exit_tree() -> void:
    if worker != null: worker.wait_to_finish()
var shop_page: int = 0
var shop_tab: int = 0 # 0 = Skins, 1 = Musik, 2 = Kulissen, 3 = Hints
var music_preview_player: AudioStreamPlayer
var music_preview_generation: int = 0
const NEW_MUSIC_STREAMS = [
    preload("res://assets/music/cyberwave_main.mp3"),
    preload("res://assets/music/zen_piano.mp3"),
    preload("res://assets/music/velario_zen.mp3"),
    preload("res://assets/music/nature_wonder.mp3"),
    preload("res://assets/music/calm_spirit.mp3"),
    preload("res://assets/music/zen_of_nature.mp3"),
    preload("res://assets/music/sitar_story.mp3"),
]
const NEW_MUSIC_TITLES = ["Whispers of the Ancient Forest", "Echoes of a Forgotten Dream", "The Path of Serenity", "Where the Waters Sleep", "Spirit of the Jade River", "A Thousand Silent Skies", "Tales Beneath the Golden Sun"]
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
    popup.add_theme_stylebox_override("panel",UiTest.frame(Color("#f9edd5",0.985),24,3))
    popup.modulate.a = 0.0
    popup.create_tween().tween_property(popup,"modulate:a",1.0,0.18)
    var scroll = ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.scroll_deadzone = 12 # touchscreen gesture threshold, avoid accidental buying
    scroll.follow_focus = false
    scroll.mouse_filter = Control.MOUSE_FILTER_STOP
    popup.add_child(scroll)
    var box = VBoxContainer.new()
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_theme_constant_override("separation",12)
    scroll.add_child(box)
    var title_label: Label = label(title,box,24,Color("#263c2d"))
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title_label.name = "ZenGoldModalHeading"
    title_label.add_theme_font_override("font",ZenType.heading())
    if menu_context:
        button("Zum Hauptmenü",box,open_menu,true)
    else:
        button("Zurück zum Spiel",box,close_modal,true)
    var line: ColorRect = ColorRect.new()
    line.name = "ZenGoldDivider"
    line.color = UiTest.GOLD
    line.custom_minimum_size.y = 2
    line.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(line)
    return box
func close_modal() -> void:
    stop_shop_preview()
    net_active = false
    net_buttons.clear()
    if popup != null:
        popup.queue_free()
        popup = null
    if home_visible:
        home_visible = false
        column.show()
func open_menu() -> void:
    if act_one_active:
        if board.winner != 0:
            _act_one_result()
        else:
            var trial_menu := _zen_campaign_story_box(_act_one_title())
            premium_button(_act_one_ui("Fortsetzen", "Resume", "Retomar"), trial_menu, close_modal, true)
            button(_act_one_ui("Zur Geschichte", "Back to story", "Voltar à história"), trial_menu, _act_one_leave, true)
        return
    if zen_campaign_active:
        if board.winner != 0:
            _zen_campaign_present()
            return
        var campaign_box := _zen_campaign_story_box(_campaign_text("title"))
        _zen_campaign_paragraph(campaign_box, ZenCampaign.demon_name(language_code(), zen_campaign_stage))
        premium_button(_campaign_text("resume"), campaign_box, _zen_campaign_begin, true)
        button(_campaign_text("leave"), campaign_box, _zen_campaign_leave, true)
        return
    menu_context = true
    var box: VBoxContainer = modal("Hauptmenü")
    for child in box.get_children():
        box.remove_child(child)
        child.queue_free()
    popup.name = "HomeScreen"
    popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var backdrop: StyleBoxFlat = theme_style(Color("10271f", 0.80), 0)
    backdrop.set_border_width_all(0)
    backdrop.shadow_size = 0
    backdrop.content_margin_left = 26
    backdrop.content_margin_right = 26
    backdrop.content_margin_top = 18
    backdrop.content_margin_bottom = 18
    popup.add_theme_stylebox_override("panel", backdrop)
    var home: VBoxContainer = HomeMenu.new()
    box.add_child(home)
    home.configure(self)
    column.hide()
    home_visible = true

func resume_current_match() -> void:
    menu_context = false
    close_modal()
    refresh(-1, false)

func open_story_library() -> void:
    chronicles.open_library()

func resume_campaign() -> void:
    if tutorial != null:
        tutorial_return_to_campaign = false
        end_tutorial()
    var step: Dictionary = Journey.next_step(data)
    if not bool(data.settings.get("campaign_intro_seen", false)) and not bool(step.started) and int(data.stats.played) == 0:
        open_campaign_introduction()
        return
    if str(step.kind) == "story":
        # The reader loads its own saved page and boss checkpoint.
        chronicles.call(["open_act_one", "open_act_two", "open_act_three", "open_act_four"][int(step.act) - 1])
        return
    if str(step.kind) == "realms":
        if not FractureState.awakening_seen():
            chronicles.open_act_four()
            return
        const RealmPath = preload("res://core/ZenRealmCampaign2.gd")
        var openers: Array[String] = ["open_shadow_reader", "open_abyss_reader", "open_ember_campaign_preview", "open_celestial_campaign_preview", "open_satori_campaign_preview"]
        for realm in range(openers.size()):
            if not RealmPath.story_finished(realm):
                chronicles.call(openers[realm])
                return
        chronicles.open_library()
        return
    var same_match: bool = not challenge_active and tutorial == null and int(data.settings.mode) == 1 and board.winner == 0 and board.move_count() > 0 and int(data.settings.level) == int(step.level) and int(data.ascension.world) == int(step.world)
    if same_match:
        resume_current_match()
        return
    if board.winner == 0 and board.move_count() > 0 and not challenge_active:
        var confirm: VBoxContainer = modal("Kampagne fortsetzen")
        label("Für die nächste Aufgabe beginnt eine neue Partie. Deine aktuelle Partie ist noch offen.", confirm, 16)
        premium_button("Partie fortsetzen", confirm, resume_current_match, true)
        premium_button("Kampagnenpartie starten", confirm, _start_journey_match.bind(step))
        return
    _start_journey_match(step)

func _start_journey_match(step: Dictionary) -> void:
    if challenge_active: leave_challenges()
    if tutorial != null: end_tutorial()
    data.ascension.world = int(step.world)
    data.settings.next_start = 0
    start_mode(1, int(step.level))

func open_campaign_introduction() -> void:
    var box: VBoxContainer = modal("Dein erster Zug")
    label("1. Drehe den Würfel.", box, 19)
    label("2. Tippe ein freies Feld, um dein Zeichen zu setzen.", box, 19)
    label("3. Verbinde vier gleiche Zeichen über eine Würfelkante.", box, 19)
    premium_button("Kurz ausprobieren", box, _begin_campaign_tutorial, true)
    button("Überspringen und Kampagne starten", box, _accept_campaign_introduction, true)

func _accept_campaign_introduction() -> void:
    data.settings.campaign_intro_seen = true
    data.settings.intro_seen = true
    persist()
    resume_campaign()

func _begin_campaign_tutorial() -> void:
    data.settings.campaign_intro_seen = true
    data.settings.intro_seen = true
    persist()
    start_tutorial()
    tutorial_quick = true
    tutorial_return_to_campaign = true
    var finish: Button = tutorial_row.get_child(2) as Button
    finish.text = T("Kampagne fortsetzen")
    finish.set_meta("zen_source_text", "Kampagne fortsetzen")
    refresh()

func open_game_modes() -> void:
    var box: VBoxContainer = modal("Spielmodi")
    premium_button("Freies Spiel", box, open_play_menu, true)
    premium_button("Zen Challenges · 100 Aufgaben", box, begin_challenges)
    premium_button("Zwei Spieler lokal", box, func(): start_mode(0, 0))
    button("Training", box, func(): start_mode(2, 0), true)
    if _ascend_revealed():
        premium_button("Zen Ascend", box, open_ascend_intro)

func open_profile() -> void:
    Asc.ensure(data)
    var box: VBoxContainer = modal("Profil")
    label(T(Asc.RANKS[int(data.ascension.rank)]), box, 24)
    premium_button("Zen-Aufstieg", box, open_ascension, true)
    premium_button("Welten", box, open_worlds)
    premium_button("Statistik", box, open_stats)
    if _ascend_revealed():
        premium_button("Erfolge", box, open_achievements)

func open_achievements() -> void:
    if not _ascend_revealed():
        open_profile()
        return
    var box: VBoxContainer = modal("Erfolge")
    # Read-only view of the same earned achievements used inside Zen Ascend.
    var account: Dictionary = data.duplicate(true)
    label(T("Geheime Erfolge: %d/%d") % [ProfileAchievements.secret_count(account), ProfileAchievements.SECRETS.size()], box, 20)
    for realm in range(4):
        if not ProfileRealms.unlocked(account, realm): continue
        label(ProfileRealms.realm_name(realm, language_code()), box, 21)
        for secret in ProfileAchievements.SECRETS:
            if int(secret.realm) != realm: continue
            var earned: bool = ProfileAchievements.earned(account, str(secret.id))
            var name_text: String = str(secret.name) if earned else T("Geheimer Erfolg")
            label(("✓ " if earned else "◇ ") + name_text, box, 16)

func open_store() -> void:
    Collection.ensure(data)
    var box = modal("Zen-Shop")
    label(T("Deine Zen-Blätter: 🍃 %d") % int(data.economy.leaves), box, 20, Color("50663e"))
    var tab_bar: HBoxContainer = row(box)
    var skins_tab: Button = button(T("Skins"), tab_bar, func(): change_shop_tab(0), true, shop_tab == 0)
    var music_tab: Button = button("Musik", tab_bar, func(): change_shop_tab(1), true, shop_tab == 1)
    var backdrops_tab: Button = button("Kulissen", tab_bar, func(): change_shop_tab(2), true, shop_tab == 2)
    var hints_tab: Button = button("Hints", tab_bar, func(): change_shop_tab(3), true, shop_tab == 3)
    for tab in [skins_tab, music_tab, backdrops_tab, hints_tab]:
        tab.add_theme_font_size_override("font_size", 12)
    skins_tab.disabled = shop_tab == 0
    music_tab.disabled = shop_tab == 1
    backdrops_tab.disabled = shop_tab == 2
    hints_tab.disabled = shop_tab == 3
    if shop_tab == 3:
        store_hint_section(box)
        button("Zum Hauptmenü", box, open_menu, true)
        return
    if shop_tab == 2:
        store_background_section(box)
        button("Zum Hauptmenü", box, open_menu, true)
        return
    if shop_tab == 1:
        label("Höre neue Musik an und schalte sie dauerhaft mit Zen-Blättern frei.", box, 13)
        store_music_section(box)
        button("Zum Hauptmenü", box, open_menu, true)
        return
    label("Gewinne gegen den Zen-Bot oder löse neue Challenges. Stärkere Bots geben mehr Blätter.", box, 13)
    var rewards: String = ""
    for i in range(5):
        if i > 0: rewards += "  ·  "
        rewards += T(Asc.LEVELS[i]) + ": +" + str(Collection.BOT_REWARDS[i])
    label(rewards, box, 12)
    label("Holz, Stein, Marmor oder Glas: Jede Oberfläche sieht anders aus. Die 108 Gewinnlinien bleiben gleich.", box, 13)
    label("Zen Ascend",box,20,Color("526943"))
    label(_act_one_ui("Wird nach dem Sieg über Dark Kuze in Akt IV freigeschaltet.",
        "Unlocks after defeating Dark Kuze in Act IV.",
        "Desbloqueia após derrotares Dark Kuze no Ato IV."),box,13)
    if ZMode.unlocked(data):
        button(ZMode.t("Zen Ascend ausprobieren",language_code()),box,open_ascend_intro,true,true)
    else:
        button(_act_one_ui("Zen Chronicles öffnen","Open Zen Chronicles","Abrir Zen Chronicles"),box,func(): chronicles.open_library(),true)
    shop_page = clampi(shop_page, 0, 3)
    store_page_buttons(box)
    for i in range(shop_page * 5, mini((shop_page + 1) * 5, Collection.SKINS.size())):
        var skin_id: int = i
        var skin: Dictionary = Collection.SKINS[i]
        var card: PanelContainer = PanelContainer.new()
        card.add_theme_stylebox_override("panel", theme_style(Color("fff0d9", 0.96), 12))
        card.mouse_filter = Control.MOUSE_FILTER_PASS
        box.add_child(card)
        var inner: VBoxContainer = VBoxContainer.new()
        inner.mouse_filter = Control.MOUSE_FILTER_PASS
        card.add_child(inner)
        var card_row: HBoxContainer = row(inner)
        card_row.mouse_filter = Control.MOUSE_FILTER_PASS
        # Three swatches preview the REAL color/material preset used by the 3D cube.
        for face in [0, 2, 3]:
            var sample: ColorRect = ColorRect.new()
            sample.color = Color(str(skin.faces[face]))
            sample.custom_minimum_size = Vector2(28, 28)
            sample.mouse_filter = Control.MOUSE_FILTER_IGNORE
            card_row.add_child(sample)
        var material_thumb: TextureRect = TextureRect.new()
        material_thumb.texture = load("res://assets/skins/skin_%02d.webp" % i)
        material_thumb.custom_minimum_size = Vector2(56, 56)
        material_thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        material_thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        material_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card_row.add_child(material_thumb)
        var name_label: Label = label(T(str(skin.name)), card_row, 16, Color("4b3428"))
        name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var surface_note: Label = label(T(str(Collection.MATERIALS[i])), inner, 12, Color("776250"))
        var owned: bool = data.economy.owned.has(i)
        var equipped: bool = int(data.economy.equipped) == i
        var title: String = ""
        if equipped: title = "✓ " + T("Ausgerüstet")
        elif owned: title = T("Skin verwenden")
        else: title = T("Kaufen für 🍃 %d") % int(skin.price)
        var skin_button: Button = button(title, inner, func(): store_select_skin(skin_id), true, equipped)
        # Important on Android: swipes starting ON the button also reach the ScrollContainer.
        skin_button.mouse_filter = Control.MOUSE_FILTER_PASS
        skin_button.disabled = equipped or (not owned and int(data.economy.leaves) < int(skin.price))
        skin_button.add_theme_color_override("font_disabled_color", Color("42372d"))
        skin_button.add_theme_stylebox_override("disabled", theme_style(Color("e7dfd0"), 12))
    store_page_buttons(box)
    button("Zum Hauptmenü", box, open_menu, true)

func change_shop_tab(index: int) -> void:
    shop_tab = clampi(index, 0, 3)
    open_store()

func store_hint_section(parent: VBoxContainer) -> void:
    ZenAscendAchievements.ensure(data)
    label("Secret Achievement Hints",parent,19,Color("526943"))
    label("A purchased hint stays with you. Achievements must still be earned in battle.",parent,13)
    label("Zen Leaves: 🍃 %d" % int(data.economy.leaves),parent,14)
    for secret in ZenAscendAchievements.SECRETS:
        var key: String = str(secret.id)
        var earned: bool = ZenAscendAchievements.earned(data,key)
        var hint_bought: bool = ZenAscendAchievements.hint_owned(data,key)
        var card: PanelContainer = PanelContainer.new()
        card.add_theme_stylebox_override("panel",theme_style(Color("fff0d9",0.96),12))
        card.mouse_filter = Control.MOUSE_FILTER_PASS
        parent.add_child(card)
        var inside: VBoxContainer = VBoxContainer.new()
        inside.add_theme_constant_override("separation",6)
        card.add_child(inside)
        label(str(secret.name) if earned else "??? · " + str(ZenAscendRealms.REALM_NAMES[int(secret.realm)]),inside,16,Color("4b3428"))
        if earned:
            label("✓ Achievement unlocked",inside,13,Color("4b7848"))
        elif hint_bought:
            label("🍃 Hint: " + ZenAscendAchievements.hint_text(key),inside,14,Color("596b46"))
        else:
            var buy_button: Button = button("Buy a hint · 🍃 %d" % ZenAscendAchievements.HINT_PRICE,inside,func(): store_buy_hint(key),true)
            buy_button.mouse_filter = Control.MOUSE_FILTER_PASS
            buy_button.disabled = int(data.economy.leaves) < ZenAscendAchievements.HINT_PRICE

func store_buy_hint(key: String) -> void:
    if not ZenAscendAchievements.buy_hint(data,key):
        notify_user("Not enough Zen Leaves, or hint already owned.")
        return
    persist()
    open_store()

func store_background_section(parent: VBoxContainer) -> void:
    Backdrops.ensure(data)
    label("Wähle einen Hintergrund für deine Zen-Welt. Die aktuelle Welt und der Bot bleiben unverändert.", parent, 13)
    var chosen: int = Backdrops.selected(data)
    var world_button: Button = button("✓ Welt-Hintergrund aktiv" if chosen == -1 else "Welt-Hintergrund verwenden", parent, use_world_background, true)
    world_button.disabled = chosen == -1
    for i in range(Backdrops.ITEMS.size()):
        var idx: int = i
        var item: Dictionary = Backdrops.ITEMS[i]
        var card: PanelContainer = PanelContainer.new()
        card.mouse_filter = Control.MOUSE_FILTER_PASS
        card.add_theme_stylebox_override("panel",theme_style(Color("fff0d9",0.96),12))
        parent.add_child(card)
        var inner: VBoxContainer = VBoxContainer.new()
        inner.mouse_filter = Control.MOUSE_FILTER_PASS
        card.add_child(inner)
        label(str(item.name),inner,17,Color("4b3428"))
        var art: TextureRect = TextureRect.new()
        art.texture = load(str(item.path))
        art.custom_minimum_size = Vector2(0,152)
        art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        art.mouse_filter = Control.MOUSE_FILTER_IGNORE
        inner.add_child(art)
        var owned: bool = Backdrops.is_owned(data,idx)
        var selected: bool = chosen == idx
        var caption: String = "✓ Aktiv" if selected else "Hintergrund verwenden" if owned else "Hintergrund freischalten für 🍃 %d"
        var action_text: String = T(caption) % int(item.price) if not owned else T(caption)
        var buy_button: Button = button(action_text,inner,func(): store_select_background(idx),true,selected)
        buy_button.mouse_filter = Control.MOUSE_FILTER_PASS
        buy_button.disabled = selected or (not owned and int(data.economy.leaves) < int(item.price))

func use_world_background() -> void:
    if not Backdrops.equip(data,-1): return
    refresh()
    persist()
    open_store()

func store_select_background(idx: int) -> void:
    Backdrops.ensure(data)
    if not Backdrops.is_owned(data,idx) and not Backdrops.purchase(data,idx):
        notify_user("Nicht genug Zen-Blätter.")
        return
    if not Backdrops.equip(data,idx): return
    refresh()
    persist()
    open_store()

func store_music_section(parent: VBoxContainer) -> void:
    # Music and skins are separate scrollable tabs, not a mixed catalog.
    var titles: Array = ["Zen-Garten (Original)", "Klangschalen – Stiller Tempel", "Handpan – Sanfter Rhythmus", "Nebelpfad", "Stein und Wasser", "Regentropfen im Zen-Garten", "Sternenlicht am Tempel"] + NEW_MUSIC_TITLES
    # Shop offers only purchasable or purchased tracks. Base/world songs remain bundled.
    var display_order: Array = [5, 6, 8, 9, 10, 11, 12, 13]
    label("Freischaltbare Musik", parent, 17, Color("526943"))
    for track in display_order:
        var track_id: int = int(track)
        var owned: bool = Collection.music_unlocked(data, track_id)
        var chosen: bool = MusicPolicy.mode(data) == "manual" and int(data.settings.get("music_track", 7)) == track_id
        var card: PanelContainer = PanelContainer.new()
        card.mouse_filter = Control.MOUSE_FILTER_PASS
        card.add_theme_stylebox_override("panel", theme_style(Color("fff0d9",0.96),12))
        parent.add_child(card)
        var inner: VBoxContainer = VBoxContainer.new()
        inner.mouse_filter = Control.MOUSE_FILTER_PASS
        card.add_child(inner)
        label(T(str(titles[track_id])), inner, 16, Color("4b3428"))
        # Stack buttons so long localized labels fit narrow Android screens.
        var listen: Button = button(T("▶ Probe hören (12 Sek.)"), inner, func(): preview_shop_music(track_id), true)
        listen.mouse_filter = Control.MOUSE_FILTER_PASS
        var caption: String = ""
        if chosen:
            caption = "✓ " + T("Ausgewählt")
        elif owned:
            caption = T("Musik auswählen")
        else:
            caption = T("Musik freischalten für 🍃 %d") % Collection.music_price(track_id)
        var action: Button = button(caption, inner, func(): store_select_music(track_id), true, chosen)
        action.mouse_filter = Control.MOUSE_FILTER_PASS
        action.disabled = chosen or (not owned and int(data.economy.leaves) < Collection.music_price(track_id))
        action.add_theme_color_override("font_disabled_color",Color("42372d"))
        action.add_theme_stylebox_override("disabled", theme_style(Color("e7dfd0"),12))

func stop_shop_preview() -> void:
    music_preview_generation += 1
    if music_preview_player != null:
        music_preview_player.stop()
    if music_player != null:
        music_player.stream_paused = false
    if music_fade_player != null:
        music_fade_player.stream_paused = false

func preview_shop_music(track: int) -> void:
    # A 12-second preview does NOT purchase or unlock the track.
    stop_shop_preview()
    if music_preview_player == null:
        return
    music_preview_player.stream = music_stream(track)
    if music_preview_player.stream == null:
        notify_user("Musik konnte nicht geladen werden.")
        return
    if music_player != null:
        music_player.stream_paused = true
    if music_fade_player != null:
        music_fade_player.stream_paused = true
    music_preview_player.play()
    var token: int = music_preview_generation
    get_tree().create_timer(12.0).timeout.connect(func():
        if token == music_preview_generation:
            stop_shop_preview()
    )

func store_select_music(track: int) -> void:
    Collection.ensure(data)
    if not Collection.music_unlocked(data, track):
        if not Collection.buy_music(data, track):
            notify_user("Nicht genug Zen-Blätter.")
            return
    stop_shop_preview()
    data.settings.music = true
    select_music_track(track)
    open_store()

func store_page_buttons(parent: VBoxContainer) -> void:
    var pager: HBoxContainer = row(parent)
    pager.mouse_filter = Control.MOUSE_FILTER_PASS
    var back: Button = button(T("Vorherige Skins") + " ◀", pager, func(): change_shop_page(-1), true)
    back.disabled = shop_page == 0
    var counter: Label = label(T("Seite %d von 4") % (shop_page + 1), pager, 13, Color("514232"))
    counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var forward: Button = button(T("Weitere Skins") + "  ▶", pager, func(): change_shop_page(1), true)
    forward.disabled = shop_page == 3
    for b in [back, forward]:
        b.mouse_filter = Control.MOUSE_FILTER_PASS
        b.add_theme_color_override("font_disabled_color", Color("5b5144"))
        b.add_theme_stylebox_override("disabled", theme_style(Color("e7dfd0"), 12))

func change_shop_page(delta: int) -> void:
    shop_page = clampi(shop_page + delta, 0, 3)
    open_store()

func store_select_skin(skin: int) -> void:
    Collection.ensure(data)
    if not data.economy.owned.has(skin):
        if not Collection.buy(data, skin):
            notify_user("Nicht genug Zen-Blätter.")
            return
    if Collection.equip(data, skin):
        renderer.apply_skin(skin)
        refresh()
        persist()
        open_store()

func open_play_menu() -> void:
    Asc.ensure(data)
    var box = modal("Freies Spiel")
    label("Gegen wen möchtest du spielen?", box, 16)
    for i in range(5):
        var lvl: int = i
        var source: String = "Zen-Bot · " + Asc.LEVELS[i]
        var b: Button = premium_button(source, box, func(): start_mode(1, lvl), i == int(data.ascension.rank))
        if not Asc.level_unlocked(data,i):
            b.disabled = true
            b.text += "  🔒"
        else:
            label(T("Sieg-Belohnung: 🍃 %d") % int(Collection.BOT_REWARDS[i]), box, 12)
    button("Spielmodi", box, open_game_modes, true)

func open_ascension() -> void:
    Asc.ensure(data)
    var box = modal("Zen-Aufstieg")
    label("Dein Zen-Rang",box,17)
    label(T(Asc.RANKS[int(data.ascension.rank)]),box,23,Color("5b704b"))
    label("Siege gegen Zen-Bots erhöhen deinen Rang. Neue Ränge schalten Welten frei.",box,14)
    label("Die ersten drei Prüfungen zählen Siege insgesamt. Danach brauchst du Siegesserien.",box,13)
    for i in range(5):
        var done: bool = bool(data.ascension.completed[i])
        var accessible: bool = i <= int(data.ascension.rank)
        var state: String = "✓ " if done else "○ " if accessible else "🔒 "
        label(state + T(Asc.RANKS[i+1]) + " · " + T(Asc.LEVELS[i]),box,16)
        var number: int = Asc.progress(data, i)
        var goal: int = Asc.target(i)
        var description: String = T("Geschafft") if done else (T("%d/%d Siege in Folge") if Asc.is_streak(i) else T("%d/%d Siege")) % [number, goal]
        label(description,box,14,Color("53643e") if done else Color("74614c"))
        var progress_bar = ProgressBar.new()
        progress_bar.max_value = float(goal)
        progress_bar.value = float(number)
        progress_bar.show_percentage = false
        progress_bar.custom_minimum_size.y = 9
        progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var track: StyleBoxFlat = StyleBoxFlat.new()
        track.bg_color = Color("e4d5b9")
        track.set_corner_radius_all(5)
        var fill: StyleBoxFlat = StyleBoxFlat.new()
        fill.bg_color = Color("667f53")
        fill.set_corner_radius_all(5)
        progress_bar.add_theme_stylebox_override("background",track)
        progress_bar.add_theme_stylebox_override("fill",fill)
        box.add_child(progress_bar)
    label("Der Zen-Wächter ist die letzte Rangprüfung. Es gibt fünf Welten.",box,13)
    if _ascend_revealed():
        button("Zen Ascend",box,open_ascend_intro,true)
    button("Welten ansehen",box,open_worlds,true)
    button("Spielen",box,open_play_menu,true,true)

func world_unlock_info(world: int) -> String:
    # World 0 is free; worlds 1..4 are cosmetic rewards for completing
    # the previous Ascension exam. No change to the game rules or difficulty.
    if world <= 0:
        return T("Von Anfang an verfügbar")
    var exam: int = world - 1
    var needed: int = Asc.target(exam)
    var done: int = Asc.progress(data, exam)
    var opponent: String = T(Asc.LEVELS[exam])
    var requirement: String = (T("%d Siege in Folge gegen %s") if Asc.is_streak(exam) else T("%d Siege gegen %s")) % [needed, opponent]
    var current: String = (T("%d/%d Siege in Folge") if Asc.is_streak(exam) else T("%d/%d Siege")) % [done, needed]
    return T("Freischaltung: ") + requirement + "  ·  " + current

func open_worlds() -> void:
    Asc.ensure(data)
    var box = modal("Welten")
    label("Welten ändern nur das Aussehen. Dein Rang steigt durch Siege gegen den Zen-Bot.", box, 14)
    label("Neue Welten schaltest du über Zen Ascension frei.", box, 13)
    label(_act_one_ui("Bot-Schwierigkeit und Welt sind unabhängig. Schwierigkeit unter Spielen oder Einstellungen ändern.", "Worlds change the scenery only. Change bot difficulty under Play or Settings.", "Os mundos mudam apenas o cenário. Altera a dificuldade do bot em Jogar ou Definições."),box,13)
    for i in range(5):
        var number: int = i
        var card: PanelContainer = PanelContainer.new()
        var card_style: StyleBoxFlat = theme_style(Color("fff2dc", 0.97), 14)
        card_style.content_margin_top = 7
        card_style.content_margin_bottom = 7
        card.add_theme_stylebox_override("panel", card_style)
        box.add_child(card)
        var card_row: HBoxContainer = row(card)
        # Only scenery is painted here. The playable cube is always rendered
        # separately by CubeRenderer on the unchanged 54-cell SubViewport.
        var thumbnail: TextureRect = TextureRect.new()
        thumbnail.texture = Asc.WORLD_TEXTURES[i]
        thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        thumbnail.custom_minimum_size = Vector2(90, 104)
        thumbnail.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card_row.add_child(thumbnail)
        var info: VBoxContainer = VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        info.add_theme_constant_override("separation", 1)
        card_row.add_child(info)
        label(T(Asc.WORLD_SUBTITLES[i]), info, 12, Color("6f5940"))
        var b: Button = button(T(Asc.WORLDS[i]), info, func(): select_world(number), true, i == int(data.ascension.world))
        b.disabled = not Asc.world_unlocked(data, i)
        if b.disabled:
            b.text += "  🔒"
            label(world_unlock_info(i), info, 12, Color("6c5141"))
        elif i == int(data.ascension.world):
            label("Ausgewählt", info, 12, Color("526943"))
        else:
            label("Freigeschaltet", info, 12, Color("526943"))
    button("Rang & Fortschritt", box, open_ascension, true, true)
    button("Zum Hauptmenü", box, open_menu, true)

func select_world(number: int) -> void:
    if not Asc.world_unlocked(data,number): return
    data.ascension.world = number
    close_modal()
    refresh()

# The newly selected world track may still be at -54 dB at the moment of promotion.
# Freeze its crossfade BEFORE the gong; don't capture an unfinished fade level.
func prepare_rank_music() -> void:
    if music_transition != null and music_transition.is_running():
        music_transition.kill()
    if music_fade_player != null and music_fade_player.playing:
        music_fade_player.stop()

func restore_rank_music() -> void:
    if not bool(data.settings.get("music", false)):
        return
    if music_transition != null and music_transition.is_running():
        music_transition.kill()
    if music_fade_player != null and music_fade_player.playing:
        music_fade_player.stop()
    if music_player != null:
        music_player.stream_paused = false
        music_player.volume_db = -2.0
        if not music_player.playing:
            sync_music()

func _continue_newly_unlocked_story() -> void:
    var act: int = _newly_unlocked_story_act()
    if act==0: return
    close_modal()
    if act==2: chronicles.open_act_two()
    elif act==3: chronicles.open_act_three()
    elif act==4: chronicles.open_act_four()

func _newly_unlocked_story_act() -> int:
    if not bool(last_rank_up.get("rank_up",false)): return 0
    var rank_after: int = int(data.ascension.rank)
    if rank_after==1 and ActTwo.unlocked(data) and ActTwo.media_ready(): return 2
    if rank_after==2 and ActThree.unlocked(data) and ActThree.media_ready(): return 3
    if rank_after==3 and ActFour.unlocked(data) and ActFour.media_ready(): return 4
    return 0

func show_result_screen() -> void:
    if act_one_active:
        _act_one_result()
        return
    if zen_campaign_active: return
    # Called deferred after a real Classic match finishes. A new match cancels it.
    if challenge_active or tutorial != null or board.winner == 0 or popup != null:
        return
    if int(data.settings.mode) == 2:
        return
    # Rank-up is already persisted by record_result(); this is visual only.
    # Never replay the ceremony on reopening results or loading a previous rank.
    if bool(last_rank_up.get("rank_up",false)) and not ceremony_done_for_match:
        ceremony_done_for_match = true
        ceremony_active = true
        var celebration: ZenRankCeremony = RANK_CEREMONY.new()
        add_child(celebration)
        celebration.finished.connect(func():
            ceremony_active = false
            if is_inside_tree():
                restore_rank_music()
                call_deferred("show_result_screen")
        )
        prepare_rank_music()
        celebration.present(int(data.ascension.rank),language_code(),bool(data.settings.sound),[music_player,music_fade_player])
        return
    var human_win: bool = false
    if board.winner in [1, 2]:
        human_win = int(board.owners[board.winner-1]) == 0
    var versus_bot: bool = int(data.settings.mode) == 1
    var level: int = completed_bot_level if completed_bot_level >= 0 else int(data.settings.level)
    var special: bool = versus_bot and human_win and (bool(last_rank_up.get("rank_up",false)) or level == 4)
    var headline: String = "Unentschieden"
    if board.winner != 3:
        if special:
            headline = "Zen erreicht!"
        elif human_win or not versus_bot:
            headline = "Gewonnen!"
        else:
            headline = "Verloren"
    var box = modal(headline)
    # Let the actual 3D winning line stay visible above the results panel.
    # ~20% less height for normal results; preserve extra text room on rank-up.
    popup.anchor_top = 0.52 if special else 0.56
    popup.anchor_bottom = 0.97
    popup.offset_top = 0
    box.add_theme_constant_override("separation",7)
    popup.add_theme_stylebox_override("panel", theme_style(Color("342820", 0.985), 25))
    var heading: Label = box.get_child(0) as Label
    box.get_child(1).hide()
    heading.add_theme_color_override("font_color", Color("f8dfaa"))
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    if special:
        var unlocked_rank: String = T(Asc.RANKS[int(data.ascension.rank)])
        var award: Label = label(unlocked_rank,box,21,Color("edd18e"))
        award.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        if bool(last_rank_up.get("rank_up",false)):
            label("Neuer Zen-Rang freigeschaltet!",box,15,Color("fff1d6"))
            var rank_after: int = int(data.ascension.rank)
            if rank_after >= 1 and rank_after < Asc.WORLDS.size():
                label(T("Neue Welt freigeschaltet: %s") % T(Asc.WORLDS[rank_after]),box,15,Color("e7d3aa"))
            else:
                label("Zen-Wächter erreicht – höchste Rangstufe!",box,15,Color("e7d3aa"))
            # The next dimension is revealed only after the Moon Garden finale.
            # Unlock ownership remains unchanged.
    elif board.winner in [1, 2]:
        var winning_symbol: String = "X" if board.winner == 1 else "O"
        var summary: String = ""
        if versus_bot:
            summary = (T("Du hast als %s gewonnen.") if human_win else T("Zen-Bot gewinnt mit %s.")) % winning_symbol
        else:
            var winner_owner: int = int(board.owners[board.winner - 1])
            summary = T("%s gewinnt mit %s.") % [player_name(winner_owner), winning_symbol]
        var symbol_label: Label = label(summary, box, 17, Color("ead3aa"))
        symbol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    if versus_bot and last_leaf_reward > 0:
        var reward_text: Label = label(T("Belohnung: +%d Zen-Blätter 🍃") % last_leaf_reward, box, 17, Color("d3e5b6"))
        reward_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var story_act: int = _newly_unlocked_story_act()
    if story_act>0:
        var story_button: Button = premium_button(_act_one_ui("📖 Geschichte fortsetzen · Akt %d","📖 Continue Story · Act %d","📖 Continuar história · Ato %d") % story_act,box,_continue_newly_unlocked_story,true)
        story_button.name = "NewlyUnlockedActStory"
    var inspect: Button = premium_button("Spielfeld ansehen",box,_inspect_classic_finished_board,true)
    inspect.text = _inspect_label()
    inspect.name = "InspectClassicFinishedBoard"
    premium_button("Noch eine Partie", box, play_again_after_result)
    premium_button("Hauptmenü", box, open_menu)

func _inspect_label() -> String:
    return "Spielfeld ansehen" if language_code()=="de" else ("Ver tabuleiro" if language_code()=="pt" else "Inspect board")

func _classic_result_label() -> String:
    return "Ergebnis anzeigen" if language_code()=="de" else ("Ver resultado" if language_code()=="pt" else "Show result")

func _inspect_classic_finished_board() -> void:
    if board.winner == 0: return
    close_modal()
    input_control.fingers.clear()
    input_control.press_cell = -1
    input_control.dragged = false
    input_control.mouse_down = false

func play_again_after_result() -> void:
    close_modal()
    new_game()

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
    for i in range(5): label("%s: %d / %d" % [T(Asc.LEVELS[i]),data.stats.ai_wins[i],data.stats.ai_losses[i]],box)
    var name_a: String = str(data.settings.names[0])
    var name_b: String = str(data.settings.names[1])
    var total_classic: int = maxi(1,int(data.stats.played))
    var classic_win_rate: float = float(data.stats.p1)*100.0/float(total_classic)
    # Two compact premium overview cards make long-form statistics scannable.
    var summary_card: PanelContainer = PanelContainer.new()
    summary_card.add_theme_stylebox_override("panel",theme_style(Color("f7e6ca",0.98),16))
    box.add_child(summary_card)
    var summary_stack: VBoxContainer = VBoxContainer.new()
    summary_card.add_child(summary_stack)
    label(ZMode.t("Spieler 1",language_code()) + ": " + name_a + "   ·   " + ZMode.t("Spieler 2",language_code()) + ": " + name_b,summary_stack,17,Color("4d6245"))
    label(ZMode.t("Siegquote",language_code()) + " (" + name_a + "): %.1f%%" % classic_win_rate,summary_stack,14)
    var classic_bar: ProgressBar = ProgressBar.new()
    classic_bar.max_value = 100.0
    classic_bar.value = classic_win_rate
    classic_bar.show_percentage = false
    classic_bar.custom_minimum_size.y = 12
    classic_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    summary_stack.add_child(classic_bar)
    var stat_detail: String = "%s: %d  ·  %s: %d" % [name_a,int(data.stats.p1),name_b,int(data.stats.p2)]
    label(stat_detail,box,16)
    label(ZMode.t("Siegquote",language_code()) + " (" + name_a + "): %.1f%%" % classic_win_rate,box,14)
    label(ZMode.t("Zen-Rang",language_code()) + ": " + T(Asc.RANKS[int(data.ascension.rank)]),box,18,Color("526943"))
    if int(data.ascension.rank) < 5:
        var next_exam: int = int(data.ascension.rank)
        var progress: int = Asc.progress(data,next_exam)
        label(ZMode.t("Nächste Rangprüfung",language_code()) + ": " + T(Asc.LEVELS[next_exam]) + "  ·  %d/%d" % [progress,Asc.target(next_exam)],box,14)
        var rank_bar: ProgressBar = ProgressBar.new()
        rank_bar.max_value = float(Asc.target(next_exam))
        rank_bar.value = float(progress)
        rank_bar.show_percentage = false
        rank_bar.custom_minimum_size.y = 11
        rank_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        box.add_child(rank_bar)
    ZMode.ensure(data)
    var zs: Dictionary = data.ascend
    label((ZMode.t("4×4 Partien",language_code()) if _ascend_revealed() else "Zen Ascend") + ": %d" % int(zs.played),box,18,Color("526943"))
    stat_detail = "%s: %d  ·  %s: %d  ·  %s: %d" % [ZMode.t("Siege",language_code()),int(zs.p1),ZMode.t("Niederlagen",language_code()),int(zs.bot_losses),ZMode.t("Unentschieden",language_code()),int(zs.draw)]
    label(stat_detail,box,14)
    stat_detail = "%s: %d  ·  %s: %d" % [("Zen Ascend Bot" if not _ascend_revealed() else ZMode.t("4×4 gegen Bot",language_code())),int(zs.bot_played),("Zen Ascend Local" if not _ascend_revealed() else ZMode.t("4×4 zu zweit",language_code())),int(zs.local_played)]
    label(stat_detail,box,14)
    stat_detail = "%s: %d  ·  %s: %d" % [ZMode.t("Beste Siegesserie",language_code()),int(zs.best_streak),ZMode.t("Aktuelle Siegesserie",language_code()),int(zs.current_streak)]
    label(stat_detail,box,14)
    stat_detail = "%s: %d  ·  %s: %.1f" % [ZMode.t("Züge gesamt",language_code()),int(zs.moves),ZMode.t("Züge pro Partie",language_code()),float(zs.moves)/float(maxi(1,int(zs.played)))]
    label(stat_detail,box,14)
    button("Zen-Aufstieg",box,open_ascension,true)
    label("Ergebnisse zählen die Spieleridentität auch nach einem Farbtausch. Training und Tutorial werden nicht gezählt. Abgeschlossene Partien können nicht rückgängig gemacht werden. Abgebrochene Partien zählen nicht.",box,14)
# ---- Separate 4x4 Zen Ascend mode and persistent player profiles ----
func _display_player_name(index: int) -> String:
    var stored: String = str(data.settings.names[index])
    if stored == ("Du" if index == 0 else "Spieler 2"):
        if language_code() == "en": return "You" if index == 0 else "Player 2"
        if language_code() == "pt": return "Tu" if index == 0 else "Jogador 2"
    return stored

func save_player_name(index: int, value: String) -> void:
    if index < 0 or index > 1: return
    var cleaned: String = value.strip_edges().replace("\n", " ").replace("\r", " ").substr(0,24)
    if cleaned == _display_player_name(index): return
    if cleaned == "": cleaned = "Du" if index == 0 else "Spieler 2"
    data.settings.names[index] = cleaned
    persist()

const FractureState = preload("res://story/ZenFractureState.gd")

func _ascend_revealed() -> bool:
    # Existing players keep their entitlement and can still enter Zen Ascend.
    return ZMode.unlocked(data) and (FractureState.awakening_seen() or int(data.get("ascend",{}).get("played",0))>0)

func open_ascend_intro() -> void:
    ZMode.ensure(data)
    var language: String = language_code()
    var box: VBoxContainer = modal("Zen Ascend")
    var heading: Label = label(("A New Dimension of Strategy" if _ascend_revealed() else _act_one_ui("Ein verborgener Pfad", "A Hidden Path", "Um Caminho Oculto")),box,20,Color("#284735"))
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var preview: TextureRect = TextureRect.new()
    preview.name = "ZenAscendSneakPreview"
    var art_path: String = "res://assets/zen_realm2/ascend_preview.webp" if _ascend_revealed() else "res://assets/zen_world_moon.webp"
    if not ResourceLoader.exists(art_path):
        art_path = "res://assets/realms/shadow_realm.webp"
    preview.texture = load(art_path) as Texture2D
    preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    preview.custom_minimum_size.y = 245
    preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(preview)
    var tagline: String = "Ein verborgener Pfad wartet." if not _ascend_revealed() else "96 Felder · 6 Seiten · 204 Gewinnlinien"
    if language=="en": tagline = "A hidden path awaits." if not _ascend_revealed() else "96 Cells · 6 Faces · 204 Winning Lines"
    elif language=="pt": tagline = "Um caminho oculto aguarda-te." if not _ascend_revealed() else "96 casas · 6 faces · 204 linhas de vitória"
    var summary: Label = label(tagline,box,17,Color("#315846"))
    summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    if ZMode.unlocked(data):
        premium_button("Zen Ascend betreten" if language=="de" else ("Enter Zen Ascend" if language=="en" else "Entrar no Zen Ascend"),box,start_ascend,true)
    else:
        label(_act_one_ui("🔒 Schließe Zen Chronicles Akt IV ab und besiege Dark Kuze.",
            "🔒 Finish Zen Chronicles Act IV and defeat Dark Kuze.",
            "🔒 Conclui o Ato IV de Zen Chronicles e derrota Dark Kuze."),box,15)
        premium_button(_act_one_ui("Zur Geschichte","Go to Story","Ir à História"),box,func(): chronicles.open_library(),true)

func buy_ascend() -> void:
    # Keep legacy signals safe: direct calls cannot buy an early 4x4 unlock.
    notify_user(_act_one_ui("Besiege zuerst Dark Kuze in Akt IV.",
        "Defeat Dark Kuze in Act IV first.",
        "Derrota primeiro Dark Kuze no Ato IV."))
    open_ascend_intro()

func start_ascend() -> void:
    if not ZMode.unlocked(data): return
    close_modal()
    persist()
    get_tree().change_scene_to_file("res://Ascend.tscn")

# ---- Zen Challenges (same interactive 3D cube; Classic state is untouched) ----
func begin_challenges() -> void:
    if challenges == null or not challenges.valid:
        notify_user("Zen Challenges konnten nicht geladen werden.")
        close_modal()
        return
    if challenge_active:
        close_modal()
        return
    if tutorial != null:
        # Finish the tutorial before entering a new mode.
        end_tutorial()
    close_modal()
    # Cancel outstanding bot moves. The stale worker result is discarded.
    generation += 1
    classic_backup = {"board":board.snapshot(), "history":board.history.duplicate(true), "preview":preview.duplicate(), "selected":renderer.selected}
    challenge_active = true
    var first_unsolved: int = 0
    for i in range(challenges.puzzles.size()):
        if not challenges.solved.has(str(i+1)):
            first_unsolved = i
            break
    open_challenge_number(first_unsolved)
    open_challenge_levels()

func open_challenge_number(number: int) -> void:
    if not challenge_active or challenges == null or not challenges.valid: return
    if number < 0 or number >= challenges.puzzles.size(): return
    close_modal()
    generation += 1
    challenge_index = number
    challenge_phase = 0
    challenge_hint_level = 0
    challenge_message = ""
    toast_until = 0
    preview = []
    board = BoardModel.new()
    challenges.setup(board,challenge_index)
    renderer.reset_view()
    refresh()

func challenge_restart() -> void:
    if challenge_active: open_challenge_number(challenge_index)

func open_challenge_levels() -> void:
    if not challenge_active: return
    var box = modal("Zen-Rätsel · 5 Stufen")
    label(T("20 Rätsel je Stufe") + " · ✓ %d/100" % challenges.solved.size(),box,15)
    var levels: Array = ["Anfänger", "Fortgeschritten", "Experte", "Zen-Meister", "Großmeister"]
    for level in range(1, 6):
        var start_index: int = (level - 1) * 20
        var completed: int = 0
        for number in range(start_index, start_index + 20):
            if challenges.solved.has(str(number + 1)): completed += 1
        button(T(levels[level - 1]) + " · %d/20 ✓" % completed,box,Callable(self, "challenge_open_level").bind(level),false,level == 1)

func challenge_open_level(level: int) -> void:
    if not challenge_active or level < 1 or level > 5: return
    var start_index: int = (level - 1) * 20
    var selected: int = start_index
    for i in range(start_index, start_index + 20):
        if not challenges.solved.has(str(i + 1)):
            selected = i
            break
    open_challenge_number(selected)

func challenge_try_cell(cell: int) -> void:
    if not challenge_active or challenge_phase == -1 or cell < 0 or cell >= 54 or board.cells[cell] != 0: return
    var p: Dictionary = challenges.puzzle(challenge_index)
    var kind: String = str(p.kind)
    var script_path: Array = []
    if kind == "sequence":
        script_path = p.get("path", [])
    var next_move: int = -1
    if kind == "sequence" and script_path.size() > challenge_phase * 2:
        next_move = int(script_path[challenge_phase * 2])
    elif kind == "fork" and challenge_phase == 0:
        # The first move is chosen from the puzzle's certified fork solutions.
        next_move = -1
    elif challenge_phase == 0:
        next_move = -1
    # Later X moves in a fork finish any still-open winning line.
    var last_move: bool = kind in ["fork", "sequence"] and challenge_phase > 0 and (kind == "fork" or script_path.size() <= challenge_phase * 2)
    if last_move:
        var candidate: Array = board.cells.duplicate()
        candidate[cell] = 1
        var victories: Array = rules.victories(candidate,1)
        if victories.is_empty():
            notify_user("Suche den zweiten Gewinnweg über die Kante.")
            return
        board.cells[cell] = 1
        board.last_cell = cell
        board.win_lines = victories
        challenge_complete()
        refresh(cell)
        return
    if (next_move >= 0 and cell != next_move) or (next_move < 0 and not p.solutions.has(cell)):
        notify_user("Nicht ganz – überlege, welche Kantenlinie entscheidend ist.")
        return
    board.cells[cell] = 1
    board.last_cell = cell
    play_sound(false)
    if kind in ["win", "block", "defense"]:
        if kind == "win": board.win_lines = rules.victories(board.cells,1)
        challenge_complete()
        refresh(cell)
        return
    var threats: Array = rules.threats(board.cells,1)
    if rules.threats(board.cells,2).size() > 0 or threats.is_empty():
        push_error("Zen Challenges: broken forcing sequence")
        challenge_restart()
        return
    var bot_block: int = -1
    if kind == "sequence" and script_path.size() > challenge_phase * 2 + 1:
        var script_reply: Variant = script_path[challenge_phase * 2 + 1]
        if script_reply is Dictionary:
            bot_block = int(threats[0])
        else:
            bot_block = int(script_reply)
    else:
        bot_block = int(threats[0])
    if bot_block < 0 or bot_block >= 54 or board.cells[bot_block] != 0 or not threats.has(bot_block):
        push_error("Zen Challenges: forcing response does not match winning lines")
        challenge_restart()
        return
    board.cells[bot_block] = 2
    board.last_cell = bot_block
    challenge_phase += 1
    challenge_message = T("Der Zen-Bot blockiert. Finde den nächsten Zug!")
    play_sound(false)
    refresh(bot_block)

func challenge_complete() -> void:
    challenge_phase = -1
    board.winner = 1 if not board.win_lines.is_empty() else 0
    var was_solved: bool = challenges.solved.has(str(challenge_index + 1))
    challenges.record_solved(challenge_index)
    if not was_solved:
        var puzzle_level: int = int(challenges.puzzle(challenge_index).level)
        var leaves: int = Collection.reward_challenge(data, puzzle_level)
        challenge_message = T("Rätsel gelöst! +%d Zen-Blätter 🍃") % leaves
    else:
        challenge_message = T("Rätsel erneut gelöst.")
    persist()
    play_sound(true)
    if not board.win_lines.is_empty(): focus_line(board.win_lines[0])

func challenge_hint() -> void:
    if not challenge_active or challenge_phase == -1: return
    var targets: Array = challenges.solutions(challenge_index)
    var active_p: Dictionary = challenges.puzzle(challenge_index)
    if str(active_p.kind) == "sequence" and challenge_phase > 0:
        var scripted: Array = active_p.get("path", [])
        if scripted.size() > challenge_phase * 2:
            targets = [int(scripted[challenge_phase * 2])]
        else:
            targets = rules.threats(board.cells,1)
    elif challenge_phase > 0:
        targets = rules.threats(board.cells,1)
    if targets.is_empty(): return
    var cell: int = int(targets[0])
    var face: int = CubeGeometry.face(cell)
    if challenge_hint_level == 0:
        challenge_message = T("Schau auf die Würfelseite: ") + T(CubeGeometry.NAMES[face])
        renderer.focus_faces([face])
    else:
        challenge_message = T("Lösungshinweis: ") + T(CubeGeometry.NAMES[face]) + " · " + T("Zeile ") + str(int((cell%9)/3)+1) + " · " + T("Spalte ") + str(cell%3+1)
    challenge_hint_level += 1
    toast_until = 0
    refresh()

func leave_challenges() -> void:
    if not challenge_active: return
    close_modal()
    challenge_active = false
    generation += 1
    board = BoardModel.new()
    board.restore(classic_backup.board)
    board.history = classic_backup.history.duplicate(true)
    preview = classic_backup.preview.duplicate()
    renderer.selected = int(classic_backup.selected)
    classic_backup = {}
    challenge_message = ""
    refresh()

func open_help() -> void:
    if zen_campaign_active:
        _zen_campaign_help()
        return
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
    if zen_campaign_active and board.winner != 0: return
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
    if challenge_active: leave_challenges()
    close_modal()
    menu_context = false
    tutorial_quick = false
    tutorial_return_to_campaign = false
    var finish: Button = tutorial_row.get_child(2) as Button
    finish.text = T("Spielen")
    finish.set_meta("zen_source_text", "Spielen")
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
    var total: int = 3 if tutorial_quick else TutorialController.TEXTS.size()
    if tutorial.step + delta >= total:
        end_tutorial()
        return
    tutorial.step = clampi(tutorial.step+delta,0,total-1)
    load_tutorial()
func end_tutorial() -> void:
    if tutorial == null: return
    tutorial = null
    generation += 1
    preview = []
    var return_to_campaign: bool = tutorial_return_to_campaign
    tutorial_return_to_campaign = false
    tutorial_quick = false
    if tutorial_from_welcome:
        tutorial_from_welcome = false
        start_mode(1,0,true)
        return
    board = BoardModel.new()
    board.restore(saved_training.board)
    board.history = saved_training.history
    refresh()
    if return_to_campaign:
        data.settings.tutorial_seen = true
        persist()
        resume_campaign()
func start_mode(mode: int, level: int = 0, from_welcome: bool = false) -> void:
    if zen_campaign_active: return
    if challenge_active: leave_challenges()
    close_modal()
    menu_context = false
    tutorial_quick = false
    tutorial_return_to_campaign = false
    if tutorial != null:
        tutorial = null
        preview = []
        tutorial_from_welcome = false
    data.settings.mode = mode
    data.settings.level = clampi(level,0,4)
    data.settings.intro_seen = true
    if from_welcome:
        data.settings.next_start = 0
    if mode == 1:
        data.settings.swap = false
    new_game()

# ZENCUBE_ONBOARDING_RESULT_HARD_FIX_2026_11_13
func allow_welcome_scroll(node: Node) -> void:
    # Decorative panels and labels must not swallow Android swipe gestures.
    # Buttons still receive taps, but let a drag pass up to ScrollContainer.
    var control: Control = node as Control
    if control != null:
        if control is PanelContainer or control is Label:
            control.mouse_filter = Control.MOUSE_FILTER_IGNORE
        else:
            control.mouse_filter = Control.MOUSE_FILTER_PASS
    for child in node.get_children():
        allow_welcome_scroll(child)

func open_welcome() -> void:
    welcome_open = true
    var box = modal("Spielanleitung")
    popup.anchor_top = 0.06
    popup.offset_top = 0
    box.get_child(1).hide()
    label("Atme durch. Drehe den Würfel. Entdecke neue Wege zu gewinnen.",box,15,Color("6d6550"))
    # First-screen actions must be visible WITHOUT scrolling.
    button("Mini-Tutorial starten",box,start_tutorial,false,true)
    button("Zum Hauptmenü",box,open_menu,true)
    # The full explanation is available on demand from How to Play.
    label("VIER STEINE  ·  ZWEI WÜRFELSEITEN",box,13,Color("8a755b"))
    add_rule_example(box,"3 + 1",3)
    add_rule_example(box,"2 + 2",2)
    label("Ein Finger zieht den Würfel. Ein kurzes Tippen setzt deinen Stein. Erreiche vier verbundene Felder über zwei benachbarte Würfelseiten.",box,14)
    var welcome_scroll: ScrollContainer = popup.get_child(0) as ScrollContainer
    if welcome_scroll != null:
        welcome_scroll.scroll_deadzone = 0
        welcome_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
    allow_welcome_scroll(box)

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
    box.add_theme_constant_override("separation",9)
    label("Spiele in deinem Tempo.",box,15,Color("806c54"))
    for i in range(2):
        var idx: int = i
        label(ZMode.t("Spielername",language_code()) + " " + str(i+1),box,14)
        var name_field: LineEdit = LineEdit.new()
        name_field.max_length = 24
        name_field.text = _display_player_name(i)
        name_field.placeholder_text = ZMode.t("Spieler 1" if i==0 else "Spieler 2",language_code())
        name_field.name = "SettingsPlayerName%d" % (i+1)
        UiTest.settings_field(name_field)
        name_field.text_submitted.connect(func(value: String): save_player_name(idx,value))
        name_field.focus_exited.connect(func(): save_player_name(idx,name_field.text))
        box.add_child(name_field)
    label("Sprache",box,15)
    var language_picker = OptionButton.new()
    language_picker.name = "SettingsLanguage"
    UiTest.settings_picker(language_picker)
    language_picker.add_item("Deutsch", 0)
    language_picker.add_item("English", 1)
    language_picker.add_item("Português", 2)
    var selected_language: int = ["de", "en", "pt"].find(language_code())
    language_picker.select(maxi(0, selected_language))
    language_picker.item_selected.connect(func(index): change_language(["de","en","pt"][index]))
    box.add_child(language_picker)
    var level = OptionButton.new()
    level.name = "SettingsBotDifficulty"
    UiTest.settings_picker(level)
    for title in ["Bot: Leicht","Bot: Mittel","Bot: Schwer","Bot: Meister","Bot: Großmeister"]: level.add_item(T(title))
    for index in range(5):
        level.set_item_disabled(index, not Asc.level_unlocked(data,index))
    level.selected = clampi(int(data.settings.level),0,4)
    level.custom_minimum_size.y = 52
    level.item_selected.connect(func(index):
        # Difficulty can be selected only after its previous rank is achieved.
        if Asc.level_unlocked(data,index):
            data.settings.level = index
        else:
            level.select(clampi(int(data.settings.level),0,4))
            notify_user("Besiege zuerst die vorherige Bot-Stufe.")
        persist()
    )
    box.add_child(level)
    var music = CheckButton.new()
    UiTest.settings_switch(music)
    music.text = T("Ruhige Zen-Garten-Musik")
    music.button_pressed = bool(data.settings.get("music",false))
    music.toggled.connect(func(enabled):
        data.settings.music = enabled
        sync_music()
        persist()
    )
    box.add_child(music)
    label("Musiktitel", box, 15)
    var tracks: OptionButton = OptionButton.new()
    tracks.name = "SettingsMusicTrack"
    UiTest.settings_picker(tracks)
    tracks.add_item(MusicPolicy.base_label(language_code()))
    var music_names: Array = ["Zen-Garten (Original)", "Klangschalen – Stiller Tempel", "Handpan – Sanfter Rhythmus", "Nebelpfad", "Stein und Wasser", "Regentropfen im Zen-Garten", "Sternenlicht am Tempel"] + NEW_MUSIC_TITLES
    # Hide Misty Path (3), Stone and Water (4), Whispers (7) from manual selection.
    # Other free classics remain available; paid songs appear here only after purchase.
    var track_choices: Array[int] = [0, 1, 2, 5, 6, 8, 9, 10, 11, 12, 13]
    for i in track_choices:
        if not Collection.music_unlocked(data, i):
            continue
        var display: String = T(str(music_names[i]))
        tracks.add_item(display, i)
    var chosen_music: int = clampi(int(data.settings.get("music_track", 7)), 0, 13)
    var base_selected: bool = MusicPolicy.mode(data) == "base"
    # A manually chosen title now hidden from the menu safely reverts to Base.
    # The saved numeric track ID, purchases and original MP3 files are untouched.
    if not base_selected and chosen_music in [3, 4, 7]:
        data.settings["music_mode"] = "base"
        sync_music()
        persist()
        base_selected = true
    var selected_option: int = 0
    if not base_selected:
        for i in range(1, tracks.item_count):
            if tracks.get_item_id(i) == chosen_music:
                selected_option = i
                break
    tracks.select(selected_option)
    tracks.custom_minimum_size.y = 48
    tracks.item_selected.connect(func(index):
        if index == 0:
            select_base_music()
        else:
            select_music_track(tracks.get_item_id(index))
    )
    box.add_child(tracks)
    var sounds = CheckButton.new()
    UiTest.settings_switch(sounds)
    sounds.text = T("Sanfte Spieltöne")
    sounds.button_pressed = bool(data.settings.sound)
    sounds.toggled.connect(func(enabled):
        data.settings.sound = enabled
        persist()
    )
    box.add_child(sounds)
    var vibration = CheckButton.new()
    UiTest.settings_switch(vibration)
    vibration.text = T("Vibration bei Spielzügen")
    vibration.button_pressed = bool(data.settings.get("haptics", true))
    vibration.toggled.connect(func(enabled):
        data.settings.haptics = enabled
        persist()
    )
    box.add_child(vibration)
    var hints = CheckButton.new()
    UiTest.settings_switch(hints)
    hints.text = T("Gewinnfelder als Hilfe zeigen")
    hints.button_pressed = bool(data.settings.hints)
    hints.toggled.connect(func(enabled):
        data.settings.hints = enabled
        refresh()
    )
    box.add_child(hints)
    var alternate = CheckButton.new()
    UiTest.settings_switch(alternate)
    alternate.text = T("Startspieler nach jeder Runde wechseln")
    alternate.button_pressed = bool(data.settings.alternate)
    alternate.toggled.connect(func(enabled):
        data.settings.alternate = enabled
        persist()
    )
    box.add_child(alternate)
    var swap = CheckButton.new()
    UiTest.settings_switch(swap)
    swap.text = T("Farbtausch erlauben (nur lokaler Modus)")
    swap.button_pressed = bool(data.settings.swap)
    swap.toggled.connect(func(enabled):
        data.settings.swap = enabled
        persist()
    )
    box.add_child(swap)
    button("Musikprobe abspielen",box,music_preview)
    var scroll: ScrollContainer = box.get_parent() as ScrollContainer
    var layout := VBoxContainer.new()
    layout.name = "SettingsDialogLayout"
    layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_theme_constant_override("separation",6)
    popup.add_child(layout)
    scroll.reparent(layout)
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var footer := MarginContainer.new()
    footer.name = "SettingsStickyFooter"
    footer.add_theme_constant_override("margin_left",12)
    footer.add_theme_constant_override("margin_right",12)
    footer.add_theme_constant_override("margin_top",6)
    footer.add_theme_constant_override("margin_bottom",10)
    layout.add_child(footer)
    var finish: Button = button("Fertig",footer,open_menu if menu_context else close_modal,false,true)
    finish.name = "SettingsDoneSticky"

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
    sound_player.volume_db = -4.5
    music_player = AudioStreamPlayer.new()
    music_player.name = "ZenGardenMusic"
    add_child(music_player)
    # Use explicit signed PCM16 instead of Godot's WAV import/remap path.
    # This makes Android music decoding use the same engine format as working SFX.
    music_player.stream = music_stream(int(data.settings.get("music_track", 7)))
    music_player.volume_db = -2.0
    music_fade_player = AudioStreamPlayer.new()
    music_fade_player.name = "ZenWorldMusicCrossfade"
    music_fade_player.volume_db = -54.0
    add_child(music_fade_player)
    music_preview_player = AudioStreamPlayer.new()
    music_preview_player.name = "ZenShopPreview"
    music_preview_player.volume_db = -4.5
    add_child(music_preview_player)
    sync_music()
func make_zen_music_stream(track: int = 0) -> AudioStreamWAV:
    var pcm: PackedByteArray = FileAccess.get_file_as_bytes("res://assets/zen_ambient_music.pcm")
    if track == 1:
        pcm = FileAccess.get_file_as_bytes("res://assets/zen_bamboo_music.pcm")
    elif track == 2:
        pcm = FileAccess.get_file_as_bytes("res://assets/zen_moon_music.pcm")
    elif track == 3:
        pcm = FileAccess.get_file_as_bytes("res://assets/zen_flute_music.pcm")
    elif track == 4:
        pcm = FileAccess.get_file_as_bytes("res://assets/zen_koto_music.pcm")
    elif track == 5:
        pcm = FileAccess.get_file_as_bytes("res://assets/zen_regentropfen_music.pcm")
    elif track == 6:
        pcm = FileAccess.get_file_as_bytes("res://assets/zen_sternenlicht_music.pcm")
    if pcm.size() < 32000 or pcm.size() % 2 != 0:
        # Fallback audible tones if a distribution omits the PCM resource.
        push_warning("ZenCube music resource missing; using generated fallback audio")
        pcm = PackedByteArray()
        pcm.resize(16000 * 8 * 2)
        for i in range(16000 * 8):
            var t: float = float(i) / 16000.0
            var fade: float = minf(1.0, minf(t / 0.5, (8.0 - t) / 0.5))
            var y: float = (0.22 * sin(TAU * 440.0 * t) + 0.14 * sin(TAU * 659.26 * t)) * maxf(0.0, fade)
            pcm.encode_s16(i * 2, clampi(roundi(y * 32767.0), -32767, 32767))
    var ambient := AudioStreamWAV.new()
    ambient.format = AudioStreamWAV.FORMAT_16_BITS
    ambient.stereo = false
    ambient.mix_rate = 16000
    ambient.data = pcm
    ambient.loop_begin = 0
    ambient.loop_end = int(pcm.size() / 2)
    ambient.loop_mode = AudioStreamWAV.LOOP_FORWARD
    return ambient
func music_stream(track: int) -> AudioStream:
    if track >= 7 and track <= 13:
        var imported: AudioStreamMP3 = NEW_MUSIC_STREAMS[track - 7] as AudioStreamMP3
        if imported != null:
            imported.loop = true
            return imported
    return make_zen_music_stream(track)

func select_base_music() -> void:
    data.settings["music_mode"] = "base"
    sync_music()
    persist()

func select_music_track(index: int) -> void:
    Collection.ensure(data)
    if not Collection.music_unlocked(data, index):
        notify_user("Schalte diesen Musiktitel zuerst im Zen-Shop frei.")
        return
    data.settings.music_track = clampi(index, 0, 13)
    data.settings["music_mode"] = "manual"
    sync_music()
    persist()
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
func suspend_campaign_music() -> void:
    if music_transition != null and music_transition.is_running(): music_transition.kill()
    for player in [music_player,music_fade_player,music_preview_player]:
        if is_instance_valid(player):
            player.stop()
            player.stream_paused = false

func resume_campaign_music() -> void:
    sync_music()

func sync_music() -> void:
    if music_player == null or data == null: return
    if ZenChronicles.campaign_audio_exclusive():
        suspend_campaign_music()
        return
    var chosen: int = MusicPolicy.selected_track(data)
    if not bool(data.settings.get("music", false)):
        if music_transition != null and music_transition.is_running():
            music_transition.kill()
        if music_player.playing: music_player.stop()
        if music_fade_player != null and music_fade_player.playing: music_fade_player.stop()
        return
    var actual: int = int(music_player.get_meta("track")) if music_player.has_meta("track") else -1
    if actual == chosen:
        if not music_player.playing:
            music_player.volume_db = -2.0
            music_player.play()
        return
    var next_stream: AudioStream = music_stream(chosen)
    if next_stream == null:
        push_warning("ZenCube soundtrack missing: " + str(chosen))
        return
    if music_transition != null and music_transition.is_running():
        music_transition.kill()
    if music_fade_player != null and music_player.playing and not music_player.stream_paused:
        music_fade_player.stop()
        music_fade_player.stream = next_stream
        music_fade_player.set_meta("track", chosen)
        music_fade_player.volume_db = -54.0
        music_fade_player.play()
        var previous_player: AudioStreamPlayer = music_player
        music_player = music_fade_player
        music_fade_player = previous_player
        music_transition = create_tween().set_parallel(true)
        music_transition.tween_property(music_player, "volume_db", -2.0, 1.8)
        music_transition.tween_property(music_fade_player, "volume_db", -54.0, 1.8)
        music_transition.finished.connect(func():
            if is_instance_valid(previous_player) and previous_player != music_player:
                previous_player.stop()
        )
    else:
        music_player.stream = next_stream
        music_player.set_meta("track", chosen)
        music_player.volume_db = -2.0
        music_player.play()
func vibrate_on_move() -> void:
    if not bool(data.settings.get("haptics", true)):
        return
    if OS.get_name() == "Android":
        Input.vibrate_handheld(22)

func play_sound(win: bool) -> void:
    if not bool(data.settings.sound): return
    sound_player.pitch_scale = 1.5 if win else 1.0
    sound_player.play()


# The campaign borrows the view and the rules, and holds its own BoardModel.
func start_zen_campaign() -> void:
    if act_one_active: return
    if zen_campaign_active or ceremony_active:
        return
    chronicles.close_chronicles()
    close_modal()
    menu_context = false
    generation += 1
    zen_campaign_classic_board = board
    zen_campaign_classic_view = {
        "background": world_background.texture,
        "tint": world_background.modulate,
        "basis": renderer.pivot.basis,
        "zoom": renderer.camera.position.z,
        "preview": preview,
    }
    preview = []
    zen_campaign_active = true
    chronicles.set_campaign_board_active(true)
    zen_campaign_progress = ZenCampaign.load_progress()
    zen_campaign_stage = int(zen_campaign_progress.stage)
    _zen_campaign_load_match()
    _zen_campaign_present()

func _zen_campaign_load_match() -> void:
    zen_campaign_battle_line = ""
    zen_campaign_line_until = 0
    zen_campaign_last_line_move = -99
    zen_campaign_spoken = {}
    generation += 1
    board = BoardModel.new()
    board.swap_enabled = false
    board.starter_owner = ZenCampaign.starting_owner(zen_campaign_stage)
    board.owners = [board.starter_owner, 1 - board.starter_owner]
    var game: Dictionary = zen_campaign_progress.game
    if not game.is_empty():
        board.restore(game)
        board.history = game.get("history", []).duplicate(true)
        var x_lines: Array = rules.victories(board.cells, 1)
        var o_lines: Array = rules.victories(board.cells, 2)
        board.win_lines = x_lines + o_lines
        board.winner = 1 if not x_lines.is_empty() else (2 if not o_lines.is_empty() else (3 if not board.cells.has(0) else 0))
    if zen_campaign_stage == ZenCampaign.NIGHT and zen_campaign_progress.night != "" and board.winner == 0:
        board.winner = 3 if zen_campaign_progress.night == "still" else 2
    renderer.reset_view()
    var chapter: int = ZenCampaign.CHAPTER_FOR_STAGE[zen_campaign_stage]
    var scenery := 3 if zen_campaign_stage in [ZenCampaign.NIGHT, ZenCampaign.EPILOGUE] else chapter
    world_background.texture = Asc.WORLD_TEXTURES[scenery]
    # Winter moonlight, deceptive golden summit, and clear cold dawn are distinct.
    if zen_campaign_stage in [ZenCampaign.NIGHT, ZenCampaign.LORD, ZenCampaign.SLAIN]:
        world_background.modulate = Color("b8c9e4")
    elif zen_campaign_stage == ZenCampaign.DAWN:
        world_background.modulate = Color("ffe6ac")
    elif zen_campaign_stage == ZenCampaign.SELF:
        world_background.modulate = Color("cbdfea")
    else:
        world_background.modulate = Color.WHITE
    refresh()

func _campaign_text(key: String) -> String:
    return ZenCampaign.text_for(language_code(), key)

func _zen_campaign_refresh(animate: int) -> void:
    var stage := zen_campaign_stage
    var chapter: int = ZenCampaign.CHAPTER_FOR_STAGE[stage]
    var name_text := ZenCampaign.demon_name(language_code(), stage)
    world_title_label.text = ZenCampaign.chapter_name(language_code(), chapter)
    if stage in [ZenCampaign.NIGHT, ZenCampaign.EPILOGUE]:
        world_title_label.text = name_text
    world_quote_label.text = _campaign_text("quote_%d" % stage)

    var mark := "X" if board.turn == 1 else "O"
    if board.winner != 0:
        status.text = _campaign_text("result_draw" if board.winner == 3 else (
            "result_win" if ZenCampaign.victory_by_player(board) else "result_loss"))
        if stage == ZenCampaign.EPILOGUE:
            status.text = name_text
    elif stage == ZenCampaign.EPILOGUE:
        status.text = _campaign_text("named_turn") % [_campaign_text("shin" if board.turn == 1 else "kuze"), mark]
    else:
        var rival := ZenCampaign.demon_name(language_code(), 4 if stage == ZenCampaign.NIGHT else stage)
        status.text = _campaign_text("rival_turn") % rival if _zen_campaign_bot_turn() else _campaign_text("your_turn") % mark
    status.add_theme_color_override("font_color", Color("453329"))
    detail.text = _campaign_text("moves") % board.move_count()
    rank_label.text = name_text
    rank_label.visible = stage != ZenCampaign.EPILOGUE
    if int(ZenCampaign.WINS_FOR_STAGE[stage]) > 1:
        rank_label.text += "  ·  " + _campaign_text("wins") % [int(zen_campaign_progress.wins), ZenCampaign.WINS_FOR_STAGE[stage]]
    help_text.text = _campaign_text("turn_help")
    if stage in [2, 3, 4, 5, 7, 8, 9, 10] and zen_campaign_battle_line != "" and Time.get_ticks_msec() < zen_campaign_line_until:
        help_text.text = zen_campaign_battle_line
    if stage == ZenCampaign.NIGHT and not _zen_campaign_bot_turn() and board.winner == 0:
        help_text.text = _campaign_text("time_left") % ceili(float(zen_campaign_progress.seconds_left))
    swap_row.hide()
    tutorial_row.hide()
    challenge_role_panel.hide()
    challenge_row.hide()
    challenge_leave_row.hide()
    classic_views.show()
    classic_views.get_child(2).visible = stage != ZenCampaign.NIGHT
    classic_actions.hide()
    zen_campaign_controls.visible = board.winner == 0
    zen_campaign_undo_button.visible = stage != ZenCampaign.NIGHT
    zen_campaign_undo_button.disabled = not _zen_campaign_can_undo()
    zen_campaign_undo_button.tooltip_text = _campaign_text("undo_held") if stage == 3 else ""
    var leave_button: Button = zen_campaign_controls.get_child(1)
    leave_button.text = _campaign_text("leave")
    var allow_hints: bool = stage not in [ZenCampaign.NIGHT, ZenCampaign.DAWN] and bool(data.settings.hints)
    renderer.selected = board.last_cell
    renderer.paint(board, allow_hints, preview, animate)
    if net_active:
        update_net()

func _zen_campaign_can_undo() -> bool:
    return zen_campaign_stage not in [3, ZenCampaign.NIGHT] and board.winner == 0 and board.history.size() > board.starter_owner

func _zen_campaign_undo() -> void:
    if not zen_campaign_active or popup != null or not _zen_campaign_can_undo():
        return
    generation += 1
    rules.undo(board)
    while zen_campaign_stage != ZenCampaign.EPILOGUE and board.current_owner() == 1 and _zen_campaign_can_undo():
        rules.undo(board)
    zen_campaign_turn_start = Time.get_ticks_msec()
    _zen_campaign_save_game()
    refresh()

func _zen_campaign_bot_turn() -> bool:
    return zen_campaign_stage != ZenCampaign.EPILOGUE and board.current_owner() == 1

func _zen_campaign_after_move(cell: int, owner: int) -> void:
    if zen_campaign_stage == ZenCampaign.NIGHT:
        zen_campaign_progress.seconds_left = ZenCampaign.NIGHT_SECONDS
    if owner == 0 or zen_campaign_stage == ZenCampaign.EPILOGUE:
        vibrate_on_move()
    if owner == 0 and zen_campaign_stage < ZenCampaign.SELF:
        if board.move_count() == 1 or (board.starter_owner == 1 and board.move_count() == 2):
            var key := str(cell)
            zen_campaign_progress.openings[key] = int(zen_campaign_progress.openings.get(key, 0)) + 1
        if zen_campaign_turn_start > 0:
            var elapsed := clampi(Time.get_ticks_msec() - zen_campaign_turn_start, 100, 8000)
            zen_campaign_progress.tempo_total += elapsed
            zen_campaign_progress.tempo_count += 1
    if board.winner != 0 and not board.win_lines.is_empty():
        focus_line(board.win_lines[0])
    _zen_campaign_emit_battle_line(cell, owner)
    _zen_campaign_arm_turn()
    _zen_campaign_save_game()
    refresh(cell)
    if board.winner != 0 or _zen_campaign_has_story_beat():
        _zen_campaign_present()

# Optional in-match dialogue from the original campaign manuscript.
# Does not interrupt a turn; at most one new line every three moves.
func _zen_campaign_emit_battle_line(cell: int, owner: int) -> void:
    var stage: int = zen_campaign_stage
    if stage not in [2, 3, 4, 5, 7, 8, 9, 10]:
        return
    if board.move_count() - zen_campaign_last_line_move < 3:
        return
    if board.history.is_empty():
        return
    var previous: Dictionary = board.history.back()
    var before: Array = previous.get("cells", [])
    if before.size() != 54:
        return
    var human_mark: int = board.owners.find(0) + 1
    var bot_mark: int = board.owners.find(1) + 1
    var human_threats: Array = rules.threats(before, human_mark)
    var bot_threats: Array = rules.threats(before, bot_mark)
    var line_key: String = ""
    if stage == 2:
        if owner == 1 and human_threats.has(cell):
            line_key = "combat_2_block"
        elif owner == 0 and rules.threats(board.cells, human_mark).size() >= 2:
            line_key = "combat_2_fork"
    elif stage == 3:
        var last_cell: int = int(previous.get("last_cell", -1))
        if owner == 1 and last_cell >= 0:
            var opposite_face: int = CubeGeometry.N.find(-CubeGeometry.N[CubeGeometry.face(last_cell)])
            if CubeGeometry.face(cell) == opposite_face:
                line_key = "combat_3_mirror"
        if line_key == "" and board.move_count() >= 6:
            line_key = "combat_3_question"
    elif stage == 4:
        if owner == 0 and bot_threats.has(cell):
            line_key = "combat_4_block"
        elif owner == 1 and not rules.threats(board.cells, bot_mark).is_empty():
            line_key = "combat_4_attack"
        elif owner == 0 and zen_campaign_turn_start > 0 and Time.get_ticks_msec() - zen_campaign_turn_start >= 15000:
            line_key = "combat_4_think"
    elif stage == 5:
        if owner == 0 and bot_threats.has(cell):
            line_key = "combat_5_block"
        elif owner == 1 and not rules.threats(board.cells, bot_mark).is_empty():
            line_key = "combat_5_showoff"
    elif stage == ZenCampaign.LORD:
        if owner == 1 and not rules.threats(board.cells, bot_mark).is_empty():
            line_key = "combat_7_build"
        elif owner == 1 and human_threats.has(cell):
            line_key = "combat_7_block"
    elif stage == ZenCampaign.SLAIN:
        if owner == 1:
            var normal: Vector3 = renderer.pivot.basis * CubeGeometry.N[CubeGeometry.face(cell)]
            if normal.z <= 0.12:
                line_key = "combat_8_hidden"
        elif owner == 0 and board.move_count() >= 8:
            line_key = "combat_8_turn"
    elif stage == ZenCampaign.DAWN:
        if owner == 1 and not rules.threats(board.cells, bot_mark).is_empty():
            line_key = "combat_9_bait"
        elif owner == 0 and bot_threats.has(cell):
            line_key = "combat_9_block"
    elif stage == ZenCampaign.SELF:
        if owner == 1 and board.move_count() == 1:
            line_key = "combat_10_favorite"
        elif owner == 0 and bot_threats.has(cell):
            line_key = "combat_10_block"
        elif owner == 1 and not rules.threats(board.cells, bot_mark).is_empty():
            line_key = "combat_10_build"
    if line_key == "" or zen_campaign_spoken.has(line_key):
        return
    zen_campaign_spoken[line_key] = true
    zen_campaign_last_line_move = board.move_count()
    zen_campaign_battle_line = _campaign_text(line_key)
    zen_campaign_line_until = Time.get_ticks_msec() + 4800

func _zen_campaign_save_game() -> bool:
    if zen_campaign_stage == ZenCampaign.NIGHT and board.winner != 0 and zen_campaign_progress.night == "":
        zen_campaign_progress.night = "still" if board.winner == 3 or ZenCampaign.victory_by_player(board) else "red"
    zen_campaign_progress.game = board.snapshot()
    zen_campaign_progress.game["history"] = board.history.duplicate(true)
    if not ZenCampaign.save_progress(zen_campaign_progress):
        push_warning(_campaign_text("save_error"))
        return false
    return true

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_GO_BACK_REQUEST and act_one_active:
        _act_one_back()
        return
    if what == NOTIFICATION_APPLICATION_PAUSED:
        if act_one_active: _act_one_save()
        zen_campaign_paused = true
        if zen_campaign_active and zen_campaign_stage == ZenCampaign.NIGHT and not zen_campaign_progress.game.is_empty():
            _zen_campaign_save_game()
    elif what == NOTIFICATION_APPLICATION_RESUMED:
        zen_campaign_paused = false

func _zen_campaign_arm_turn() -> void:
    zen_campaign_turn_start = Time.get_ticks_msec()
    if _zen_campaign_bot_turn() and board.winner == 0:
        zen_campaign_bot_ready = zen_campaign_turn_start + ZenCampaign.bot_delay(zen_campaign_stage, board.move_count(), zen_campaign_progress)

func _zen_campaign_tick(delta: float) -> void:
    if zen_campaign_battle_line != "" and Time.get_ticks_msec() >= zen_campaign_line_until:
        zen_campaign_battle_line = ""
        if popup == null and zen_campaign_stage in [2, 3, 4, 5, 7, 8, 9, 10]:
            help_text.text = _campaign_text("turn_help")
    if zen_campaign_paused or board.winner != 0:
        return
    if zen_campaign_stage == ZenCampaign.NIGHT and not _zen_campaign_bot_turn() and (popup == null or net_active):
        var previous := ceili(float(zen_campaign_progress.seconds_left))
        zen_campaign_progress.seconds_left = maxf(0.0, float(zen_campaign_progress.seconds_left) - delta)
        var remaining := ceili(float(zen_campaign_progress.seconds_left))
        if remaining == 0:
            board.winner = board.owners.find(1) + 1
            generation += 1
            _zen_campaign_save_game()
            refresh()
            _zen_campaign_present()
        elif remaining != previous:
            _zen_campaign_save_game()
            help_text.text = _campaign_text("time_left") % remaining
    if popup != null or worker != null or not _zen_campaign_bot_turn() or Time.get_ticks_msec() < zen_campaign_bot_ready:
        return
    var hidden: Array = []
    if zen_campaign_stage == ZenCampaign.SLAIN:
        for face in range(6):
            var normal: Vector3 = renderer.pivot.basis * CubeGeometry.N[face]
            if normal.z <= 0.12:
                hidden.append(face)
    var last_bot := -1
    if board.history.size() >= 2:
        last_bot = int(board.history[-1].get("last_cell", -1))
    var context := {
        "mark": board.turn,
        "last_cell": board.last_cell,
        "last_bot": last_bot,
        "hidden_faces": hidden,
        "openings": zen_campaign_progress.openings.duplicate(),
    }
    var turn_cells: Array = board.cells.duplicate()
    var stage := zen_campaign_stage
    var seed_value := int(Time.get_ticks_usec())
    worker = Thread.new()
    worker_generation = generation
    ai_running = true
    worker.start(func(): return ZenCampaign.pick_move(turn_cells, stage, seed_value, context))

func _zen_campaign_story_box(title: String, art_path: String = "", compact: bool = false) -> VBoxContainer:
    var box := modal(title)
    box.get_child(1).hide()
    popup.add_theme_stylebox_override("panel", theme_style(Color("182524", 0.99), 19))
    var heading: Label = box.get_child(0)
    heading.add_theme_color_override("font_color", Color("f4dba4"))
    heading.add_theme_font_size_override("font_size", 27)
    box.add_theme_constant_override("separation", 14)
    if compact:
        popup.anchor_top = 0.45
        popup.anchor_bottom = 0.98
        popup.offset_top = 0
        popup.offset_bottom = 0
    if art_path != "":
        box.add_child(ZenCampaign.artwork(art_path, 246))
    return box

func _zen_campaign_paragraph(box: VBoxContainer, message: String) -> void:
    label(message, box, 17, Color("f1ebdd"))

func _zen_campaign_present() -> void:
    if zen_campaign_progress.pending != "":
        _zen_campaign_interlude()
    elif _zen_campaign_has_story_beat():
        _zen_campaign_story_beat()
    elif zen_campaign_stage == ZenCampaign.NIGHT and zen_campaign_progress.night != "":
        _zen_campaign_night_result()
    elif board.winner != 0:
        _zen_campaign_result()
    elif zen_campaign_stage == 0 and not bool(zen_campaign_progress.prologue_seen):
        var box := _zen_campaign_story_box(_campaign_text("prologue_title"), ZenCampaign.PROLOGUE_ART)
        _zen_campaign_paragraph(box, _campaign_text("prologue"))
        premium_button(_campaign_text("continue"), box, _zen_campaign_prologue_seen, true)
        button(_campaign_text("leave"), box, _zen_campaign_leave, true)
    else:
        _zen_campaign_intro()

func _zen_campaign_prologue_seen() -> void:
    zen_campaign_progress.prologue_seen = true
    if ZenCampaign.save_progress(zen_campaign_progress):
        _zen_campaign_intro()
    else:
        zen_campaign_progress.prologue_seen = false
        _zen_campaign_save_error()

func _zen_campaign_intro() -> void:
    var stage := zen_campaign_stage
    var resumed: bool = not zen_campaign_progress.game.is_empty()
    var show_intro: bool = not zen_campaign_progress.introduced and not resumed
    var art_path: String = ZenCampaign.encounter_art(stage)
    var box := _zen_campaign_story_box(ZenCampaign.demon_name(language_code(), stage), art_path if show_intro else "")
    if show_intro:
        _zen_campaign_paragraph(box, _campaign_text("intro_%d" % stage))
        if stage == ZenCampaign.NIGHT:
            _zen_campaign_paragraph(box, _campaign_text("night_rules"))
        elif stage in [ZenCampaign.LORD, ZenCampaign.SLAIN, ZenCampaign.DAWN]:
            var key: String = ZenCampaign.NAME_KEYS[stage] + "_" + str(zen_campaign_progress.night)
            _zen_campaign_paragraph(box, _campaign_text(key))
    if ZenCampaign.WINS_FOR_STAGE[stage] > 1:
        _zen_campaign_paragraph(box, _campaign_text("wins") % [int(zen_campaign_progress.wins), ZenCampaign.WINS_FOR_STAGE[stage]])
    if stage == ZenCampaign.SELF and int(zen_campaign_progress.wins) >= ZenCampaign.WINS_FOR_STAGE[stage]:
        premium_button(_campaign_text("bow"), box, _zen_campaign_bow, true)
    premium_button(_campaign_text("resume" if resumed else "begin"), box, _zen_campaign_begin, true)
    button(_campaign_text("leave"), box, _zen_campaign_leave, true)

func _zen_campaign_begin() -> void:
    zen_campaign_progress.introduced = true
    if _zen_campaign_save_game():
        close_modal()
        _zen_campaign_arm_turn()
    else:
        _zen_campaign_save_error()

func _zen_campaign_has_story_beat() -> bool:
    var revealed := int(zen_campaign_progress.revealed)
    if zen_campaign_stage == 0:
        return revealed == 0 and board.move_count() >= 1
    if zen_campaign_stage == ZenCampaign.SLAIN:
        return revealed == 0 and (board.move_count() >= 10 or ZenCampaign.victory_by_player(board))
    if zen_campaign_stage == ZenCampaign.SELF and revealed < 3:
        return board.move_count() >= [6, 12, 18][revealed] or ZenCampaign.victory_by_player(board)
    return false

func _zen_campaign_story_beat() -> void:
    var key := "natsu"
    var title := "natsu_title"
    if zen_campaign_stage == ZenCampaign.SLAIN:
        key = "slain_reveal"
        title = "reveal_title"
    elif zen_campaign_stage == ZenCampaign.SELF:
        key = "self_%d" % int(zen_campaign_progress.revealed)
        if int(zen_campaign_progress.revealed) == 2:
            key += "_" + str(zen_campaign_progress.night)
        title = "self"
    var box := _zen_campaign_story_box(_campaign_text(title))
    _zen_campaign_paragraph(box, _campaign_text(key))
    premium_button(_campaign_text("continue"), box, _zen_campaign_story_beat_read, true)
    button(_campaign_text("leave"), box, _zen_campaign_leave, true)

func _zen_campaign_story_beat_read() -> void:
    zen_campaign_progress.revealed += 1
    if not _zen_campaign_save_game():
        zen_campaign_progress.revealed -= 1
        _zen_campaign_save_error()
        return
    close_modal()
    _zen_campaign_arm_turn()
    if board.winner != 0 or _zen_campaign_has_story_beat():
        _zen_campaign_present()

func _zen_campaign_result() -> void:
    var stage := zen_campaign_stage
    var wins := int(zen_campaign_progress.wins)
    var goal: int = ZenCampaign.WINS_FOR_STAGE[stage]
    var player_won := ZenCampaign.victory_by_player(board)
    var draw: bool = board.winner == 3
    var box: VBoxContainer
    if stage == ZenCampaign.EPILOGUE:
        box = _zen_campaign_story_box(_campaign_text("epilogue"), "", true)
        _zen_campaign_paragraph(box, _campaign_text("epilogue_again"))
        premium_button(_campaign_text("again"), box, _zen_campaign_retry, true)
    elif stage == ZenCampaign.SELF and wins + int(player_won) >= goal:
        box = _zen_campaign_story_box(_campaign_text("self"), "", true)
        _zen_campaign_paragraph(box, _campaign_text("win_10"))
        premium_button(_campaign_text("bow"), box, _zen_campaign_bow, true)
        button(_campaign_text("again"), box, _zen_campaign_transition.bind(stage, goal), true)
    else:
        var key := "result_win" if player_won else ("result_draw" if draw else "result_loss")
        box = _zen_campaign_story_box(_campaign_text(key), "", true)
        var story_key := "draw" if draw else ("%s_%d" % ["win" if player_won else "loss", stage])
        if stage == ZenCampaign.SELF and player_won:
            story_key = "quote_10"
        _zen_campaign_paragraph(box, _campaign_text(story_key))
        if goal > 1:
            _zen_campaign_paragraph(box, _campaign_text("wins") % [wins + int(player_won), goal])
        if player_won:
            var next_key := "again"
            if wins + 1 >= goal:
                next_key = "next_chapter" if ZenCampaign.CHAPTER_FOR_STAGE[stage + 1] != ZenCampaign.CHAPTER_FOR_STAGE[stage] else "next_demon"
                if stage == 5 or stage == ZenCampaign.DAWN:
                    next_key = "continue"
            premium_button(_campaign_text(next_key), box, _zen_campaign_advance, true)
        else:
            if not draw and (stage == ZenCampaign.SLAIN or (stage >= ZenCampaign.LORD and wins > 0)):
                _zen_campaign_paragraph(box, _campaign_text("streak_broken"))
            premium_button(_campaign_text("again"), box, _zen_campaign_retry, true)
    var inspect: Button = premium_button("Spielfeld ansehen",box,_inspect_classic_finished_board)
    inspect.text = _inspect_label()
    button(_campaign_text("leave"), box, _zen_campaign_leave, true)

func _zen_campaign_night_result() -> void:
    var still: bool = zen_campaign_progress.night == "still"
    var box := _zen_campaign_story_box(_campaign_text("still" if still else "red_hand"), ZenCampaign.CHAPTER_ART[2])
    if float(zen_campaign_progress.seconds_left) == 0.0:
        _zen_campaign_paragraph(box, _campaign_text("time_out"))
    _zen_campaign_paragraph(box, _campaign_text("night_still" if still else "night_red"))
    premium_button(_campaign_text("next_chapter"), box, _zen_campaign_transition.bind(ZenCampaign.LORD, 0), true)
    button(_campaign_text("leave"), box, _zen_campaign_leave, true)

func _zen_campaign_retry() -> void:
    if not zen_campaign_active or board.winner == 0 or zen_campaign_stage == ZenCampaign.NIGHT:
        return
    var stage := zen_campaign_stage
    var wins := int(zen_campaign_progress.wins)
    if board.winner != 3 and stage >= ZenCampaign.LORD and stage < ZenCampaign.EPILOGUE:
        if stage == ZenCampaign.SLAIN:
            stage = ZenCampaign.LORD
        wins = 0
    _zen_campaign_transition(stage, wins)

func _zen_campaign_advance() -> void:
    if not zen_campaign_active or zen_campaign_stage in [ZenCampaign.NIGHT, ZenCampaign.EPILOGUE] or not ZenCampaign.victory_by_player(board):
        return
    var wins := int(zen_campaign_progress.wins) + 1
    if wins < ZenCampaign.WINS_FOR_STAGE[zen_campaign_stage]:
        _zen_campaign_transition(zen_campaign_stage, wins)
    elif zen_campaign_stage < ZenCampaign.SELF:
        var pending := ""
        if zen_campaign_stage == 3:
            pending = "chapter_2_end"
        elif zen_campaign_stage == 5:
            pending = "chapter_3_end"
        elif zen_campaign_stage == ZenCampaign.SLAIN:
            pending = "chapter_4_end"
        elif zen_campaign_stage == ZenCampaign.DAWN:
            pending = "false_ending"
        _zen_campaign_transition(zen_campaign_stage + 1, 0, pending)

func _zen_campaign_bow() -> void:
    var wins := int(zen_campaign_progress.wins) + int(ZenCampaign.victory_by_player(board))
    if zen_campaign_stage == ZenCampaign.SELF and wins >= ZenCampaign.WINS_FOR_STAGE[ZenCampaign.SELF]:
        _zen_campaign_transition(ZenCampaign.EPILOGUE, 0, "chapter_5_end")

func _zen_campaign_transition(stage: int, wins: int, pending: String = "") -> void:
    if not zen_campaign_active:
        return
    var next := zen_campaign_progress.duplicate(true)
    next.stage = stage
    next.wins = wins
    next.pending = pending
    next.game = {}
    next.seconds_left = ZenCampaign.NIGHT_SECONDS
    if stage != zen_campaign_stage:
        next.revealed = 0
        next.introduced = false
    if stage == ZenCampaign.EPILOGUE:
        next.complete = true
    if not ZenCampaign.save_progress(next):
        _zen_campaign_save_error()
        return
    zen_campaign_progress = next
    zen_campaign_stage = stage
    _zen_campaign_load_match()
    _zen_campaign_present()

func _zen_campaign_interlude() -> void:
    var scene: String = zen_campaign_progress.pending
    if scene in ["chapter_2_end", "chapter_3_end", "chapter_4_end", "chapter_5_end"]:
        var completed_world: int = {
            "chapter_2_end": 1,
            "chapter_3_end": 2,
            "chapter_4_end": 3,
            "chapter_5_end": 4
        }[scene]
        var chapter_box := _zen_campaign_story_box(
            _campaign_text(scene + "_title"), ZenCampaign.CHAPTER_ART[completed_world])
        _zen_campaign_paragraph(chapter_box, _campaign_text(scene + "_body"))
        var following: String = "epilogue" if scene == "chapter_5_end" else ""
        premium_button(_campaign_text("next_chapter"), chapter_box,
            _zen_campaign_transition.bind(zen_campaign_stage, 0, following), true)
        button(_campaign_text("leave"), chapter_box, _zen_campaign_leave, true)
    elif scene == "false_ending":
        var box := _zen_campaign_story_box(_campaign_text("false_title"), ZenCampaign.CHAPTER_ART[4])
        popup.add_theme_stylebox_override("panel", theme_style(Color("52402b"), 19))
        _zen_campaign_paragraph(box, _campaign_text(scene))
        premium_button(_campaign_text("accept"), box, _zen_campaign_transition.bind(zen_campaign_stage, 0, "false_accept"), true)
        button(_campaign_text("sit_again"), box, _zen_campaign_transition.bind(zen_campaign_stage, 0, "false_refuse"), true)
        button(_campaign_text("leave"), box, _zen_campaign_leave, true)
    else:
        var island := scene == "epilogue"
        var title_key := "epilogue" if island else "dawn"
        var box := _zen_campaign_story_box(_campaign_text(title_key), ZenCampaign.encounter_art(ZenCampaign.EPILOGUE) if island else "")
        if island:
            _zen_campaign_paragraph(box, _campaign_text("after_bow"))
            _zen_campaign_paragraph(box, _campaign_text("epilogue_" + str(zen_campaign_progress.night)))
        else:
            _zen_campaign_paragraph(box, _campaign_text(scene))
        premium_button(_campaign_text("continue"), box, _zen_campaign_transition.bind(zen_campaign_stage, 0), true)
        button(_campaign_text("leave"), box, _zen_campaign_leave, true)

func _zen_campaign_help() -> void:
    if zen_campaign_stage == ZenCampaign.NIGHT or board.winner != 0:
        return
    var box := _zen_campaign_story_box(_campaign_text("hint_title"))
    var bait: Array = rules.threats(board.cells, 2) if zen_campaign_stage == ZenCampaign.DAWN else []
    var offer := not bait.is_empty()
    _zen_campaign_paragraph(box, _campaign_text("bait_hint" if offer else "hint_text"))
    if offer:
        button(_campaign_text("bait_button"), box, focus_and_close.bind(CubeGeometry.face(bait[0])), true)
    premium_button(_campaign_text("resume"), box, close_modal, true)

func _zen_campaign_save_error() -> void:
    if popup == null:
        notify_user(_campaign_text("save_error"))
        return
    var content: VBoxContainer = popup.get_child(0).get_child(0)
    if content.get_node_or_null("CampaignSaveError") == null:
        var error := label(_campaign_text("save_error"), content, 16, Color("ffb6a0"))
        error.name = "CampaignSaveError"

func _zen_campaign_leave() -> void:
    if not zen_campaign_active:
        return
    if not zen_campaign_progress.game.is_empty() and not _zen_campaign_save_game():
        if popup == null:
            open_menu()
        _zen_campaign_save_error()
        return
    close_modal()
    generation += 1
    zen_campaign_active = false
    chronicles.set_campaign_board_active(false)
    board = zen_campaign_classic_board
    world_background.texture = zen_campaign_classic_view.background
    world_background.modulate = zen_campaign_classic_view.tint
    renderer.pivot.basis = zen_campaign_classic_view.basis
    renderer.camera.position.z = zen_campaign_classic_view.zoom
    preview = zen_campaign_classic_view.preview
    zen_campaign_classic_board = null
    zen_campaign_classic_view = {}
    zen_campaign_progress = {}
    refresh(-1, false)
    chronicles.open_campaign_overview()

# Act I reuses the live Classic 3x3 board and renderer, but not Classic stats,
# ranks, economy, results, settings, or the original campaign's progress.
func _act_one_ui(de: String, en: String, pt: String) -> String:
    return de if language_code() == "de" else (pt if language_code() == "pt" else en)

func _act_one_title() -> String:
    return str(prequel_model.config().get("title", {}).get(language_code(), "The Zen Master"))

func start_act_one_trial(act: int = 1) -> void:
    if act_one_active or zen_campaign_active or ceremony_active:
        return
    if act not in [1,2,3,4]: return
    if act==2 and (not ActTwo.unlocked(SaveManager.load_data()) or not ActTwo.media_ready()): return
    if act==3 and (not ActThree.unlocked(SaveManager.load_data()) or not ActThree.media_ready()): return
    if act==4 and (not ActFour.unlocked(SaveManager.load_data()) or not ActFour.media_ready()): return
    prequel_act = act
    prequel_model = ActFour if act==4 else (ActThree if act==3 else (ActTwo if act==2 else ActOne))
    var progress: Dictionary = prequel_model.load_progress()
    if not bool(progress.reached) or bool(progress.acknowledged):
        return
    chronicles.close_chronicles()
    close_modal()
    menu_context = false
    generation += 1
    act_one_classic_board = board
    act_one_view = {"background": world_background.texture, "tint": world_background.modulate,
        "basis": renderer.pivot.basis, "zoom": renderer.camera.position.z, "preview": preview}
    preview = []
    act_one_active = true
    chronicles.set_campaign_board_active(true)
    act_one_back_previous = get_tree().quit_on_go_back
    get_tree().quit_on_go_back = false
    act_one_progress = progress
    board = prequel_model.restore_board(progress.game)
    renderer.reset_view()
    world_background.texture = Asc.WORLD_TEXTURES[prequel_act-1]
    world_background.modulate = Color.WHITE
    _act_one_save()
    refresh()
    if board.winner != 0: _act_one_result()

func _act_one_save() -> bool:
    if not act_one_active:
        return false
    prequel_model.capture(act_one_progress, board)
    if not prequel_model.save_progress(act_one_progress):
        notify_user(_act_one_ui("Speichern fehlgeschlagen.", "Could not save progress.", "Não foi possível guardar."))
        return false
    return true

func _act_one_refresh(animate: int) -> void:
    world_title_label.text = _act_one_title()
    world_quote_label.text = T(WORLD_QUOTES[prequel_act-1]) if prequel_act>=2 else "The First Trial · The Roots of Peace"
    rank_label.visible = true
    rank_label.text = "Kuze · X    /    O · " + _act_one_title()
    if board.winner == 1:
        status.text = _act_one_ui("Prüfung bestanden!", "Trial passed!", "Prova concluída!")
    elif board.winner == 2:
        status.text = _act_one_title() + " · " + _act_one_ui("Sieg · O", "Victory · O", "Vitória · O")
    elif board.winner == 3:
        status.text = _act_one_ui("Unentschieden", "Draw", "Empate")
    elif board.turn == 1:
        status.text = _act_one_ui("Du bist am Zug · X", "Your turn · X", "A tua vez · X")
    else:
        status.text = _act_one_title() + " · " + _act_one_ui("ist am Zug · O", "turn · O", "a jogar · O")
    status.add_theme_color_override("font_color", Color("453329"))
    detail.text = _act_one_ui("Zug ", "Move ", "Jogada ") + str(board.move_count()) + " · 3×3"
    help_text.text = _act_one_ui("Drehen · Tippen · Zoomen", "Rotate · Tap · Zoom", "Rodar · Tocar · Ampliar")
    swap_row.hide()
    tutorial_row.hide()
    challenge_role_panel.hide()
    challenge_row.hide()
    challenge_leave_row.hide()
    classic_views.show()
    classic_views.get_child(2).hide()
    classic_actions.hide()
    zen_campaign_controls.hide()
    act_one_controls.show()
    act_one_result_button.visible = board.winner != 0
    act_one_result_button.text = _classic_result_label()
    var leave_button := act_one_controls.get_child(1) as Button
    leave_button.text = _act_one_ui("Zur Geschichte", "Back to story", "Voltar à história")
    renderer.selected = board.last_cell
    renderer.paint(board, bool(data.settings.hints) and board.winner == 0, [], animate)
    if net_active: update_net()

func _act_one_tick() -> void:
    if zen_campaign_paused or board.winner != 0 or board.turn != 2 or popup != null or worker != null:
        return
    var cells: Array = board.cells.duplicate()
    var seed_value := int(Time.get_ticks_usec())
    worker_generation = generation
    ai_running = true
    worker = Thread.new()
    var trial_level: int = prequel_act-1
    worker.start(func(): return AIEngine.new(seed_value).choose(cells, 2, trial_level, 45))

func _act_one_result() -> void:
    if not act_one_active or board.winner == 0: return
    var saved := _act_one_save()
    var config: Dictionary = prequel_model.config()
    var dialogue: Dictionary = config.get("dialogue_"+language_code(),config.get("dialogue", {}))
    var outcome := "victory" if board.winner == 1 else ("defeat" if board.winner == 2 else "draw")
    var box := _zen_campaign_story_box(_act_one_title())
    popup.add_theme_stylebox_override("panel", theme_style(Color("30261f", 0.985), 22))
    # Result art matches the large full-height Act I-IV introduction portrait.
    var art := ZenCampaign.artwork(prequel_model.portrait_path(),
        clampf(get_viewport().get_visible_rect().size.y * 0.62,400.0,880.0))
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    box.add_child(art)
    _zen_campaign_paragraph(box, str(dialogue.get(outcome, "")))
    if not saved:
        _zen_campaign_paragraph(box, _act_one_ui("Speichern fehlgeschlagen. Bitte erneut versuchen.", "Save failed. Please try again.", "Erro ao guardar. Tenta novamente."))
    if board.winner == 1 and bool(act_one_progress.won):
        premium_button(_act_one_ui("Fortsetzen", "Continue", "Continuar"), box, _act_one_continue, true)
    else:
        premium_button(_act_one_ui("Erneut versuchen", "Try again", "Tentar novamente"), box, _act_one_retry, true)
    button(_inspect_label(), box, _inspect_classic_finished_board, true)
    button(_act_one_ui("Zur Geschichte", "Back to story", "Voltar à história"), box, _act_one_leave, true)

func _act_one_retry() -> void:
    if not act_one_active or board.winner not in [2, 3]: return
    if not _act_one_save(): return
    var old_board: BoardModel = board
    var old_progress: Dictionary = act_one_progress.duplicate(true)
    generation += 1
    board = prequel_model.new_board()
    if not _act_one_save():
        board = old_board
        act_one_progress = old_progress
        _act_one_result()
        return
    close_modal()
    renderer.reset_view()
    refresh()

func _act_one_continue() -> void:
    if not act_one_active or board.winner != 1 or not bool(act_one_progress.won): return
    act_one_progress.acknowledged = true
    act_one_progress.page = 12
    if not _act_one_save():
        act_one_progress.acknowledged = false
        act_one_progress.page = 11
        _act_one_result()
        return
    _act_one_leave()

func _act_one_leave() -> void:
    if not act_one_active or not _act_one_save(): return
    close_modal()
    generation += 1
    act_one_active = false
    chronicles.set_campaign_board_active(false)
    get_tree().quit_on_go_back = act_one_back_previous
    board = act_one_classic_board
    world_background.texture = act_one_view.background
    world_background.modulate = act_one_view.tint
    renderer.pivot.basis = act_one_view.basis
    renderer.camera.position.z = act_one_view.zoom
    preview = act_one_view.preview
    act_one_view = {}
    act_one_classic_board = null
    act_one_progress = {}
    refresh(-1, false)
    if prequel_act==4: chronicles.open_act_four()
    elif prequel_act==3: chronicles.open_act_three()
    elif prequel_act==2: chronicles.open_act_two()
    else: chronicles.open_act_one()

func _act_one_back() -> void:
    if popup != null:
        close_modal()
    else:
        open_menu()

func _unhandled_key_input(event: InputEvent) -> void:
    if act_one_active and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        _act_one_back()
        get_viewport().set_input_as_handled()
