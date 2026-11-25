extends Node3D
# Standalone 4x4 scene so no Classic board, AI or rules are replaced.
const Mode = preload("res://core/ZenAscend.gd")
const BotAuto = preload("res://core/ZenBotAutoLevel.gd")
const Locale = preload("res://core/ZenLocalization.gd")
const MusicPolicy = preload("res://core/ZenMusicPolicy.gd")
const WorldMusic = preload("res://core/ZenWorldMusic.gd")
const RealmMusic = preload("res://core/ZenRealmMusic.gd")
const BossMusic = preload("res://core/ZenRealmBossMusic.gd")
const FullyAware = preload("res://ui/ZenFullyAwareCeremony.gd")
const Achievements = preload("res://core/ZenAscendAchievements.gd")
const UnlockCeremony = preload("res://ui/ZenUnlockCeremony.gd")
const RealmPortal = preload("res://ui/ZenRealmTravelCeremony.gd")
const Realms = preload("res://core/ZenAscendRealms.gd")
const RealmBot = preload("res://core/ZenAscendRealmBot.gd")
const RealmStory = preload("res://story/ZenRealmChronicles.gd")
const ZenType = preload("res://ui/ZenRealm2Typography.gd")
const SettingsTheme = preload("res://ui/ZenUiTestTheme.gd")
const Abyss = preload("res://story/ZenAbyssCampaign.gd")
const Shadow = preload("res://story/ZenShadowCampaign.gd")
const Ember = preload("res://story/ZenEmberCampaign.gd")
const Celestial = preload("res://story/ZenCelestialCampaign.gd")
const Satori = preload("res://story/ZenSatoriCampaign.gd")
const Moon = preload("res://story/ZenShatteredMoonCampaign.gd")
const SkyGarden = preload("res://story/ZenSkyGardenCampaign.gd")
const Realm2 = preload("res://core/ZenRealmCampaign2.gd")
const FinalSeries = preload("res://core/ZenFinalGuardianSeries.gd")
const VictoryArtwork = preload("res://ui/ZenRealmVictoryArtwork.gd")
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
var result_review_button: Button
var rules_button: Button
var new_match_button: Button
var realms_nav_button: Button
var challenges_nav_button: Button
var achievements_nav_button: Button
var ascend_subtitle: Label
var layer: Control
var hd_gameplay_margin: MarginContainer
var menu_dialog: ConfirmationDialog
var world_music: AudioStreamPlayer
var realm_music_fade: AudioStreamPlayer
var realm_music_tween: Tween
var realm_backdrop: TextureRect
var realm_backdrop_shade: ColorRect
const ARENA_BACKDROP_SHADER = preload("res://ui/RealmArenaBackdrop.gdshader")
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
var realm_story_active: bool = false
var realm_story_progress: Dictionary = {}
# Prevent delayed bot replies from bleeding into later normal/Chronicles matches.
var match_generation: int = 0
var realm_story_stage: int = 0
var realm_story_last_human: int = -1
var realm_story_generation: int = 0
var abyss_active: bool = false
var abyss_progress: Dictionary = {}
var abyss_index: int = -1
var abyss_generation: int = 0
var abyss_last_human: int = -1
var shadow_active: bool = false
var shadow_progress: Dictionary = {}
var shadow_index: int = -1
var shadow_generation: int = 0
var shadow_last_human: int = -1
var ember_active: bool = false
var ember_model: Variant = Ember
var guardian_chapter: int = 2
var ember_index: int = -1
var ember_generation: int = 0
var ember_last_human: int = -1
var ember_progress: Dictionary = {}
var practice_chapter: int = 1
var campaign_practice_active: bool = false
var hd_direct_realm: bool = false
var campaign_awards: Array[String] = []
var campaign_award_index: int = 0

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
    # Check the earned Act IV gate BEFORE touching saved Realm selection.
    # Locked players return to Classic without rewriting their existing Realm save.
    if not Mode.unlocked(data):
        get_tree().call_deferred("change_scene_to_file","res://Main.tscn")
        return
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
    var practice_launch: int = ZenChronicles.consume_campaign_practice_launch()
    if practice_launch in [0,1,2,3,4]:
        call_deferred("start_campaign_practice",practice_launch)
        return
    if ZenChronicles.consume_celestial_launch():
        call_deferred("start_celestial_battle")
        return
    if ZenChronicles.consume_shattered_moon_launch():
        call_deferred("start_shattered_moon_battle")
        return
    if ZenChronicles.consume_satori_launch():
        call_deferred("start_satori_battle")
        return
    if ZenChronicles.consume_ember_launch():
        call_deferred("start_ember_battle")
        return
    if ZenChronicles.consume_shadow_launch():
        call_deferred("start_shadow_battle")
        return
    if ZenChronicles.consume_abyss_launch():
        call_deferred("start_abyss_battle")
        return
    if ZenChronicles.consume_realm_story_launch():
        # Scene is loaded; do not toggle normal 4x4 help_seen or rankings.
        call_deferred("start_realm_story")
        return
    _hd_restore_selected_board()
    # The explanation is guaranteed on first entry, including in the test build.
    if not bool(data.ascend.help_seen):
        data.ascend.help_seen = true
        SaveManager.save_data(data)
        call_deferred("show_rules")
    else:
        call_deferred("show_ascend_menu")

# Existing shop IDs 0..13 always remain unchanged. In Base mode 4x4 uses
# its own realm soundtrack; a manually owned track overrides it everywhere.
func desired_realm_stream() -> AudioStream:
    if campaign_practice_active:
        var stream: AudioStream = Satori.story_stream() if practice_chapter==4 else (Celestial.story_stream() if practice_chapter==3 else (Ember.story_stream() if practice_chapter==2 else Abyss.story_stream()))
        if stream != null: return stream
    if ember_active:
        var ember_stream: AudioStream = ember_model.boss_stream(ember_index)
        if ember_stream != null: return ember_stream
    if shadow_active:
        var shadow_stream: AudioStream = Shadow.boss_stream(shadow_index)
        if shadow_stream != null: return shadow_stream
    if abyss_active:
        var abyss_stream: AudioStream = Abyss.boss_stream(abyss_index)
        if abyss_stream != null: return abyss_stream
    # Twelve original boss themes take precedence during the 4x4 story,
    # independent of which Shop track the player has equipped. Outside a boss
    # match, the original Realm/Shop choice is restored unchanged.
    if realm_story_active:
        var battle_theme: AudioStream = BossMusic.stream_for(realm_story_stage)
        if battle_theme != null: return battle_theme
    if MusicPolicy.mode(data) == "base":
        return RealmMusic.stream_for(realm_index())
    var selected: int = MusicPolicy.selected_track(data)
    return WorldMusic.stream_for(selected)

func start_world_music() -> void:
    sync_realm_music(true)

func suspend_campaign_music() -> void:
    if realm_music_tween != null and realm_music_tween.is_running(): realm_music_tween.kill()
    if is_instance_valid(world_music):
        world_music.stop()
        world_music.stream_paused = false
    if is_instance_valid(realm_music_fade):
        realm_music_fade.stop()
        realm_music_fade.queue_free()
        realm_music_fade = null

func resume_campaign_music() -> void:
    sync_realm_music(true)

func sync_realm_music(initial: bool = false) -> void:
    if ZenChronicles.campaign_audio_exclusive():
        suspend_campaign_music()
        return
    if ember_active or shadow_active or abyss_active or realm_story_active or campaign_practice_active:
        initial = true
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
        if initial and is_instance_valid(realm_music_fade):
            if realm_music_tween != null and realm_music_tween.is_running(): realm_music_tween.kill()
            realm_music_fade.stop()
            realm_music_fade.queue_free()
            realm_music_fade = null
            world_music.volume_db = -2.0
        if not world_music.playing:
            world_music.volume_db = -2.0
            world_music.play()
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
    b.add_theme_stylebox_override("focus",_hd_gold_focus())
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
        if is_instance_valid(hd_gameplay_margin): hd_gameplay_margin.show()
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
    var ui_theme: Theme = Theme.new()
    ui_theme.default_font = ZenType.body()
    ui_theme.default_font_size = 18
    for kind in ["Button","OptionButton","CheckButton","CheckBox","LineEdit"]:
        ui_theme.set_stylebox("focus",kind,_hd_gold_focus())
    layer.theme = ui_theme
    var backdrop: TextureRect = TextureRect.new()
    realm_backdrop = backdrop
    backdrop.texture = load(Realms.REALM_ART[realm_index()])
    backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(backdrop)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shade: ColorRect = ColorRect.new()
    realm_backdrop_shade = shade
    shade.color = Color("241f1a",0.24)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(shade)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var margin: MarginContainer = MarginContainer.new()
    hd_gameplay_margin = margin
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
    header.add_theme_stylebox_override("panel",style(Color("10271f",0.84),20))
    column.add_child(header)
    var header_row: HBoxContainer = HBoxContainer.new()
    header_row.add_theme_constant_override("separation",8)
    header.add_child(header_row)
    var menu_button: Button = action(header_row,"☰",show_ascend_menu)
    menu_button.custom_minimum_size = Vector2(50,54)
    menu_button.size_flags_horizontal = Control.SIZE_SHRINK_END
    menu_button.tooltip_text = "Zen Ascend menu"
    var title_box: VBoxContainer = VBoxContainer.new()
    title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header_row.add_child(title_box)
    header_row.move_child(menu_button,1)
    _hd_beta_boss_button(menu_button,false)
    rank_label = text(title_box,"",27,Color("f9e7b7"))
    rank_label.add_theme_font_override("font",ZenType.heading())
    text(title_box,Z("Zen Ascend 4×4"),18,Color("e8d1a9"))
    ascend_subtitle = text(title_box,L("subtitle"),12,Color("d6bfa4"))
    ascend_subtitle.hide()
    var scoreboard: PanelContainer = PanelContainer.new()
    scoreboard.add_theme_stylebox_override("panel",style(Color("10271f",0.82),16))
    column.add_child(scoreboard)
    var score_box: VBoxContainer = VBoxContainer.new()
    scoreboard.add_child(score_box)
    status_label = text(score_box,"",17,Color("fff2d5"))
    details_label = text(score_box,"",13,Color("d8bb7e"))
    var cube_card: PanelContainer = PanelContainer.new()
    var clear_cube: StyleBoxFlat = style(Color(0,0,0,0),0)
    clear_cube.set_border_width_all(0)
    clear_cube.set_content_margin_all(0.0)
    cube_card.add_theme_stylebox_override("panel",clear_cube)
    cube_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
    column.add_child(cube_card)
    cube_surface = TextureRect.new()
    cube_surface.texture = vp.get_texture()
    cube_surface.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    cube_surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    cube_surface.mouse_filter = Control.MOUSE_FILTER_STOP
    cube_surface.custom_minimum_size.y = 240
    cube_surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
    cube_surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cube_card.add_child(cube_surface)
    cube_surface.gui_input.connect(cube_input)
    var tip: PanelContainer = PanelContainer.new()
    tip.add_theme_stylebox_override("panel",style(Color("10271f",0.65),13))
    column.add_child(tip)
    instructions = text(tip,Z("Ziehen: drehen · Tippen: setzen · Zwei Finger: zoomen"),13)
    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override("separation",6)
    column.add_child(row)
    new_match_button = action(row,Z("Neue Partie"),show_mode_picker)
    rules_button = action(row,Z("Regeln ansehen"),show_rules)
    result_review_button = action(row,_result_button_label(),_reopen_finished_result)
    result_review_button.name = "ShowFinishedResult"
    result_review_button.hide()
    _hd_beta_boss_button(result_review_button,true)
    _hd_beta_boss_button(new_match_button,false)
    _hd_beta_boss_button(rules_button,false)
    row.show()
    var realm_actions: HBoxContainer = HBoxContainer.new()
    realm_actions.add_theme_constant_override("separation",6)
    column.add_child(realm_actions)
    realms_nav_button = action(realm_actions,L("realms"),show_realms)
    challenges_nav_button = action(realm_actions,L("challenges"),show_challenges,true)
    achievements_nav_button = action(realm_actions,_achievements_label(),show_realm_titles)
    for nav in [realms_nav_button,challenges_nav_button,achievements_nav_button]:
        _hd_beta_boss_button(nav,false)
        nav.add_theme_font_size_override("font_size",14)
    realm_actions.show()
    var quote_box: PanelContainer = PanelContainer.new()
    quote_box.add_theme_stylebox_override("panel",style(Color("10271f",0.65),13))
    column.add_child(quote_box)
    quote_label = text(quote_box,"",12,Color("f4dfbd"))

# Portrait art and all normal game UI keep the original presentation.
# Only landscape campaign arenas get the reduced crop and mild sharpening.
func _refresh_arena_presentation() -> void:
    if not is_instance_valid(realm_backdrop): return
    var tex: Texture2D = realm_backdrop.texture
    var landscape: bool = false
    if tex != null:
        var path: String = tex.resource_path
        landscape = tex.get_width()>tex.get_height() and ("/arenas/" in path or path.ends_with("/abyss_of_memories/gameplay.webp"))
    if landscape:
        var mat := ShaderMaterial.new()
        mat.shader = ARENA_BACKDROP_SHADER
        realm_backdrop.material = mat
        realm_backdrop.stretch_mode = TextureRect.STRETCH_SCALE
        realm_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    else:
        realm_backdrop.material = null
        realm_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        realm_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_PARENT_NODE
    if is_instance_valid(realm_backdrop_shade):
        realm_backdrop_shade.color = Color("241f1a",0.08 if landscape else 0.24)

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
    if result != 0:
        _reopen_finished_result()
        return
    if campaign_practice_active and hd_direct_realm:
        show_ascend_home()
        return
    if campaign_practice_active:
        _campaign_practice_menu()
        return
    if ember_active:
        _ember_menu()
        return
    if shadow_active:
        _shadow_menu()
        return
    if abyss_active:
        _abyss_menu()
        return
    if realm_story_active:
        _realm_story_menu()
        return
    show_ascend_home()

func _hd_chapter_allowed(chapter: int) -> bool:
    if chapter == 6: return SkyGarden.unlocked()
    if chapter == 5: return Moon.unlocked()
    return chapter >= 0 and chapter <= 4 and Realm2.unlocked(chapter)

func _hd_selected_chapter() -> int:
    if shadow_active: return 0
    if abyss_active: return 1
    if ember_active: return guardian_chapter
    if realm_story_active: return [0,2,3,4][clampi(int(RealmStory.chapter(realm_story_stage)),0,3)]
    if campaign_practice_active: return practice_chapter
    var saved: int = int(data.ascend.get("hd_selected_chapter",-1))
    if _hd_chapter_allowed(saved): return saved
    return [0,2,3,4][clampi(int(Realms.state(data).selected),0,3)]

func _hd_remember_chapter(chapter: int, direct: bool) -> void:
    if not _hd_chapter_allowed(chapter): return
    if int(data.ascend.get("hd_selected_chapter",-1)) == chapter and bool(data.ascend.get("hd_direct_realm",false)) == direct: return
    data.ascend["hd_selected_chapter"] = chapter
    data.ascend["hd_direct_realm"] = direct
    SaveManager.save_data(data)

func _hd_has_story_battle() -> bool:
    return shadow_active or abyss_active or ember_active or realm_story_active

func _hd_confirm_free_switch(next_action: Callable) -> void:
    if _hd_has_story_battle(): return
    if result == 0 and (move_count() > 0 or busy):
        var parts: Dictionary = _realm_dialog(_campaign_phrase("Laufende Partie","Match in progress","Partida em curso"),520)
        text(parts.box,_campaign_phrase("Die laufende freie Partie wird beendet. Dein Story-Fortschritt bleibt erhalten.","The current free match will be abandoned. Your story progress is kept.","A partida livre atual será abandonada. O progresso da história será mantido."),16)
        action(parts.box,_campaign_phrase("Partie fortsetzen","Resume match","Retomar partida"),_close_realm_dialog.bind(parts.dialog),true)
        action(parts.box,_campaign_phrase("Wechsel bestätigen","Confirm switch","Confirmar mudança"),next_action)
        _hd_menu_dialog(parts,false)
        _open_realm_dialog(parts)
    else:
        next_action.call()

func _hd_enter_realm(chapter: int) -> void:
    if chapter < 0 or chapter > 4 or not Realm2.unlocked(chapter) or _hd_has_story_battle(): return
    # Resume the actual board rather than replacing an unfinished match in the same Realm.
    var same_board: bool = (campaign_practice_active and practice_chapter == chapter) or (chapter == 0 and not campaign_practice_active and realm_index() == 0)
    if same_board and result == 0 and (move_count() > 0 or busy):
        hd_direct_realm = campaign_practice_active
        _hd_remember_chapter(chapter,chapter != 0)
        if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
        return
    _hd_confirm_free_switch(_hd_enter_realm_now.bind(chapter,true))

func _hd_enter_realm_now(chapter: int, begin_match: bool) -> void:
    if chapter < 0 or chapter > 4 or not Realm2.unlocked(chapter) or _hd_has_story_battle(): return
    # Called only after confirmation or with an idle board. Invalidate queued bot work.
    match_generation += 1
    busy = false
    cells.fill(0)
    result = 0
    recorded = false
    turn = 1
    campaign_practice_active = false
    campaign_awards = []
    _hd_remember_chapter(chapter,chapter != 0)
    start_campaign_practice(chapter,true,begin_match)

func _hd_restore_selected_board() -> void:
    var chapter: int = int(data.ascend.get("hd_selected_chapter",-1))
    if chapter >= 1 and chapter <= 4 and bool(data.ascend.get("hd_direct_realm",false)) and Realm2.unlocked(chapter):
        _hd_enter_realm_now(chapter,false)

func _hd_continue_campaign_now(chapter: int) -> void:
    if not _hd_chapter_allowed(chapter) or _hd_has_story_battle(): return
    if chapter <= 4:
        _hd_enter_realm_now(chapter,false)
        _open_campaign_story_from_match(chapter)
    else:
        match_generation += 1
        busy = false
        cells.fill(0)
        result = 0
        recorded = false
        turn = 1
        campaign_practice_active = false
        hd_direct_realm = false
        campaign_awards = []
        ZenChronicles.set_campaign_board_active(false)
        _hd_remember_chapter(chapter,false)
        draw()
        if chapter == 6: _open_sky_from_realms()
        else: _open_shattered_from_realms()

func _home_story_chapter() -> int:
    for chapter in range(5):
        if Realm2.unlocked(chapter) and not Realm2.ready(chapter): return chapter
    if SkyGarden.unlocked(): return 6
    if Moon.unlocked(): return 5
    return 4

func _hd_gold_focus() -> StyleBoxFlat:
    var outline := StyleBoxFlat.new()
    outline.bg_color = Color(0,0,0,0)
    outline.draw_center = false
    outline.border_color = Color("d8bb7e")
    outline.set_border_width_all(1)
    outline.set_corner_radius_all(15)
    return outline

func _hd_home_frame(fill: Color, border: Color, radius: int = 16) -> StyleBoxFlat:
    var skin := style(fill,radius)
    skin.set_border_width_all(1)
    skin.border_color = border
    skin.content_margin_left = 12
    skin.content_margin_right = 12
    skin.content_margin_top = 8
    skin.content_margin_bottom = 8
    return skin

func _hd_realm_scenery(chapter: int) -> String:
    if chapter == 6: return SkyGarden.REALM_ART
    if chapter == 5: return Moon.REALM_ART
    if chapter == 1 and ResourceLoader.exists(Abyss.gameplay_art()): return Abyss.gameplay_art()
    return Realm2.SOURCE_ART[clampi(chapter,0,4)]

func _home_button(parent: Node, caption: String, callback: Callable, featured: bool = false) -> Button:
    var b := action(parent,caption,callback,true)
    var in_row: bool = parent is HBoxContainer
    b.custom_minimum_size.y = 66 if featured else (52 if in_row else 48)
    b.add_theme_font_size_override("font_size",20 if featured else (16 if in_row else 15))
    for state in ["normal","hover","pressed","disabled"]:
        var color: Color = Color("d8bb7e") if featured else (Color("18382c") if in_row else Color("102a25",0.35))
        if state == "hover": color = Color("dfc58b") if featured else Color("315747")
        elif state == "pressed": color = Color("c8aa71") if featured else Color("102a25")
        elif state == "disabled": color = Color("35453c",0.90)
        var edge: Color = Color("d8bb7e") if featured else (Color("8d9870") if in_row else Color("cfb37e",0.45))
        b.add_theme_stylebox_override(state,_hd_home_frame(color,edge,18 if featured else 15))
    for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
        b.add_theme_color_override(key,Color("102a25") if featured else Color("fff2d5"))
    b.add_theme_color_override("font_disabled_color",Color("b5b8a7"))
    b.add_theme_stylebox_override("focus",_hd_gold_focus())
    return b

func show_ascend_home() -> void:
    var parts: Dictionary = _realm_dialog("Zen Ascend",900)
    var dialog: Control = parts.dialog
    dialog.name = "AscendHomeScreen"
    var frame: PanelContainer = parts.frame
    frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    # Match the Classic home shell, with no enclosing gold frame.
    var shell := style(Color("10271f",0.80),0)
    shell.set_border_width_all(0)
    shell.shadow_size = 0
    shell.content_margin_left = 26
    shell.content_margin_right = 26
    shell.content_margin_top = 18
    shell.content_margin_bottom = 18
    frame.add_theme_stylebox_override("panel",shell)
    var tint: ColorRect = dialog.get_child(0) as ColorRect
    tint.color = Color(0,0,0,0)
    if is_instance_valid(hd_gameplay_margin): hd_gameplay_margin.hide()
    var scroller: ScrollContainer = parts.scroller
    var stack: VBoxContainer = scroller.get_parent() as VBoxContainer
    for child in stack.get_children():
        if child != scroller:
            stack.remove_child(child)
            child.queue_free()
    var body: VBoxContainer = parts.box
    body.add_theme_constant_override("separation",9)
    var chapter: int = _hd_selected_chapter()
    var background := TextureRect.new()
    var artwork: String = _hd_realm_scenery(chapter)
    background.name = "AscendHomeScenery"
    if ResourceLoader.exists(artwork): background.texture = load(artwork)
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    dialog.add_child(background)
    dialog.move_child(background,0)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var top := HBoxContainer.new()
    top.add_theme_constant_override("separation",8)
    body.add_child(top)
    var profile := _home_button(top,_campaign_phrase("Profil","Profile","Perfil"),show_statistics)
    profile.name = "AscendHomeProfile"
    profile.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    profile.custom_minimum_size = Vector2(66,44)
    profile.add_theme_font_size_override("font_size",15)
    for state in ["normal","hover","pressed"]:
        var shade: Color = Color("102a25",0.35) if state == "normal" else Color("28523d")
        profile.add_theme_stylebox_override(state,_hd_home_frame(shade,Color("cfb37e",0.45),14))
    var space := Control.new()
    space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(space)
    var settings := _home_button(top,"⚙",show_ascend_settings)
    settings.name = "AscendSettingsEntry"
    settings.tooltip_text = _campaign_phrase("Einstellungen","Settings","Definições")
    settings.custom_minimum_size = Vector2(44,44)
    settings.add_theme_font_size_override("font_size",15)
    for state in ["normal","hover","pressed"]:
        var shade: Color = Color("102a25",0.35) if state == "normal" else Color("28523d")
        settings.add_theme_stylebox_override(state,_hd_home_frame(shade,Color("cfb37e",0.45),14))
    settings.size_flags_horizontal = Control.SIZE_SHRINK_END
    var title := text(body,"Zen Ascend",36,Color("fff2d5"))
    title.add_theme_font_override("font",ZenType.heading())
    text(body,L("subtitle"),15,Color("d8bb7e"))
    var hero := TextureRect.new()
    hero.name = "AscendHomeCubePreview"
    hero.custom_minimum_size.y = 205
    hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
    body.add_child(hero)
    var preview := SubViewport.new()
    preview.size = Vector2i(540,540)
    preview.transparent_bg = true
    preview.own_world_3d = true
    preview.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
    hero.add_child(preview)
    var preview_cube := AscendRenderer.new()
    preview.add_child(preview_cube)
    preview_cube.set_skin(int(data.economy.get("equipped",0)))
    preview_cube.set_realm_theme(chapter if chapter < 5 else -1)
    var example: Array = []
    example.resize(Mode.CELLS)
    example.fill(0)
    for cell in [4,5,6]: example[cell] = 1
    for cell in [0,9,15]: example[cell] = 2
    preview_cube.repaint(example,[])
    preview_cube.pivot.rotation = Vector3(0.40,-0.58,0.0)
    hero.texture = preview.get_texture()
    var destination: String = "Sky Garden" if chapter==6 else ("Shattered Moon" if chapter==5 else Realm2.REALM_NAMES[chapter])
    text(body,destination,18,Color("d8bb7e")).name = "AscendHomeSelectedRealm"
    text(body,_campaign_phrase("Deine Reise geht weiter.","Your journey continues.","A tua viagem continua."),15,Color("fff2d5"))
    _home_button(body,_campaign_phrase("Kampagne fortsetzen","Continue Campaign","Continuar campanha"),_continue_ascend_campaign,true).name = "AscendHomeCampaign"
    _home_button(body,"Zen Chronicles",_open_campaign_library_from_realms).name = "AscendHomeChronicles"
    var first := HBoxContainer.new()
    first.add_theme_constant_override("separation",8)
    body.add_child(first)
    _home_button(first,L("realms"),show_realms).name = "AscendHomeRealms"
    _home_button(first,L("challenges"),_open_campaign_trials_from_realms.bind(mini(chapter,4))).name = "AscendHomeChallenges"
    var second := HBoxContainer.new()
    second.add_theme_constant_override("separation",8)
    body.add_child(second)
    _home_button(second,_achievements_label(),show_realm_titles).name = "AscendHomeAchievements"
    var shop := _home_button(second,"Zen Shop",_open_shop_from_ascend)
    shop.name = "AscendHomeShop"
    shop.disabled = move_count()>0 and result==0
    var third := HBoxContainer.new()
    third.add_theme_constant_override("separation",8)
    body.add_child(third)
    _home_button(third,_campaign_phrase("Spielmodi","Game Modes","Modos de jogo"),show_mode_picker).name = "AscendHomeGameModes"
    _home_button(third,_campaign_phrase("Spielanleitung","How to Play","Como jogar"),show_rules).name = "AscendHomeHowToPlay"
    _home_button(body,_campaign_phrase("Partie fortsetzen","Resume match","Retomar partida"),_close_realm_dialog.bind(dialog)).name = "AscendHomeResume"
    _home_button(body,_campaign_phrase("Zum Hauptmenü","Back to main menu","Voltar ao menu principal"),return_home)
    if Realm2.qa_mode():
        action(body,"Ember Boss · VFX Test",_show_ember_vfx_test)
    _open_realm_dialog(parts)

func _continue_ascend_campaign() -> void:
    var chapter: int = _home_story_chapter()
    if _hd_has_story_battle():
        if _hd_selected_chapter() == chapter or realm_story_active:
            if result != 0:
                if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
                _reopen_finished_result()
            elif shadow_active: _shadow_begin()
            elif abyss_active: _abyss_begin()
            elif ember_active: _ember_begin()
            else: _realm_story_begin()
            return
        # The native story models save their own battle. A replay of another
        # chapter must not redirect Continue away from the real campaign.
        if shadow_active: _shadow_back_to_reader(false)
        elif abyss_active: _abyss_back_to_reader(false)
        elif ember_active: _ember_back_to_reader(false)
    _hd_confirm_free_switch(_hd_continue_campaign_now.bind(chapter))

func _open_shop_from_ascend() -> void:
    if move_count()>0 and result==0: return
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    SaveManager.save_data(data)
    ZenChronicles.request_classic_shop()

func _save_ascend_setting(key: String, value: Variant) -> void:
    data.settings[key] = value
    SaveManager.save_data(data)
    if key=="music" or key=="music_mode" or key=="music_track":
        sync_realm_music(true)
    if key=="language":
        new_match_button.text = Z("Neue Partie")
        rules_button.text = Z("Regeln ansehen")
        result_review_button.text = _result_button_label()
        realms_nav_button.text = L("realms")
        challenges_nav_button.text = L("challenges")
        achievements_nav_button.text = _achievements_label()
        ascend_subtitle.text = L("subtitle")
    draw()

func _save_ascend_name(index: int, value: String) -> void:
    var default_name: String = "Du" if index==0 else "Spieler 2"
    var localized: String = Locale.translate(default_name,lang())
    var cleaned: String = value.strip_edges()
    if cleaned==localized and str(data.settings.names[index])==default_name: return
    var names: Array = data.settings.names.duplicate()
    names[index] = default_name if cleaned.is_empty() else cleaned
    _save_ascend_setting("names",names)

func show_ascend_settings() -> void:
    var parts: Dictionary = _realm_dialog(_campaign_phrase("Einstellungen","Settings","Definições"),700)
    var body: VBoxContainer = parts.box
    for i in range(2):
        var index: int = i
        text(body,_campaign_phrase("Spielername","Player name","Nome do jogador")+" "+str(i+1),15)
        var field: LineEdit = LineEdit.new()
        field.name = "AscendSettingsName%d" % i
        field.max_length = 24
        var stored: String = str(data.settings.names[i])
        field.text = Locale.translate(stored,lang()) if stored==("Du" if i==0 else "Spieler 2") else stored
        SettingsTheme.settings_field(field)
        body.add_child(field)
        field.text_submitted.connect(func(value: String): _save_ascend_name(index,value))
        field.focus_exited.connect(func(): _save_ascend_name(index,field.text))
    text(body,_campaign_phrase("Sprache","Language","Idioma"),15)
    var languages: OptionButton = OptionButton.new()
    languages.name = "AscendSettingsLanguage"
    SettingsTheme.settings_picker(languages)
    for label in ["Deutsch","English","Português"]: languages.add_item(label)
    languages.select(maxi(0,["de","en","pt"].find(lang())))
    body.add_child(languages)
    languages.item_selected.connect(func(index: int):
        _save_ascend_setting("language",["de","en","pt"][index])
        call_deferred("show_ascend_settings"))
    text(body,_campaign_phrase("Bot-Schwierigkeit","Bot difficulty","Dificuldade do bot"),15)
    var difficulty := Label.new()
    difficulty.name = "AscendSettingsDifficulty"
    difficulty.text = _bot_difficulty_name() + " · " + _campaign_phrase("Vorgegeben","Fixed","Fixa")
    difficulty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    difficulty.add_theme_font_size_override("font_size",18)
    difficulty.add_theme_color_override("font_color",Color("fff2d5"))
    var difficulty_card := PanelContainer.new()
    difficulty_card.add_theme_stylebox_override("panel",_hd_home_frame(Color("18382c",0.92),Color("d8bb7e",0.65)))
    body.add_child(difficulty_card)
    difficulty_card.add_child(difficulty)
    text(body,_campaign_phrase("Die Schwierigkeit folgt dem Realm oder dem Boss.","Difficulty follows the Realm or boss.","A dificuldade depende do reino ou do chefe."),12,Color("d8bb7e"))
    var toggles: Array = [
        ["music",_campaign_phrase("Musik","Music","Música"),false],
        ["sound",_campaign_phrase("Soundeffekte","Sound effects","Efeitos sonoros"),true],
        ["haptics",_campaign_phrase("Vibration","Vibration","Vibração"),true]]
    for entry in toggles:
        var key: String = str(entry[0])
        var toggle: CheckButton = CheckButton.new()
        toggle.name = "AscendSettings_"+key
        SettingsTheme.settings_switch(toggle)
        toggle.text = str(entry[1])
        toggle.button_pressed = bool(data.settings.get(key,entry[2]))
        body.add_child(toggle)
        toggle.toggled.connect(func(enabled: bool): _save_ascend_setting(key,enabled))
    text(body,_campaign_phrase("Musiktitel","Music track","Faixa musical"),15)
    var tracks: OptionButton = OptionButton.new()
    SettingsTheme.settings_picker(tracks)
    tracks.name = "AscendSettingsMusicTrack"
    tracks.add_item(MusicPolicy.base_label(lang()),99)
    var names: Array = ["Zen-Garten (Original)","Klangschalen – Stiller Tempel","Handpan – Sanfter Rhythmus","Nebelpfad","Stein und Wasser","Regentropfen im Zen-Garten","Sternenlicht am Tempel","Whispers of the Ancient Forest","Echoes of a Forgotten Dream","The Path of Serenity","Where the Waters Sleep","Spirit of the Jade River","A Thousand Silent Skies","Tales Beneath the Golden Sun"]
    var selected: int = 0
    for id in [0,1,2,5,6,8,9,10,11,12,13]:
        if not ZenCollection.music_unlocked(data,id): continue
        var label: String = Locale.translate(str(names[id]),lang())
        tracks.add_item(label,id)
        if MusicPolicy.mode(data)=="manual" and int(data.settings.get("music_track",7))==id: selected = tracks.item_count-1
    tracks.select(selected)
    body.add_child(tracks)
    tracks.item_selected.connect(func(index: int):
        var id: int = tracks.get_item_id(index)
        data.settings.music_mode = "base" if id==99 else "manual"
        if id!=99: data.settings.music_track = id
        SaveManager.save_data(data)
        sync_realm_music(true))
    action(body,_campaign_phrase("Fertig","Done","Concluído"),_close_realm_dialog.bind(parts.dialog),true)
    _hd_menu_dialog(parts, false)
    _open_realm_dialog(parts)

func pname(owner: int) -> String:
    if against_bot and owner == 1: return zen_ascend_bot_name()
    var names: Array = data.settings.names
    var index: int = clampi(owner,0,1)
    var stored: String = str(names[index])
    if stored == ("Du" if index==0 else "Spieler 2"):
        return _campaign_phrase(stored,"You" if index==0 else "Player 2","Tu" if index==0 else "Jogador 2")
    return stored
func move_count() -> int:
    return Mode.CELLS - cells.count(0)
func _review_board_label() -> String:
    return "Spielfeld ansehen" if lang()=="de" else ("Ver tabuleiro" if lang()=="pt" else "Inspect board")

func _result_button_label() -> String:
    return "Ergebnis anzeigen" if lang()=="de" else ("Ver resultado" if lang()=="pt" else "Show result")

func _review_finished_board(dialog: Control) -> void:
    if result == 0: return
    _close_realm_dialog(dialog)
    touch_positions.clear()
    touched_cell = -1
    dragged = false
    mouse_pressed = false

func _reopen_finished_result() -> void:
    if result == 0 or is_instance_valid(active_realm_dialog): return
    if ember_active: _ember_result()
    elif shadow_active: _shadow_result()
    elif abyss_active: _abyss_result()
    elif realm_story_active: _realm_story_result()
    elif campaign_practice_active: _campaign_practice_result()
    else: show_match_result()

func draw() -> void:
    if cube == null: return
    var wins: Array = []
    if result in [1,2]:
        for line in Mode.winning_lines(cells,lines,result):
            for c in line:
                if not wins.has(c): wins.append(c)
    var cosmetic_chapter: int = practice_chapter if campaign_practice_active else [0,2,3,4][clampi(match_realm,0,3)]
    cube.set_realm_theme(cosmetic_chapter,false)
    cube.repaint(cells,wins)
    if is_instance_valid(rules_button): rules_button.visible = result == 0
    if is_instance_valid(result_review_button):
        result_review_button.visible = result != 0
        var review_row: Control = result_review_button.get_parent() as Control
        if review_row != null: review_row.show()
        new_match_button.visible = result == 0
        rules_button.visible = result == 0
    if is_instance_valid(instructions):
        instructions.text = _campaign_phrase("Partie beendet · Drehen und zoomen","Match finished · Rotate and zoom","Partida terminada · Roda e amplia") if result != 0 else Z("Ziehen: drehen · Tippen: setzen · Zwei Finger: zoomen")
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
        status_label.text = zen_ascend_bot_name() + " · " + _campaign_phrase("überlegt …","Thinking…","A pensar…")
    else:
        status_label.text = pname(int(owners[turn-1]))+" · "+Z("Du bist am Zug")+" · "+("X" if turn==1 else "O")
    details_label.text = "%s X  ·  %s O  ·  %d/96" % [pname(int(owners[0])),pname(int(owners[1])),move_count()]
    if is_instance_valid(new_match_button):
        new_match_button.text = _campaign_phrase("Neustart","Restart","Reiniciar") if (ember_active or shadow_active or abyss_active or realm_story_active) and result==0 else Z("Neue Partie")
    if campaign_practice_active:
        rank_label.text = Realm2.REALM_NAMES[practice_chapter] + " · Zen-Bot"
        quote_label.text = _campaign_realm_quote(practice_chapter)
        details_label.text = Realm2.REALM_NAMES[practice_chapter] + " · %d/96 · Challenges %d/3" % [move_count(),Realm2.completed_count(Realm2.load_progress(),practice_chapter)]
    if ember_active:
        rank_label.text = ember_model.BOSS_NAMES[clampi(ember_index,0,2)]
        quote_label.text = _campaign_realm_quote(guardian_chapter)
        status_label.text = _boss_turn_status(rank_label.text)
        details_label.text = _hd_beta_round_line(ember_progress)
    if shadow_active:
        rank_label.text = Shadow.BOSS_NAMES[clampi(shadow_index,0,2)]
        quote_label.text = _campaign_realm_quote(0)
        status_label.text = _boss_turn_status(rank_label.text)
        details_label.text = _hd_beta_round_line(shadow_progress) if shadow_index==2 else "Shadow · " + str(move_count()) + "/96"
    if abyss_active:
        rank_label.text = Abyss.BOSS_NAMES[clampi(abyss_index,0,2)]
        quote_label.text = _campaign_realm_quote(1)
        status_label.text = _boss_turn_status(rank_label.text)
        details_label.text = _hd_beta_round_line(abyss_progress) if abyss_index==2 else "Abyss · " + str(move_count()) + "/96"
    if realm_story_active:
        rank_label.text = RealmStory.text_for(lang(),"boss_%d" % realm_story_stage)
        status_label.text = _boss_turn_status(rank_label.text)
        quote_label.text = RealmStory.text_for(lang(),"react_%d" % realm_story_stage)
        details_label.text = RealmStory.text_for(lang(),"skin")+" · "+str(move_count())+"/96"

func _boss_turn_status(boss_name: String) -> String:
    if result==1: return _campaign_phrase("Du hast gewonnen · X","You won · X","Venceste · X")
    if result==2: return boss_name + " · " + _campaign_phrase("Sieg · O","Victory · O","Vitória · O")
    if result==3: return _campaign_phrase("Unentschieden","Draw","Empate")
    if turn==1: return _campaign_phrase("Du bist am Zug · X","Your turn · X","A tua vez · X")
    return boss_name + " · " + _campaign_phrase("überlegt … · O","thinking … · O","a pensar … · O")

func _campaign_realm_quote(chapter: int) -> String:
    var de: Array[String] = ["Auch der tiefste Schatten kann einen Weg zeigen.","Was du erinnerst, muss dich nicht gefangen halten.","Ein ruhiger Geist überdauert jede Flamme.","Über den Wolken beginnt die Klarheit.","In der Stille findet jeder Zug seine Bedeutung."]
    var en: Array[String] = ["Even the deepest shadow can reveal a path.","What you remember need not hold you captive.","A steady mind outlasts the brightest flame.","Above the clouds, clarity begins.","In stillness, every move finds its meaning."]
    var pt: Array[String] = ["Até a sombra mais profunda pode revelar um caminho.","O que recordas não tem de te aprisionar.","Uma mente serena resiste à chama mais forte.","Acima das nuvens começa a clareza.","Na quietude, cada jogada ganha sentido."]
    var pool: Array[String] = de if lang()=="de" else (pt if lang()=="pt" else en)
    return "“" + pool[clampi(chapter,0,4)] + "”"

func _confirm_boss_restart() -> void:
    if result!=0: 
        _reopen_finished_result()
        return
    var parts: Dictionary = _realm_dialog(_campaign_phrase("Runde neu starten?","Restart round?","Reiniciar ronda?"),430)
    var body: VBoxContainer = parts.box
    var series: bool = ember_active or (shadow_active and shadow_index==2) or (abyss_active and abyss_index==2)
    if series:
        text(body,_campaign_phrase("Die laufende Runde zählt als Niederlage. Bisherige Punkte bleiben gespeichert.","The current round counts as a loss. Existing series points remain saved.","A ronda atual conta como derrota. Os pontos anteriores ficam guardados."),16)
    else:
        text(body,_campaign_phrase("Das aktuelle Spielfeld wird zurückgesetzt.","The current board will be reset.","O tabuleiro atual será reiniciado."),16)
    action(body,_campaign_phrase("Neustart bestätigen","Confirm restart","Confirmar reinício"),_restart_boss_round,true)
    _hd_menu_dialog(parts, true)
    _open_realm_dialog(parts)

func _restart_boss_round() -> void:
    if result!=0: return
    if not (ember_active or shadow_active or abyss_active or realm_story_active): return
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    match_generation += 1
    busy = false
    if realm_story_active:
        _realm_story_retry()
        return
    # Explicit forfeit for series; never erase already earned round points.
    result = 2
    recorded = true
    if ember_active:
        if _ember_save(): _ember_result()
    elif shadow_active:
        if _shadow_save():
            if shadow_index==2: _shadow_result()
            else: _shadow_retry()
    elif abyss_active:
        if _abyss_save():
            if abyss_index==2: _abyss_result()
            else: _abyss_retry()
    draw()

func _guardian_series_score(progress: Dictionary) -> String:
    var tally: Dictionary = FinalSeries.score(progress)
    return _campaign_phrase("Best of 3 · Kuze %d : %d Wächter","Best of 3 · Kuze %d : %d Guardian","Melhor de 3 · Kuze %d : %d Guardião") % [int(tally.player),int(tally.guardian)]

func _boss_starter_caption(game: Dictionary) -> String:
    var starter: int = FinalSeries.round_starter(game)
    var caption: String = _campaign_phrase("Du beginnst (X)","You start (X)","Começas (X)") if starter==1 else _campaign_phrase("Boss beginnt (O)","Boss starts (O)","O chefe começa (O)")
    if move_count()>0:
        var next: String = _campaign_phrase("Du bist am Zug (X)","Your turn (X)","A tua vez (X)") if turn==1 else _campaign_phrase("Boss am Zug (O)","Boss turn (O)","Vez do chefe (O)")
        caption = (_campaign_phrase("Start: Du (X)","Started: You (X)","Início: Tu (X)") if starter==1 else _campaign_phrase("Start: Boss (O)","Started: Boss (O)","Início: Chefe (O)")) + " · " + next
    return caption

func _hd_beta_round_line(progress: Dictionary) -> String:
    var score: Dictionary = FinalSeries.score(progress)
    var decisive: int = int(score.player) + int(score.guardian)
    var number: int = clampi(decisive + (0 if result in [1,2] else 1),1,3)
    return _campaign_phrase("Runde %d/3","Round %d/3","Ronda %d/3") % number + " · %d:%d · %d/96" % [int(score.player),int(score.guardian),move_count()]

func _guardian_series_panel(body: VBoxContainer, progress: Dictionary) -> void:
    var tally: Dictionary = FinalSeries.score(progress)
    var current: Dictionary = progress.get("game",{})
    var decisive: int = int(tally.player)+int(tally.guardian)
    var round_number: int = clampi(decisive+(0 if int(current.get("result",0)) in [1,2] else 1),1,3)
    text(body,_campaign_phrase("Runde %d / 3","Round %d / 3","Ronda %d / 3") % round_number,15,Color("#e5ca93"))
    text(body,_guardian_series_score(progress),19,Color("#e5ca93"))
    if FinalSeries.player_won(progress):
        text(body,_campaign_phrase("Finaler Wächter besiegt","Final Guardian defeated","Guardião final derrotado"),15,Color("#c8e8b4"))
    elif FinalSeries.guardian_won(progress):
        text(body,_campaign_phrase("Serie verloren · Neuer Versuch","Series lost · Try again","Série perdida · Tenta novamente"),15)
    else:
        text(body,_campaign_phrase("Zwei Siege zum Weiterkommen","Win two rounds to continue","Vence duas rondas para continuar"),15)

func _pick_position(pos: Vector2) -> int:
    if cube_surface == null or cube == null: return -1
    var square: float = minf(cube_surface.size.x,cube_surface.size.y)
    if square < 1.0: return -1
    var offset: Vector2 = (cube_surface.size - Vector2(square,square))*0.5
    var inside: Vector2 = (pos-offset) / square
    if inside.x < 0.0 or inside.x >= 1.0 or inside.y < 0.0 or inside.y >= 1.0: return -1
    return cube.pick(inside * 960.0)

func cube_input(event: InputEvent) -> void:
    if busy: return
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
                if result == 0 and touched_cell >= 0 and touched_cell == end_cell: play(end_cell)
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
                if result == 0 and touched_cell >= 0 and touched_cell == end_cell: play(end_cell)
    elif event is InputEventMouseMotion and mouse_pressed and not heard_touch:
        if event.position.distance_to(touch_down) > 12.0: dragged = true
        if dragged: cube.rotate_cube(event.relative)

func start_game(bot: bool, level: int = -1) -> void:
    if campaign_practice_active:
        _campaign_practice_restart()
        return
    if ember_active:
        _ember_retry()
        return
    if shadow_active:
        _shadow_retry()
        return
    if abyss_active:
        _abyss_retry()
        return
    if realm_story_active:
        _realm_story_retry()
        return
    against_bot = bot
    match_generation += 1
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
    if bot:
        # Alternate real matches with the Realm bot, including rematches.
        # Persist across sessions; puzzle challenges are not bot matches.
        var count: int = int(data.ascend.get("normal_bot_start_counter",0))
        turn = 1 if count % 2 == 0 else 2
        data.ascend.normal_bot_start_counter = count+1
        SaveManager.save_data(data)
    cube.reset_view()
    draw()
    if bot and turn == 2:
        busy = true
        draw()
        call_deferred("bot_turn")

func play(cell: int) -> void:
    if result != 0 or busy or cell < 0 or cell >= Mode.CELLS or int(cells[cell]) != 0: return
    if against_bot and turn == 2: return
    if realm_story_active: realm_story_last_human = cell
    if abyss_active: abyss_last_human = cell
    if ember_active: ember_last_human = cell
    if shadow_active: shadow_last_human = cell
    _commit(cell)
    if realm_story_active and result == 0: _realm_story_save()
    if abyss_active and result == 0: _abyss_save()
    if ember_active and result == 0: _ember_save()
    if shadow_active and result == 0: _shadow_save()
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
    var started_match: int = match_generation
    var generation: int = realm_story_generation
    var began_in_story: bool = realm_story_active
    var began_in_abyss: bool = abyss_active
    var started_abyss: int = abyss_generation
    var began_in_shadow: bool = shadow_active
    var started_shadow: int = shadow_generation
    var began_in_practice: bool = campaign_practice_active
    var delay: float = [0.36,0.40,0.75,0.14,0.31,0.55,0.44,0.55,0.75,0.88,0.74,1.05][clampi(realm_story_stage,0,11)] if realm_story_active else 0.26
    await get_tree().create_timer(delay).timeout
    if not is_inside_tree() or result != 0 or not against_bot or started_match != match_generation: return
    # After leaving a story, realm_story_active becomes false. Check the
    # launch context TOO, otherwise an awaited story bot could continue on
    # the restored ordinary 4x4 board after the player has left.
    if began_in_story and (not realm_story_active or generation != realm_story_generation): return
    if not began_in_story and realm_story_active: return
    if began_in_abyss and (not abyss_active or abyss_generation != started_abyss): return
    if not began_in_abyss and abyss_active: return
    if began_in_shadow and (not shadow_active or shadow_generation != started_shadow): return
    if not began_in_shadow and shadow_active: return
    if began_in_practice != campaign_practice_active: return
    var cell: int = ember_model.choose_move(cells,lines,ember_index,ember_last_human) if ember_active else Shadow.choose_move(cells,lines,shadow_index,shadow_last_human) if shadow_active else (Abyss.choose_move(cells,lines,abyss_index,abyss_last_human) if abyss_active else (RealmStory.choose_move(cells,lines,realm_story_stage,realm_story_last_human) if realm_story_active else RealmBot.next_move(cells,lines,2,bot_level,match_realm == 0)))
    busy = false
    if cell >= 0: _commit(cell)
    if realm_story_active and result == 0: _realm_story_save()
    if abyss_active and result == 0: _abyss_save()
    if ember_active and result == 0: _ember_save()
    if shadow_active and result == 0: _shadow_save()
    draw()

func _present_current_boss_result(generation: int, callback: Callable) -> void:
    if not is_inside_tree():
        return
    if generation != match_generation or result == 0:
        return
    if callback.is_valid():
        callback.call()

func finish() -> void:
    if campaign_practice_active:
        if recorded: return
        recorded = true
        busy = false
        var crossed: bool = false
        if result == 1:
            for line in Mode.winning_lines(cells,lines,1):
                if int(line[0]/16) != int(line[3]/16):
                    crossed = true
                    break
        var outcome: int = 1 if result==1 else (0 if result==3 else -1)
        campaign_awards = Realm2.record_satori_match(outcome,crossed,match_blocked_threat,move_count()) if practice_chapter==4 else (Realm2.record_celestial_match(outcome,crossed,match_blocked_threat,move_count()) if practice_chapter==3 else (Realm2.record_ember_match(outcome,crossed,move_count()) if practice_chapter==2 else Realm2.record_abyss_match(outcome,crossed,move_count())))
        campaign_award_index = 0
        # A newly earned 4x4 Realm challenge gets the same full-screen
        # ceremony as a secret achievement before the normal result screen.
        if campaign_awards.is_empty():
            call_deferred("_campaign_practice_result")
        else:
            call_deferred("_campaign_practice_show_next_award")
        return
    if ember_active:
        if recorded: return
        recorded = true
        busy = false
        _ember_save()
        call_deferred("_present_current_boss_result", match_generation, Callable(self, "_ember_result"))
        return
    if shadow_active:
        if recorded: return
        recorded = true
        busy = false
        _shadow_save()
        call_deferred("_present_current_boss_result", match_generation, Callable(self, "_shadow_result"))
        return
    if abyss_active:
        if recorded: return
        recorded = true
        busy = false
        _abyss_save()
        call_deferred("_present_current_boss_result", match_generation, Callable(self, "_abyss_result"))
        return
    if realm_story_active:
        if recorded: return
        recorded = true
        busy = false
        _realm_story_save()
        call_deferred("_present_current_boss_result", match_generation, Callable(self, "_realm_story_result"))
        return
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
        # Queue each newly earned task separately; Continue advances the queue.
        for earned_task_id in last_realm_awards.get("new_tasks",[]):
            for task in Realms.TASKS[match_realm]:
                if str(task.id) == str(earned_task_id):
                    queued_unlocks.append({"kind":"challenge","realm":match_realm,"name":str(task.title),"quote":Realms.task_description(task,lang())})
                    break
        for secret in Achievements.claim_after_match(data,match_realm):
            queued_unlocks.append({"kind":"achievement","realm":match_realm,"name":str(secret.name),"quote":str(secret.quote)})
        if bool(last_realm_awards.get("realm_completed",false)):
            queued_unlocks.append({"kind":"achievement","realm":match_realm,"name":Achievements.MAIN_TITLES[match_realm],"quote":Achievements.main_quote(match_realm)})
        # Ordinary matches still earn existing achievements and leaves.
        # They never trigger the Campaign 2.0 breakthrough.
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
    if str(item.kind) == "challenge":
        unlock.name = "ZenAscendChallengeEarnedCeremony"
    add_child(unlock)
    unlock.finished.connect(func():
        if is_inside_tree(): call_deferred("_show_next_unlock")
    )
    unlock.present(str(item.kind),str(Realms.REALM_ART[int(item.realm)]),str(item.name),str(item.quote),bool(data.settings.get("sound",true)),[world_music],lang())

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
    action(body,"Zen Realm Chronicles",_open_campaign_library_from_realms,true).name = "AscendEntryChronicles"
    _hd_menu_dialog(parts, false)
    _open_realm_dialog(parts)

func _start_picker_after_rules(dialog: Control) -> void:
    _close_realm_dialog(dialog)
    show_mode_picker()

func show_mode_picker() -> void:
    if ember_active or shadow_active or abyss_active or realm_story_active:
        _confirm_boss_restart()
        return
    if campaign_practice_active and hd_direct_realm:
        var direct_parts: Dictionary = _realm_dialog(Realm2.REALM_NAMES[practice_chapter],510)
        text(direct_parts.box,_campaign_phrase("Feste Realm-Schwierigkeit","Fixed Realm difficulty","Dificuldade fixa do reino"),15)
        action(direct_parts.box,zen_ascend_bot_name(),_hd_confirm_free_switch.bind(_hd_enter_realm_now.bind(practice_chapter,true)),true)
        action(direct_parts.box,Z("Regeln ansehen"),show_rules)
        action(direct_parts.box,"Zen Realm Chronicles",_open_campaign_library_from_realms,true).name = "AscendEntryChronicles"
        _hd_menu_dialog(direct_parts,false)
        _open_realm_dialog(direct_parts)
        return
    if campaign_practice_active:
        _campaign_practice_menu()
        return
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
    action(body,"Zen Realm Chronicles",_open_campaign_library_from_realms,true).name = "AscendEntryChronicles"
    _hd_menu_dialog(parts, false)
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
    _hd_menu_dialog(parts, false)
    _open_realm_dialog(parts)

func _hd_return_classic_from_direct() -> void:
    match_generation += 1
    busy = false
    ZenChronicles.set_campaign_board_active(false)
    if get_tree() != null: get_tree().change_scene_to_file("res://Main.tscn")

func return_home() -> void:
    if campaign_practice_active and hd_direct_realm:
        _hd_confirm_free_switch(_hd_return_classic_from_direct)
        return
    if campaign_practice_active:
        _campaign_practice_back()
        return
    if ember_active:
        _ember_back_to_reader()
        return
    if shadow_active:
        _shadow_back_to_reader()
        return
    if abyss_active:
        _abyss_back_to_reader()
        return
    if realm_story_active:
        _realm_story_leave()
        return
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
    if realm_story_active: return int(RealmStory.chapter(realm_story_stage))
    return int(Realms.state(data).selected)

func _realm_dialog(title: String, height: int = 660) -> Dictionary:
    # Draw custom premium overlay directly within the game, not Godot's gray Window.
    if is_instance_valid(active_realm_dialog): active_realm_dialog.queue_free()
    if is_instance_valid(hd_gameplay_margin): hd_gameplay_margin.show()
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
    return {"dialog":root,"box":content,"scroller":scroll,"back_button":back,"frame":frame}

func _open_realm_dialog(items: Dictionary) -> void:
    # An in-scene overlay is immediately visible, already sized to the viewport.
    var dialog: Control = items.dialog
    dialog.visible = true

func _realm_unlocked_hint(realm: int) -> String:
    return Realms.missing_reason(data,realm,lang())

func show_realms() -> void:
    if ember_active or shadow_active or abyss_active:
        if result!=0: _reopen_finished_result()
        elif ember_active: _ember_menu()
        elif shadow_active: _shadow_menu()
        else: _abyss_menu()
        return
    if realm_story_active:
        _realm_story_menu()
        return
    Realms.ensure(data)
    var ui_parts: Dictionary = _realm_dialog("Zen Ascend · " + L("realms"))
    var body: VBoxContainer = ui_parts.box
    action(body,"Zen Chronicles",_open_campaign_library_from_realms,true).name = "Campaign2ChroniclesEntry"
    # The story catalogue has five Realms. The legacy four-slot bonus
    # challenges stay separate and never determine story access.
    var campaign_progress: Dictionary = Realm2.load_progress()
    for chapter in range(5):
        _add_story_realm_card(body,chapter,campaign_progress)
    # Shattered Moon is a post-Satori story chapter, not a fifth ordinary 8-task
    # Zen Ascend realm. Show a discoverable route without changing the old gates.
    if Moon.unlocked():
        var moon_allowed: bool = Moon.unlocked() or Moon.qa_mode()
        var moon_progress: Dictionary = Moon.load_progress()
        var moon_bosses: int = 0
        for flag in moon_progress.get("defeated",[]):
            if bool(flag): moon_bosses += 1
        var moon_card := PanelContainer.new()
        moon_card.name = "ShatteredMoonStoryRealmCard"
        moon_card.add_theme_stylebox_override("panel",style(Color("#222b39"),18))
        body.add_child(moon_card)
        var moon_column := VBoxContainer.new()
        moon_column.add_theme_constant_override("separation",6)
        moon_card.add_child(moon_column)
        text(moon_column,"🌙 Shattered Moon · The Last Crossing" + ("" if moon_allowed else "  🔒"),19,Color("f7dfaa"))
        text(moon_column,_campaign_phrase("Zen Chronicles · Story-Realm","Zen Chronicles · Story realm","Zen Chronicles · Reino da história"),14,Color("d5ba85"))
        var moon_thumb := TextureRect.new()
        if ResourceLoader.exists(Moon.REALM_ART):
            _hd_queue_preview(moon_thumb,Moon.REALM_ART)
        moon_thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        moon_thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        moon_thumb.custom_minimum_size.y = 112
        moon_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        moon_column.add_child(moon_thumb)
        text(moon_column,_campaign_phrase("Bosse: %d/3 · 30 Seiten","Bosses: %d/3 · 30 pages","Chefes: %d/3 · 30 páginas") % moon_bosses,14)
        if not moon_allowed:
            text(moon_column,_campaign_phrase("Freischaltung: Satori-Geschichte abschließen","Unlock: Finish the Satori story","Desbloquear: Concluir a história de Satori"),13,Color("d5ba85"))
        var moon_entry: Button = action(moon_column,
            _campaign_phrase("▶ Story-Realm betreten","▶ Enter Story Realm","▶ Entrar no reino da história") if moon_allowed else _campaign_phrase("🔒 Freischaltung ansehen","🔒 View unlock requirements","🔒 Ver requisitos"),
            _open_shattered_from_realms,true)
        moon_entry.name = "ShatteredMoonStoryRealmButton"
        _hd_world_card(moon_card,moon_column,moon_thumb)
    if SkyGarden.unlocked():
        var sky_card := PanelContainer.new()
        sky_card.name = "SkyGardenEpilogueRealmCard"
        sky_card.add_theme_stylebox_override("panel",style(Color("#243a31"),18))
        body.add_child(sky_card)
        var sky_column := VBoxContainer.new()
        sky_card.add_child(sky_column)
        text(sky_column,"🌸 Sky Garden · The Return to Peace",19,Color("f7dfaa"))
        var sky_thumb := TextureRect.new()
        if ResourceLoader.exists(SkyGarden.REALM_ART): _hd_queue_preview(sky_thumb,SkyGarden.REALM_ART)
        sky_thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        sky_thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        sky_thumb.custom_minimum_size.y = 112
        sky_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
        sky_column.add_child(sky_thumb)
        text(sky_column,_campaign_phrase("3×3-Epilog","3×3 epilogue","Epílogo 3×3"),14)
        action(sky_column,_campaign_phrase("Geschichte betreten","Enter Story World","Entrar na história"),_open_sky_from_realms,true)
        _hd_world_card(sky_card,sky_column,sky_thumb)
    text(body,L("bot_only"),13,Color("d5ba85"))
    _hd_menu_dialog(ui_parts, false)
    var lotus := TextureRect.new()
    lotus.name = "HDDecorativeLotus"
    lotus.texture = preload("res://ui/tower_lotus.svg")
    lotus.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    lotus.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    lotus.custom_minimum_size.y = 30
    lotus.mouse_filter = Control.MOUSE_FILTER_IGNORE
    body.add_child(lotus)
    body.move_child(lotus,0)
    _open_realm_dialog(ui_parts)

func _open_sky_from_realms() -> void:
    if not SkyGarden.unlocked(): return
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    ZenChronicles.open_sky_garden_preview()

func _hd_world_card(card: PanelContainer, info: VBoxContainer, thumb: TextureRect) -> void:
    var skin := style(Color("18382c",0.92),18)
    skin.shadow_size = 0
    skin.set_border_width_all(1)
    skin.border_color = Color("d8bb7e",0.65)
    skin.set_content_margin_all(10.0)
    card.add_theme_stylebox_override("panel",skin)
    var layout := HBoxContainer.new()
    layout.name = "HDRealmWorldRow"
    layout.add_theme_constant_override("separation",8)
    # Keep all existing action nodes and callbacks intact.
    info.remove_child(thumb)
    card.remove_child(info)
    card.add_child(layout)
    thumb.custom_minimum_size = Vector2(90,104)
    thumb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    thumb.size_flags_vertical = Control.SIZE_EXPAND_FILL
    thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    thumb.name = "HDRealmWorldThumbnail"
    layout.add_child(thumb)
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.add_theme_constant_override("separation",5)
    layout.add_child(info)
    for item in info.get_children():
        if item is Label:
            var label: Label = item
            label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
            label.add_theme_font_size_override("font_size",16 if label == info.get_child(0) else 13)
        elif item is Button:
            var button: Button = item
            # All Realm cards use the same quiet green as Classic Worlds.
            _hd_beta_boss_button(button,false)
            button.custom_minimum_size.y = 48
            button.set_meta("HDRealmWorldButton",true)
            button.add_theme_font_size_override("font_size",14)
            button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            button.add_theme_stylebox_override("focus",_hd_gold_focus())

func _add_story_realm_card(body: VBoxContainer, chapter: int, campaign_progress: Dictionary) -> void:
    var legacy_index: int = [0,-1,1,2,3][chapter]
    var allowed: bool = Realm2.unlocked(chapter)
    var card := PanelContainer.new()
    card.name = "Campaign2AbyssRealmCard" if chapter==1 else "StoryRealmCard%d" % chapter
    card.add_theme_stylebox_override("panel",style(Color("252034") if chapter==1 else _realm_tone(legacy_index),18))
    card.mouse_filter = Control.MOUSE_FILTER_PASS
    body.add_child(card)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation",5)
    card.add_child(column)
    text(column,Realm2.REALM_NAMES[chapter] + ("" if allowed else "  🔒"),20,Color("f7dfaa"))
    var thumb := TextureRect.new()
    _hd_queue_preview(thumb,_hd_realm_scenery(chapter))
    thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    thumb.custom_minimum_size = Vector2(0,112)
    thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
    column.add_child(thumb)
    var bosses: int = Realm2.bosses_won(chapter)
    var tasks: int = Realm2.completed_count(campaign_progress,chapter)
    text(column,_campaign_phrase("Bosse: %d/3 · Challenges: %d/3","Bosses: %d/3 · Challenges: %d/3","Chefes: %d/3 · Desafios: %d/3") % [bosses,tasks],15)
    if allowed:
        action(column,_campaign_phrase("Realm betreten","Enter Realm","Entrar no reino"),_hd_enter_realm.bind(chapter),true).name = "EnterGameplayRealm%d" % chapter
        action(column,_campaign_phrase("Realm-Challenges","Realm Challenges","Desafios do reino")+" · %d/3" % tasks,_open_campaign_trials_from_realms.bind(chapter))
        if legacy_index>=0:
            action(column,_campaign_phrase("Bonus-Challenges","Bonus Challenges","Desafios extra")+" · %d/8" % Realms.count(data,legacy_index),_show_bonus_realm_challenges.bind(legacy_index))
    else:
        action(column,_campaign_phrase("🔒 Freischaltung ansehen","🔒 View unlock requirements","🔒 Ver requisitos"),_show_story_realm_requirements.bind(chapter))
    _hd_world_card(card,column,thumb)

func _show_story_realm_requirements(chapter: int) -> void:
    var parts: Dictionary = _realm_dialog(Realm2.REALM_NAMES[chapter],620)
    var body: VBoxContainer = parts.box
    if chapter==0:
        text(body,_campaign_phrase("Schließe Act IV ab.","Complete Act IV.","Conclui o Ato IV."),17)
    else:
        var previous: int = chapter-1
        text(body,_campaign_phrase("Schließe %s ab.","Complete %s.","Conclui %s.") % Realm2.REALM_NAMES[previous],18,Color("f6daa0"))
        var bosses: int = Realm2.bosses_won(previous)
        var tasks: int = Realm2.completed_count(Realm2.load_progress(),previous)
        text(body,_campaign_phrase("Bosse: %d/3","Bosses: %d/3","Chefes: %d/3") % bosses,16)
        _progress_meter(body,bosses,3)
        text(body,_campaign_phrase("Challenges: %d/3","Challenges: %d/3","Desafios: %d/3") % tasks,16)
        _progress_meter(body,tasks,3)
        text(body,_campaign_phrase("Kapitelende bestätigen.","Finish the chapter after the final boss.","Conclui o capítulo após o chefe final."),15)
    action(body,L("realms"),show_realms,true)
    _hd_menu_dialog(parts, false)
    _open_realm_dialog(parts)

func _show_bonus_realm_challenges(realm: int) -> void:
    var parts: Dictionary = _realm_dialog(_campaign_phrase("Optionale Bonus-Challenges","Optional Bonus Challenges","Desafios extra opcionais"))
    _challenge_items(parts.box,realm)
    if Realms.unlocked(data,realm):
        action(parts.box,_campaign_phrase("Bonus-Realm betreten","Enter Bonus Realm","Entrar no reino extra"),_choose_realm_from_dialog.bind(realm,parts.dialog),true)
    _hd_menu_dialog(parts, false)
    _open_realm_dialog(parts)

func _preview_mirror_shatter_qa() -> void:
    if not RealmStory.qa_mode(): return
    if is_instance_valid(active_realm_dialog):
        _close_realm_dialog(active_realm_dialog)
    var preview: ZenRealmTravelCeremony = RealmPortal.new()
    add_child(preview)
    preview.finished.connect(func():
        if is_inside_tree(): call_deferred("show_realms")
    )
    preview.present(Realms.REALM_ART[0],Realms.REALM_ART[1],
        Realms.realm_name(1,lang()),true,bool(data.settings.get("sound",true)),
        [world_music],lang())

func _add_abyss_realm_card(body: VBoxContainer) -> void:
    var card: PanelContainer = PanelContainer.new()
    card.name = "Campaign2AbyssRealmCard"
    card.add_theme_stylebox_override("panel",style(Color("252034"),18))
    body.add_child(card)
    var column: VBoxContainer = VBoxContainer.new()
    card.add_child(column)
    var allowed: bool = Realm2.unlocked(1)
    text(column,"Abyss of Memories" + ("" if allowed else "  🔒"),20,Color("f7dfaa"))
    var thumb: TextureRect = TextureRect.new()
    thumb.texture = Abyss.battle_backdrop()
    thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    thumb.custom_minimum_size.y = 112
    thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
    column.add_child(thumb)
    text(column,"Challenges · %d/3" % Realm2.completed_count(Realm2.load_progress(),1),15)
    action(column,_campaign_phrase("Realm betreten","Enter Realm","Entrar no reino") if allowed else _campaign_phrase("Freischaltung ansehen","View unlock requirements","Ver requisitos"),_open_campaign_trials_from_realms.bind(1),allowed)

func _open_campaign_trials_from_realms(chapter: int) -> void:
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    ZenChronicles.open_campaign_challenges(chapter)

func _open_campaign_library_from_realms() -> void:
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    ZenChronicles.open_library()

func _open_shattered_from_realms() -> void:
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    ZenChronicles.open_shattered_moon_preview()

func _open_realm_chronicles_from_realms() -> void:
    # The button is inside a modal; close it before opening the book. Returning
    # from the book goes back to the four Realm cards, not the main library.
    if realm_story_active: return
    if is_instance_valid(active_realm_dialog):
        _close_realm_dialog(active_realm_dialog)
    ZenChronicles.open_realm_story_overview(true)

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
        if Realms.count(data,previous) < 8 or Realms.completed_story_bosses(previous) < 3:
            source_realm = previous
            break
    if source_realm >= 0:
        var done: int = Realms.count(data,source_realm)
        text(body,Realms.realm_name(source_realm,lang()) + " · %d/8 " % done + L("challenges"),16)
        _progress_meter(body,done,8)
        var defeated: int = Realms.completed_story_bosses(source_realm)
        text(body,("Story-Bosse" if lang()=="de" else "Chefes da história" if lang()=="pt" else "Story bosses") + ": %d/3" % defeated,16)
        _progress_meter(body,defeated,3)
    action(body,L("realms"),show_realms,true)
    _hd_menu_dialog(parts, false)
    _open_realm_dialog(parts)

func _choose_realm_from_dialog(number: int, dialog: Control) -> void:
    if select_realm(number): dialog.queue_free()

func select_realm(number: int) -> bool:
    if realm_story_active: return false
    if move_count() > 0 and result == 0: return false
    var from_realm: int = realm_index()
    if not Realms.select(data,number): return false
    if campaign_practice_active:
        campaign_practice_active = false
        hd_direct_realm = false
        campaign_awards = []
        match_generation += 1
        busy = false
        cells.fill(0)
        turn = 1
        result = 0
        recorded = false
        cube.clear_abyss_skin()
        cube.set_skin(int(data.economy.get("equipped",0)))
        ZenChronicles.set_campaign_board_active(false)
    data.ascend.erase("hd_selected_chapter")
    data.ascend["hd_direct_realm"] = false
    _hd_remember_chapter([0,2,3,4][number],false)
    match_realm = number
    # Prevent stale Medium UI/AI after switching from Shadow to Ember.
    bot_level = Realms.fixed_bot_level(number)
    if realm_backdrop != null:
        realm_backdrop.texture = load(Realms.REALM_ART[number])
        _refresh_arena_presentation()
    SaveManager.save_data(data)
    draw()
    if from_realm != number:
        call_deferred("_show_manual_realm_journey",from_realm,number,false)
    else:
        sync_realm_music()
    return true

func _show_manual_realm_journey(from_realm: int, to_realm: int, breakthrough: bool = false) -> void:
    if not is_inside_tree(): return
    var journey: ZenRealmTravelCeremony = RealmPortal.new()
    add_child(journey)
    journey.finished.connect(func():
        if is_inside_tree(): sync_realm_music()
    )
    journey.present(Realms.REALM_ART[from_realm],Realms.REALM_ART[to_realm],
        Realms.realm_name(to_realm,lang()),breakthrough,
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
        card.mouse_filter = Control.MOUSE_FILTER_STOP
        list.add_child(card)
        var inside: VBoxContainer = VBoxContainer.new()
        inside.add_theme_constant_override("separation",8)
        inside.mouse_filter = Control.MOUSE_FILTER_STOP
        card.add_child(inside)
        text(inside,("✓  " if earned else "◇  ") + str(task.title),18,Color("f3ddb2"))
        text(inside,Realms.task_description(task,lang()),14,Color("d7d5c9"))
        text(inside,(L("earned") if earned else L("reward")) + "  ·  🍃 %d" % int(task.leaves),14,Color("bce3af"))
    text(list,L("bot_only"),13,Color("cdbd9d"))

func show_challenges() -> void:
    if ember_active or shadow_active or abyss_active or realm_story_active:
        if result!=0: _reopen_finished_result()
        elif ember_active: _ember_menu()
        elif shadow_active: _shadow_menu()
        elif abyss_active: _abyss_menu()
        else: _realm_story_menu()
        return
    if campaign_practice_active and move_count()>0 and result==0:
        _campaign_practice_menu()
        return
    if campaign_practice_active or realm_index()==0:
        _open_campaign_trials_from_realms(practice_chapter if campaign_practice_active else 0)
        return
    # Original archive Realms retain their achievement interface until migrated.
    var parts: Dictionary = _realm_dialog("Zen Ascend · " + L("challenges"))
    var body: VBoxContainer = parts.box
    var tasks_box: VBoxContainer = VBoxContainer.new()
    tasks_box.add_theme_constant_override("separation",14)
    body.add_child(tasks_box)
    _challenge_items(tasks_box,realm_index())
    _hd_menu_dialog(parts, false)
    _open_realm_dialog(parts)

# Only small menu previews are cached, never full-resolution boss portraits.
var _hd_preview_cache: Dictionary = {}
func _hd_achievement_art(realm: int) -> String:
    if realm == Achievements.ABYSS_REALM and ResourceLoader.exists(Abyss.gameplay_art()):
        return Abyss.gameplay_art()
    return Achievements.realm_art(realm)

func _hd_queue_preview(target: TextureRect, source: String) -> void:
    if source.is_empty(): return
    var path: String = "res://assets/hd_menu_previews/" + source.trim_prefix("res://").replace("/","_").get_basename() + ".webp"
    if not ResourceLoader.exists(path):
        path = source
    if _hd_preview_cache.has(path):
        target.texture = _hd_preview_cache[path] as Texture2D
        return
    call_deferred("_hd_load_preview",weakref(target),path)

func _hd_load_preview(target_ref: WeakRef, path: String) -> void:
    if not ResourceLoader.exists(path): return
    # Wait until the preview is near the visible part of its scroll area.
    while true:
        var target := target_ref.get_ref() as TextureRect
        if not is_instance_valid(target) or not target.is_inside_tree(): return
        var ancestor: Node = target.get_parent()
        while ancestor != null and not ancestor is ScrollContainer:
            ancestor = ancestor.get_parent()
        if ancestor == null or (ancestor as ScrollContainer).get_global_rect().grow(180.0).intersects(target.get_global_rect()): break
        await get_tree().process_frame
    if _hd_preview_cache.has(path):
        var cached_target := target_ref.get_ref() as TextureRect
        if is_instance_valid(cached_target): cached_target.texture = _hd_preview_cache[path] as Texture2D
        return
    var status: int = ResourceLoader.load_threaded_get_status(path)
    if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
        if ResourceLoader.load_threaded_request(path,"Texture2D") != OK: return
    while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
        await get_tree().process_frame
    if _hd_preview_cache.has(path):
        var waiting_target := target_ref.get_ref() as TextureRect
        if is_instance_valid(waiting_target): waiting_target.texture = _hd_preview_cache[path] as Texture2D
        return
    if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_LOADED: return
    var image: Texture2D = ResourceLoader.load_threaded_get(path) as Texture2D
    if image == null: return
    if path.begins_with("res://assets/hd_menu_previews/"):
        _hd_preview_cache[path] = image
    var final_target := target_ref.get_ref() as TextureRect
    if is_instance_valid(final_target): final_target.texture = image

func show_realm_titles() -> void:
    # Achievements are independent of the Realm Challenges. Only one main
    # title can be earned per Realm, through full Realm mastery (8/8).
    var parts: Dictionary = _realm_dialog("Zen Ascend · " + _achievements_label())
    var body: VBoxContainer = parts.box
    var earned_by_id: Dictionary = {}
    var total: int = 0
    var abyss_stats: Dictionary = Realm2.load_progress().abyss_stats
    for secret in Achievements.SECRETS:
        var key: String = str(secret.id)
        var earned: bool = Achievements.earned(data,key,abyss_stats)
        earned_by_id[key] = earned
        if earned: total += 1
    text(body,"Secret Achievements   ·   %d / %d" % [total,Achievements.SECRETS.size()],18,Color("f3dca4"))
    for realm in [0,Achievements.ABYSS_REALM,1,2,3]:
        var group: PanelContainer = PanelContainer.new()
        group.add_theme_stylebox_override("panel",style(Color("252034") if realm==Achievements.ABYSS_REALM else _realm_tone(realm),18))
        group.mouse_filter = Control.MOUSE_FILTER_PASS
        body.add_child(group)
        var inside: VBoxContainer = VBoxContainer.new()
        inside.add_theme_constant_override("separation",9)
        group.add_child(inside)
        text(inside,Achievements.realm_name(realm,lang()),21,Color("f7dda5"))
        var picture: TextureRect = TextureRect.new()
        _hd_queue_preview(picture,_hd_achievement_art(realm))
        picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        picture.custom_minimum_size.y = 160
        picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
        inside.add_child(picture)
        var master: String = Achievements.title_name(realm)
        var title_earned: bool = Achievements.main_title(data,realm)!="—"
        var title_condition: String = "Complete the Abyss chapter and its three Realm Challenges." if realm==Achievements.ABYSS_REALM else "Complete all 8 Realm Challenges."
        text(inside,("✦ " if title_earned else "🔒 ") + master + ("  ·  Unlocked" if title_earned else "  ·  Locked"),18,Color("d1eabd") if title_earned else Color("d9c8ac"))
        action(inside,"View Realm Title",_show_achievement_details.bind(realm,{"id":"main","name":master,"condition":title_condition,"quote":Achievements.main_quote(realm)},title_earned),false)
        for secret in Achievements.SECRETS:
            if int(secret.realm) != realm: continue
            var unlocked: bool = bool(earned_by_id.get(str(secret.id),false))
            var display: String = ("✦  " + str(secret.name)) if unlocked else "◇  ???  ·  Secret Achievement"
            action(inside,display,_show_achievement_details.bind(realm,secret,unlocked),unlocked)
    _hd_menu_dialog(parts, false)
    _open_realm_dialog(parts)

func _show_achievement_details(realm: int, secret: Dictionary, unlocked: bool) -> void:
    var is_main_title: bool = str(secret.id) == "main"
    var revealed: bool = unlocked or is_main_title
    var title_text: String = str(secret.name) if revealed else "???"
    var parts: Dictionary = _realm_dialog(title_text,610)
    var body: VBoxContainer = parts.box
    var picture: TextureRect = TextureRect.new()
    _hd_queue_preview(picture,_hd_achievement_art(realm))
    picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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
    _hd_menu_dialog(parts, false)
    _open_realm_dialog(parts)


func _hd_menu_dialog(parts: Dictionary, compact: bool = false) -> void:
    var root: Control = parts.dialog
    var frame: PanelContainer = parts.frame
    var stack: VBoxContainer = frame.get_child(0) as VBoxContainer
    var body: VBoxContainer = parts.box
    var tint: ColorRect = root.get_child(0) as ColorRect
    tint.color = Color("10271f", 0.80)
    if not compact:
        if is_instance_valid(hd_gameplay_margin): hd_gameplay_margin.hide()
        frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shell := style(Color("10271f", 0.90) if compact else Color(0, 0, 0, 0), 18 if compact else 0)
    shell.set_border_width_all(1 if compact else 0)
    shell.set_content_margin_all(12.0 if compact else 24.0)
    frame.add_theme_stylebox_override("panel", shell)
    var heading: HBoxContainer = stack.get_child(0) as HBoxContainer
    var title: Label = heading.get_child(0) as Label
    title.add_theme_font_override("font", ZenType.heading())
    title.add_theme_font_size_override("font_size", 23 if compact else 29)
    title.add_theme_color_override("font_color", Color("fff2d5"))
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    body.add_theme_constant_override("separation", 10)
    _hd_menu_buttons(stack)

func _hd_menu_buttons(node: Node) -> void:
    if node is Button and not (node is OptionButton or node is CheckButton or node is CheckBox) and not node.has_meta("HDRealmWorldButton"):
        var b: Button = node
        var old_style := b.get_theme_stylebox("normal") as StyleBoxFlat
        var featured: bool = old_style != null and old_style.bg_color.is_equal_approx(Color("4e674f"))
        for state in ["normal", "hover", "pressed", "disabled"]:
            var bg: Color = Color("d8bb7e") if featured else Color("16382b", 0.90)
            if state == "hover": bg = Color("dfc58b") if featured else Color("28523d")
            elif state == "pressed": bg = Color("c8aa71") if featured else Color("102a25")
            elif state == "disabled": bg = Color("35453c", 0.90)
            var st := style(bg, 16)
            st.set_border_width_all(1)
            st.border_color = Color("d8bb7e", 0.70)
            b.add_theme_stylebox_override(state, st)
        for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
            b.add_theme_color_override(key, Color("10271f") if featured else Color("fff0cf"))
        b.add_theme_color_override("font_disabled_color", Color("b5b8a7"))
    if node is BaseButton or node is LineEdit:
        node.add_theme_stylebox_override("focus",_hd_gold_focus())
    for child in node.get_children():
        _hd_menu_buttons(child)

func _hd_realm_layout(parts: Dictionary, headline: String, subtitle: String, show_cube: bool) -> void:
    var root: Control = parts.dialog
    var frame: PanelContainer = parts.frame
    var stack: VBoxContainer = frame.get_child(0) as VBoxContainer
    var body: VBoxContainer = parts.box
    if is_instance_valid(hd_gameplay_margin): hd_gameplay_margin.hide()
    (root.get_child(0) as ColorRect).color = Color("10271f", 0.80)
    var clear_style: StyleBoxFlat = style(Color(0, 0, 0, 0), 0)
    clear_style.set_border_width_all(0)
    clear_style.set_content_margin_all(24.0)
    frame.add_theme_stylebox_override("panel", clear_style)
    frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    stack.add_theme_constant_override("separation", 10)
    stack.get_child(0).hide()
    stack.get_child(1).hide()
    var footer: Button = parts.back_button
    if is_instance_valid(footer): footer.hide()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.alignment = BoxContainer.ALIGNMENT_CENTER
    body.add_theme_constant_override("separation", 10)
    text(body, "ZenCube 3D", 14, Color("e6c99d"))
    var title: Label = text(body, headline, 32, Color("fff2d5"))
    title.add_theme_font_override("font", ZenType.heading())
    text(body, subtitle, 17, Color("d8bb7e"))
    if show_cube:
        var hero := TextureRect.new()
        hero.name = "HDLiveRealmResultCube"
        hero.texture = vp.get_texture()
        hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        hero.custom_minimum_size.y = clampf(get_viewport().get_visible_rect().size.y * 0.29, 180.0, 285.0)
        hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
        body.add_child(hero)

func _hd_realm_finish(parts: Dictionary, quote: String = "") -> void:
    var body: VBoxContainer = parts.box
    var stack: VBoxContainer = (parts.frame as PanelContainer).get_child(0) as VBoxContainer
    var actions: Array[Button] = []
    for parent in [body, stack]:
        for child in parent.get_children():
            if child is Button and child.visible:
                actions.append(child)
    var primary: Button = null
    var inspect: Button = null
    for b in actions:
        if b.text == _review_board_label(): inspect = b
        elif primary == null: primary = b
    if primary != null and inspect != null and primary.get_parent() == inspect.get_parent():
        primary.get_parent().move_child(inspect, primary.get_index() + (0 if inspect.get_index() < primary.get_index() else 1))
    for b in actions:
        var featured: bool = b == primary
        b.custom_minimum_size.y = 62 if featured else 48
        b.add_theme_font_size_override("font_size", 19 if featured else 16)
        for state in ["normal", "hover", "pressed"]:
            var bg: Color = (Color("dfc58b") if state == "hover" else Color("d8bb7e")) if featured else (Color("18382c") if state == "hover" else Color("102a25", 0.55))
            var st: StyleBoxFlat = style(bg, 18)
            st.set_border_width_all(1)
            st.border_color = Color("cfb37e", 0.7)
            b.add_theme_stylebox_override(state, st)
        for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
            b.add_theme_color_override(key, Color("102a25") if featured else Color("fff0cf"))
    if not quote.is_empty(): text(body, quote, 13, Color("e6d4ae"))

func _hd_realm_outcome(won: bool) -> String:
    return _campaign_phrase("Unentschieden", "Draw", "Empate") if result == 3 else (_campaign_phrase("Sieg", "Victory", "Vitória") if won else _campaign_phrase("Niederlage", "Defeat", "Derrota"))

func show_match_result() -> void:
    if realm_story_active:
        _realm_story_result()
        return
    if not is_inside_tree(): return
    var human_won: bool = result in [1,2] and int(owners[result-1]) == 0
    var title: String = Z("Unentschieden!") if result == 3 else (Z("Gewonnen!") if human_won else zen_ascend_bot_name() + " · " + Z("hat gewonnen!"))
    if not against_bot and result in [1,2]: title = pname(int(owners[result-1])) + " " + Z("hat gewonnen!")
    var parts: Dictionary = _realm_dialog(title,410)
    var body: VBoxContainer = parts.box
    _hd_realm_layout(parts, _hd_realm_outcome(human_won or not against_bot), Realms.REALM_NAMES[clampi(match_realm,0,3)], true)
    var info: VBoxContainer = body
    if not against_bot and result != 3: text(info, title, 16, Color("e6d4ae"))
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
    action(body,_review_board_label(),_review_finished_board.bind(parts.dialog),true)
    action(body,Z("Neue Partie"),_replay_after_result.bind(parts.dialog))
    if against_bot and match_realm==0:
        if Realm2.final_boss_waiting(0):
            action(body,_campaign_phrase("⚔ Finalen Boss betreten","⚔ Enter Final Boss","⚔ Enfrentar o chefe final"),_enter_campaign_final_guardian.bind(0),true)
        elif Realm2.completed_count(Realm2.load_progress(),0)==3 and Realm2.bosses_won(0)<3:
            action(body,_campaign_phrase("Geschichte fortsetzen","Continue Story","Continuar história"),_open_campaign_story_from_match.bind(0),true)
        action(body,_campaign_phrase("‹ Zu den Realm-Challenges","‹ Realm Challenges","‹ Desafios do reino"),_open_campaign_trials_from_realms.bind(0))
    action(body,Z("Hauptmenü"),return_home)
    _hd_realm_finish(parts, realm_quote())
    _open_realm_dialog(parts)

func _replay_after_result(dialog: Control) -> void:
    _close_realm_dialog(dialog)
    start_game(against_bot,bot_level)

func show_realm_rewards(_awards: Dictionary) -> void:
    # Compatibility: rewards are part of the single themed match result now.
    show_match_result()


# Compact story dialogue: keep the existing beautiful theme and scroll
# behavior, but do not reserve 80% of a tall Android screen for a short intro.
# The dedicated story actions already offer navigation; a second Back footer
# creates an unnecessary third exit next to X and "Return to main game".
func _campaign_phrase(de: String, en: String, pt: String) -> String:
    return de if lang()=="de" else (pt if lang()=="pt" else en)

func _campaign_result_compact(parts: Dictionary) -> void:
    _realm_story_compact(parts)
    var frame: PanelContainer = parts.frame
    frame.anchor_top = 0.25
    frame.anchor_bottom = 0.75

func _realm_story_compact(parts: Dictionary) -> void:
    var frame: PanelContainer = parts.frame
    frame.anchor_left = 0.055
    frame.anchor_right = 0.945
    frame.anchor_top = 0.155
    frame.anchor_bottom = 0.845
    frame.offset_top = 0
    frame.offset_bottom = 0
    var footer: Button = parts.back_button
    # Remove redundant Back from the layout, rather than merely hiding it.
    var footer_parent: VBoxContainer = footer.get_parent() as VBoxContainer
    footer_parent.remove_child(footer)
    footer.queue_free()
    footer_parent.add_theme_constant_override("separation",8)
    (parts.box as VBoxContainer).add_theme_constant_override("separation",9)

# Act I-IV style cinematic boss portraits; actual battle rules and existing artwork stay intact.
# Beta boss layout: the portrait takes only the space left by text and actions.
func _hd_beta_boss_fit(parts: Dictionary, intro: bool) -> void:
    var frame: PanelContainer = parts.frame
    var stack: VBoxContainer = frame.get_child(0) as VBoxContainer
    var body: VBoxContainer = parts.box
    var scroller: ScrollContainer = parts.scroller
    if intro:
        _hd_menu_dialog(parts, false)
    var shell: StyleBoxFlat = style(Color(0,0,0,0),0)
    shell.set_border_width_all(0)
    shell.set_content_margin_all(16.0)
    frame.add_theme_stylebox_override("panel",shell)
    frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    stack.add_theme_constant_override("separation",6)
    body.add_theme_constant_override("separation",5)
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.alignment = BoxContainer.ALIGNMENT_CENTER
    # Keep the existing ScrollContainer for focus/touch compatibility, but do
    # not allow scrolling on ordinary phone viewports. Short windows retain
    # an accessibility fallback rather than clipping an action.
    scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if get_viewport().get_visible_rect().size.y >= 620.0 else ScrollContainer.SCROLL_MODE_AUTO
    for item in body.get_children():
        if item is TextureRect:
            var portrait: TextureRect = item
            portrait.custom_minimum_size = Vector2(0,0 if get_viewport().get_visible_rect().size.y >= 620.0 else 160.0)
            portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
            portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        elif item is PanelContainer:
            var art: PanelContainer = item
            var inner: Control = art.find_child("CinematicVictoryFrame",true,false) as Control
            if inner != null:
                inner.custom_minimum_size.y = 0
                art.custom_minimum_size.y = 0
                art.size_flags_vertical = Control.SIZE_EXPAND_FILL
        elif item is Label:
            var line: Label = item
            var font_size: int = line.get_theme_font_size("font_size")
            if font_size < 25:
                line.add_theme_font_size_override("font_size",clampi(font_size,12,16))
        elif item is Button:
            _hd_beta_boss_button(item as Button,false)
    for item in stack.get_children():
        if item is Button and item.visible:
            var b: Button = item
            var featured: bool = b.name == "RealmBossStartAction"
            if not intro:
                var normal := b.get_theme_stylebox("normal") as StyleBoxFlat
                featured = normal != null and normal.bg_color.is_equal_approx(Color("d8bb7e"))
            _hd_beta_boss_button(b,featured)

func _hd_beta_boss_button(b: Button, featured: bool) -> void:
    b.custom_minimum_size.y = 50 if featured else 43
    b.add_theme_font_size_override("font_size",17 if featured else 15)
    for state in ["normal","hover","pressed"]:
        var bg: Color = Color("d8bb7e") if featured else Color("16382b",0.85)
        if state == "hover": bg = Color("e5c98e") if featured else Color("28523d")
        elif state == "pressed": bg = Color("c8aa71") if featured else Color("102a25")
        var skin: StyleBoxFlat = style(bg,15)
        skin.set_content_margin_all(6.0)
        skin.set_border_width_all(1)
        b.add_theme_stylebox_override(state,skin)
    for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
        b.add_theme_color_override(key,Color("10271f") if featured else Color("fff2d5"))

func _realm_boss_intro_layout(parts: Dictionary) -> void:
    _realm_story_compact(parts)
    var frame: PanelContainer = parts.frame
    frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _realm_boss_portrait_height() -> float:
    return clampf(get_viewport().get_visible_rect().size.y * 0.46,180.0,520.0)

func _realm_boss_result_height() -> float:
    return _realm_boss_portrait_height()

func _realm_boss_primary_action(parts: Dictionary, caption: String, callback: Callable) -> void:
    # Play remains visible beneath the scrollable, full-height boss artwork.
    var frame: PanelContainer = parts.frame
    var stack: VBoxContainer = frame.get_child(0) as VBoxContainer
    var launch: Button = action(stack,caption,callback,true)
    launch.name = "RealmBossStartAction"
    launch.custom_minimum_size.y = 62

# Cinematic Realm results: full-height illustration, actions pinned below scroll.
func _realm_boss_result_layout(parts: Dictionary) -> void:
    _realm_boss_intro_layout(parts)
    (parts.box as VBoxContainer).add_theme_constant_override("separation",8)

func _realm_boss_result_action(parts: Dictionary, caption: String, callback: Callable, primary: bool = false) -> void:
    var frame: PanelContainer = parts.frame
    var stack: VBoxContainer = frame.get_child(0) as VBoxContainer
    var button_node: Button = action(stack,caption,callback,primary)
    button_node.name = "RealmBossResultAction_%d" % stack.get_child_count()
    button_node.custom_minimum_size.y = 50

# -------- Realm Chronicles: isolated 4x4 playable story --------
func start_realm_story() -> void:
    if not Mode.unlocked(data):
        return_home()
        return
    realm_story_progress = RealmStory.load_progress()
    realm_story_stage = int(realm_story_progress.stage)
    realm_story_active = true
    ZenChronicles.set_campaign_board_active(true)
    realm_story_generation += 1
    realm_story_last_human = -1
    if realm_story_stage >= RealmStory.LAST_STAGE:
        _realm_story_completed()
        return
    if not RealmStory.can_enter(data,realm_story_stage):
        _realm_story_locked()
        return
    _realm_story_set_stage(realm_story_stage)
    _realm_story_present_intro()

func _realm_story_set_stage(stage: int) -> void:
    match_generation += 1
    realm_story_stage = clampi(stage,0,RealmStory.LAST_STAGE-1)
    match_realm = RealmStory.chapter(realm_story_stage)
    bot_level = Realms.fixed_bot_level(match_realm)
    realm_story_generation += 1
    realm_story_last_human = -1
    against_bot = true
    owners = [0,1]
    recorded = false
    busy = false
    var old: Dictionary = realm_story_progress.get("game",{})
    if not RealmStory.valid_game(old): old = {}
    if old.is_empty():
        cells.fill(0)
        # Each boss alternates its first mover based on stage order and retries.
        # Persisted attempt counters keep alternation across app restarts.
        var starts: Dictionary = realm_story_progress.get("starts",{})
        var key: String = str(realm_story_stage)
        var attempt: int = int(starts.get(key,0))
        turn = 1 if (realm_story_stage + attempt) % 2 == 0 else 2
        starts[key] = attempt+1
        realm_story_progress.starts = starts
        result = 0
    else:
        cells = old.cells.duplicate()
        turn = clampi(int(old.get("turn",1)),1,2)
        result = clampi(int(old.get("result",0)),0,3)
        recorded = result != 0
        realm_story_last_human = int(old.get("last_human",-1))
    cube.reset_view()
    cube.set_boss_skin(realm_story_stage)
    if realm_backdrop != null:
        realm_backdrop.texture = load(RealmStory.CHAPTER_ART[match_realm])
        _refresh_arena_presentation()
    draw()
    # Follow the new Realm's EXISTING song on actual chapter travel.
    # No new music and no modification to the Classic soundtrack.
    sync_realm_music()

func _realm_story_art(parent: VBoxContainer, stage: int, height: float = 214.0, zoom: bool = false) -> void:
    # Use approved cinematic boss portraits shipped in JSON + base64 WebP.
    # Optional direct WebP file takes priority if present, then the validated
    # inline texture decoder; only a broken asset falls back to an SVG.
    var art: Texture2D = null
    var file_path: String = "res://assets/realm_chronicles/boss_%s_hd.webp" % RealmStory.BOSS_IDS[stage]
    if ResourceLoader.exists(file_path):
        art = load(file_path) as Texture2D
    if art == null:
        art = RealmStory.boss_texture(stage)
    if art == null:
        art = load(RealmStory.CHAPTER_ART[RealmStory.chapter(stage)]) as Texture2D
    if art == null: return
    var picture: TextureRect = TextureRect.new()
    picture.name = "RealmChroniclesBossArt"
    picture.texture = art
    picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    # Keep the full vertical portrait and its title legible; COVERED would
    # crop the boss face and name on narrow Android screens.
    picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var image_ratio: float = float(art.get_height()) / maxf(1.0,float(art.get_width()))
    var display_width: float = get_viewport().get_visible_rect().size.x * 0.84
    picture.custom_minimum_size.y = minf(height,maxf(180.0,display_width * image_ratio))
    picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(picture)

func _realm_story_present_intro() -> void:
    if not realm_story_active: return
    if result != 0:
        _realm_story_result()
        return
    var stage: int = realm_story_stage
    var parts: Dictionary = _realm_dialog(RealmStory.text_for(lang(),"boss_%d" % stage),680)
    var body: VBoxContainer = parts.box
    _realm_boss_intro_layout(parts)
    var chapter_key: String = ["shadow","ember","celestial","satori"][RealmStory.chapter(stage)]
    text(body,RealmStory.text_for(lang(),chapter_key),17,Color("#e7cd9b"))
    if stage in [6,9]:
        text(body,RealmStory.text_for(lang(),"chapter%d_open" % (RealmStory.chapter(stage)+1)),14,Color("#b6d8ed"))
    _realm_story_art(body,stage,_realm_boss_portrait_height())
    text(body,RealmStory.text_for(lang(),"intro_%d" % stage),15)
    text(body,RealmStory.text_for(lang(),"skin")+" · "+RealmStory.text_for(lang(),"saved"),13,Color("#b8d4c2"))
    var starter_info: String = "Du beginnst (X)" if turn == 1 else "Boss beginnt (O)"
    if lang() == "en": starter_info = "You start (X)" if turn == 1 else "Boss starts (O)"
    elif lang() == "pt": starter_info = "Começas (X)" if turn == 1 else "O chefe começa (O)"
    text(body,starter_info,14,Color("#f0dfb3"))
    _realm_boss_primary_action(parts,RealmStory.text_for(lang(),"resume" if not realm_story_progress.game.is_empty() else "continue"),_realm_story_begin)
    action(body,RealmStory.text_for(lang(),"return_ascend"),_realm_story_return_to_ascend)
    _hd_beta_boss_fit(parts, true)
    _open_realm_dialog(parts)

func _realm_story_begin() -> void:
    if not realm_story_active: return
    if is_instance_valid(active_realm_dialog):
        _close_realm_dialog(active_realm_dialog)
    var seen: Dictionary = realm_story_progress.get("introduced",{})
    seen[str(realm_story_stage)] = true
    realm_story_progress.introduced = seen
    _realm_story_save()
    if result == 0 and turn == 2 and not busy:
        busy = true
        call_deferred("bot_turn")
    draw()

func _realm_story_save() -> bool:
    if not realm_story_active: return false
    realm_story_progress.stage = realm_story_stage
    # Final cutscene must not accidentally resurrect the last boss match
    # when leaving and reopening the completed Chapter 2 story.
    if realm_story_stage >= RealmStory.LAST_STAGE or (result == 0 and move_count() == 0):
        realm_story_progress.game = {}
    else:
        realm_story_progress.game = {
            "cells": cells.duplicate(),
            "turn": turn,
            "result": result,
            "owners": owners.duplicate(),
            "last_human": realm_story_last_human
        }
    var ok: bool = RealmStory.save_progress(realm_story_progress)
    if not ok: push_warning("Realm Chronicles: save failed")
    return ok

func _realm_story_result() -> void:
    if not realm_story_active or result == 0: return
    var won: bool = result == 1
    var key: String = "win_%d" % realm_story_stage if won else "loss_%d" % realm_story_stage
    var title: String = RealmStory.text_for(lang(),"win" if won else ("draw" if result == 3 else "loss"))
    var parts: Dictionary = _realm_dialog(title,590)
    var body: VBoxContainer = parts.box
    _realm_boss_result_layout(parts)
    _hd_realm_layout(parts, _hd_realm_outcome(won), title, false)
    if won:
        # A complete Kuze-with-defeated-boss illustration after EACH of 12
        # actual victories; never triggered on a loss or draw.
        var scene_art: PanelContainer = VictoryArtwork.new()
        body.add_child(scene_art)
        scene_art.call("present",realm_story_stage,lang())
        scene_art.custom_minimum_size.y = _realm_boss_result_height()
        var frame_art: Control = scene_art.find_child("CinematicVictoryFrame",true,false) as Control
        if frame_art != null: frame_art.custom_minimum_size.y = _realm_boss_result_height()
        text(body,RealmStory.text_for(lang(),"victory_story_%d" % realm_story_stage),15,Color("#e7d3ab"))
    else:
        _realm_story_art(body,realm_story_stage,_realm_boss_result_height(),true)
    text(body,RealmStory.text_for(lang(),key),16)
    _realm_boss_result_action(parts,_review_board_label(),_review_finished_board.bind(parts.dialog),true)
    if won:
        _realm_boss_result_action(parts,RealmStory.text_for(lang(),"next"),_realm_story_advance,true)
    else:
        _realm_boss_result_action(parts,RealmStory.text_for(lang(),"retry"),_realm_story_retry,true)
    _realm_boss_result_action(parts,RealmStory.text_for(lang(),"return_ascend"),_realm_story_return_to_ascend)
    _hd_realm_finish(parts)
    _hd_beta_boss_fit(parts, false)
    _open_realm_dialog(parts)

func _realm_story_retry() -> void:
    if not realm_story_active or realm_story_stage >= RealmStory.LAST_STAGE: return
    realm_story_generation += 1
    realm_story_progress.game = {}
    _realm_story_set_stage(realm_story_stage)
    _realm_story_save()
    _realm_story_present_intro()

func _realm_story_advance() -> void:
    if not realm_story_active or result != 1: return
    var prior: int = realm_story_stage
    var next_stage: int = mini(RealmStory.LAST_STAGE,prior + 1)
    var progress: Dictionary = realm_story_progress.duplicate(true)
    progress.stage = next_stage
    progress.game = {}
    if not RealmStory.save_progress(progress):
        push_warning("Realm Chronicles: failed to save completed boss")
        return
    realm_story_progress = progress
    realm_story_generation += 1
    if (prior+1) % RealmStory.CHAPTER_SIZE == 0:
        # Crucial: avoid re-saving the previous winning board under a new
        # chapter stage when the player leaves the closing cutscene.
        realm_story_stage = next_stage
        cells.fill(0)
        turn = 1
        result = 0
        recorded = false
        busy = false
        cube.clear_boss_skin()
        _realm_story_chapter_outro(RealmStory.chapter(prior))
    else:
        _realm_story_set_stage(next_stage)
        _realm_story_present_intro()

func _realm_story_chapter_outro(chapter: int) -> void:
    var is_final: bool = chapter == 3
    var title_key: String = "chapter_complete_final" if is_final else "chapter_complete"
    var parts: Dictionary = _realm_dialog(RealmStory.text_for(lang(),title_key),700)
    var body: VBoxContainer = parts.box
    _realm_story_compact(parts)
    var picture: TextureRect = TextureRect.new()
    picture.texture = load(RealmStory.CHAPTER_ART[clampi(chapter,0,3)])
    picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    picture.custom_minimum_size.y = 213
    picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    body.add_child(picture)
    var chapter_key: String = "chapter%d_end" % (chapter+1)
    text(body,RealmStory.text_for(lang(),chapter_key),16)
    if is_final:
        # Story conclusion only: does not forge the normal 4x4 Satori title.
        text(body,RealmStory.text_for(lang(),"final_title"),23,Color("#ffdc89"))
        text(body,RealmStory.text_for(lang(),"final_detail"),14,Color("#e6ddb9"))
    else:
        var target_stage: int = (chapter+1)*RealmStory.CHAPTER_SIZE
        if RealmStory.can_enter(data,target_stage):
            var label: String = ["next","continue_celestial","continue_satori"][chapter]
            action(body,RealmStory.text_for(lang(),label),_realm_story_start_chapter.bind(target_stage),true)
        else:
            var gate: String = ["gate","gate_celestial","gate_satori"][chapter]
            text(body,RealmStory.text_for(lang(),gate),14,Color("#e4bd82"))
    action(body,RealmStory.text_for(lang(),"return_ascend"),_realm_story_return_to_ascend,true)
    _open_realm_dialog(parts)

func _realm_story_start_chapter(stage: int) -> void:
    if stage < 0 or stage >= RealmStory.LAST_STAGE: return
    if not RealmStory.can_enter(data,stage):
        realm_story_stage = stage
        _realm_story_locked()
        return
    var destination: int = int(stage / RealmStory.CHAPTER_SIZE)
    if destination > 0 and Realms.ready_for_breakthrough(data,destination-1):
        var state: Dictionary = Realms.state(data)
        if not state.get("auto_transitions") is Dictionary:
            state["auto_transitions"] = {}
        if not bool(state.auto_transitions.get(str(destination-1),false)):
            state.auto_transitions[str(destination-1)] = true
            state["selected"] = destination
            SaveManager.save_data(data)
            if is_instance_valid(active_realm_dialog):
                _close_realm_dialog(active_realm_dialog)
            var epic: ZenRealmTravelCeremony = RealmPortal.new()
            add_child(epic)
            epic.finished.connect(_realm_story_open_after_breakthrough.bind(stage))
            epic.present(Realms.REALM_ART[destination-1],Realms.REALM_ART[destination],
                Realms.realm_name(destination,lang()),true,
                bool(data.settings.get("sound",true)),[world_music],lang())
            return
    _realm_story_open_after_breakthrough(stage)

func _realm_story_open_after_breakthrough(stage: int) -> void:
    if not realm_story_active or not is_inside_tree(): return
    if not RealmStory.can_enter(data,stage): return
    realm_story_progress.game = {}
    _realm_story_set_stage(stage)
    _realm_story_present_intro()

func _realm_story_start_ember() -> void:
    _realm_story_start_chapter(3)

func _realm_story_locked() -> void:
    var parts: Dictionary = _realm_dialog(RealmStory.text_for(lang(),"challenge_unlock"),570)
    var body: VBoxContainer = parts.box
    _realm_story_compact(parts)
    var gate: String = "gate_mode"
    if realm_story_stage >= 9: gate = "gate_satori"
    elif realm_story_stage >= 6: gate = "gate_celestial"
    elif realm_story_stage >= 3: gate = "gate"
    text(body,RealmStory.text_for(lang(),gate),17)
    action(body,RealmStory.text_for(lang(),"return_ascend"),_realm_story_return_to_ascend,true)
    _open_realm_dialog(parts)

func _realm_story_completed() -> void:
    _realm_story_chapter_outro(3)

func _realm_story_menu() -> void:
    if not realm_story_active: return
    var parts: Dictionary = _realm_dialog(RealmStory.text_for(lang(),"menu"),430)
    var body: VBoxContainer = parts.box
    _realm_story_compact(parts)
    # The story pause menu holds only two actions: size it accordingly.
    var frame: PanelContainer = parts.frame
    frame.anchor_top = 0.33
    frame.anchor_bottom = 0.67
    var current_boss: String = RealmStory.text_for(lang(),"final_title") if realm_story_stage >= RealmStory.LAST_STAGE else RealmStory.text_for(lang(),"boss_%d" % realm_story_stage)
    text(body,current_boss,20,Color("#eddaae"))
    action(body,RealmStory.text_for(lang(),"resume"),_realm_story_begin,true)
    action(body,RealmStory.text_for(lang(),"return_ascend"),_realm_story_return_to_ascend)
    var settings: Button = action(body,_campaign_phrase("Einstellungen","Settings","Definições"),show_ascend_settings)
    settings.name = "AscendBattleSettingsEntry"
    var pause_frame: PanelContainer = parts.frame
    pause_frame.anchor_top = 0.31
    pause_frame.anchor_bottom = 0.69
    _hd_menu_dialog(parts, true)
    action(body,_campaign_phrase("Neustart","Restart","Reiniciar"),show_mode_picker)
    action(body,Z("Regeln ansehen"),show_rules)
    action(body,_achievements_label(),show_realm_titles)
    action(body,"Zen Ascend",show_ascend_home)
    _open_realm_dialog(parts)

# Exit the story without returning to Main. The ordinary Ascend 4x4
# renderer, equipped shop skin and four Realm cards are restored in place.
func _realm_story_return_to_ascend() -> void:
    if not realm_story_active: return
    match_generation += 1
    _realm_story_save()
    realm_story_generation += 1
    realm_story_active = false
    ZenChronicles.set_campaign_board_active(false)
    busy = false
    if is_instance_valid(active_realm_dialog):
        _close_realm_dialog(active_realm_dialog)
    cube.clear_boss_skin()
    cube.set_skin(int(data.economy.get("equipped",0)))
    match_realm = int(Realms.state(data).selected)
    bot_level = Realms.fixed_bot_level(match_realm)
    cells.fill(0)
    turn = 1
    result = 0
    recorded = false
    realm_story_last_human = -1
    against_bot = true
    if realm_backdrop != null:
        realm_backdrop.texture = load(Realms.REALM_ART[match_realm])
        _refresh_arena_presentation()
    # Leaving a boss restores the normal Realm/Shop soundtrack immediately.
    # Reuse the existing 1.8-second crossfade; keep the selected music intact.
    sync_realm_music()
    draw()
    call_deferred("show_realms")

func _realm_story_leave() -> void:
    if not realm_story_active: return
    match_generation += 1
    _realm_story_save()
    realm_story_active = false
    ZenChronicles.set_campaign_board_active(false)
    realm_story_generation += 1
    busy = false
    if is_instance_valid(active_realm_dialog):
        _close_realm_dialog(active_realm_dialog)
    # The shop's equipped skin ID was never changed. Restore its material
    # in the same renderer before leaving the 4x4 scene.
    cube.clear_boss_skin()
    cube.set_skin(int(data.economy.get("equipped",0)))
    return_home()

# -------- Campaign 2.0: Abyss native 4x4 battles and story handoff --------
func start_abyss_battle() -> void:
    if not Realm2.unlocked(1): return
    abyss_progress = Abyss.load_progress()
    var next_action: Dictionary = Abyss.next_action(abyss_progress)
    if next_action.get("type") != "battle":
        ZenChronicles.open_abyss_reader()
        return
    abyss_index = int(next_action.get("boss",-1))
    if abyss_index < 0 or abyss_index >= 3: return
    if not Realm2.can_face_boss(1,abyss_index):
        ZenChronicles.open_campaign_challenges(1,true)
        return
    abyss_active = true
    shadow_active = false
    ember_active = false
    campaign_practice_active = false
    campaign_awards = []
    realm_story_active = false
    abyss_generation += 1
    match_generation += 1
    ZenChronicles.set_campaign_board_active(true)
    against_bot = true
    owners = [0,1]
    recorded = false
    busy = false
    var game: Dictionary = Abyss.begin_battle(abyss_progress,abyss_index)
    if game.is_empty(): return
    _hd_remember_chapter(1,1 >= 1 and 1 <= 4)
    hd_direct_realm = false
    cells = game.cells.duplicate()
    turn = clampi(int(game.get("turn",1)),1,2)
    result = clampi(int(game.get("result",0)),0,3)
    recorded = result != 0
    abyss_last_human = int(game.get("last_human",-1))
    bot_level = Abyss.BOT_LEVELS[abyss_index]
    cube.reset_view()
    cube.clear_boss_skin()
    cube.set_abyss_skin(abyss_index+1)
    if realm_backdrop != null:
        var arena: Texture2D = Abyss.battle_backdrop(abyss_index)
        if arena != null: realm_backdrop.texture = arena
        _refresh_arena_presentation()
    _abyss_save()
    sync_realm_music()
    draw()
    if result != 0: _abyss_result()
    else: _abyss_intro()

func _abyss_save() -> bool:
    if not abyss_active: return false
    var starter: int = FinalSeries.round_starter(abyss_progress.get("game",{}))
    abyss_progress.game = {
        "boss":abyss_index,
        "cells":cells.duplicate(),
        "turn":turn,
        "starter":starter,
        "result":result,
        "last_human":abyss_last_human
    }
    var ok: bool = Abyss.save_progress(abyss_progress)
    if not ok: push_warning("Abyss of Memories: could not save battle")
    return ok

func _abyss_add_art(parent: VBoxContainer, height: float = 245.0, zoom: bool = false) -> void:
    var image_path: String = Abyss.boss_art(abyss_index)
    if not ResourceLoader.exists(image_path): return
    var art := TextureRect.new()
    art.texture = load(image_path) as Texture2D
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var image_ratio: float = float(art.texture.get_height()) / maxf(1.0,float(art.texture.get_width()))
    var display_width: float = get_viewport().get_visible_rect().size.x * 0.84
    art.custom_minimum_size.y = minf(height,maxf(180.0,display_width * image_ratio))
    art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(art)

func _abyss_intro() -> void:
    if not abyss_active: return
    var parts: Dictionary = _realm_dialog(Abyss.BOSS_NAMES[abyss_index],670)
    _realm_boss_intro_layout(parts)
    var body: VBoxContainer = parts.box
    _abyss_add_art(body,_realm_boss_portrait_height())
    var opening: Array = [
        "Every stolen memory has a price.",
        "Some wounds remain even when the blade is silent.",
        "Remember who you were – and why you still fight."
    ]
    text(body,opening[abyss_index],16,Color("#dfd4e5"))
    if abyss_index==2: _guardian_series_panel(body,abyss_progress)
    text(body,_boss_starter_caption(abyss_progress.get("game",{})),14,Color("#e1c99d"))
    _realm_boss_primary_action(parts,_campaign_phrase("⚔ Kampf fortsetzen","⚔ Continue Battle","⚔ Continuar batalha") if move_count() > 0 else _campaign_phrase("⚔ Kampf beginnen","⚔ Start Battle","⚔ Começar batalha"),_abyss_begin)
    action(body,_campaign_phrase("‹ Zur Geschichte","‹ Back to Story","‹ Voltar à história"),_abyss_back_to_reader)
    _hd_beta_boss_fit(parts, true)
    _open_realm_dialog(parts)

func _abyss_begin() -> void:
    if not abyss_active: return
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    if result == 0 and turn == 2 and not busy:
        busy = true
        call_deferred("bot_turn")
    draw()

func _abyss_result() -> void:
    if not abyss_active or result == 0: return
    var label: String = "Erinnerung zurückgewonnen" if result == 1 else ("Unentschieden" if result == 3 else "Niederlage")
    if lang() == "en":
        label = "Memory restored" if result == 1 else ("Draw" if result == 3 else "Defeat")
    elif lang() == "pt":
        label = "Memória recuperada" if result == 1 else ("Empate" if result == 3 else "Derrota")
    var parts: Dictionary = _realm_dialog(label,520)
    _realm_boss_result_layout(parts)
    _hd_realm_layout(parts, _hd_realm_outcome(result == 1), label, false)
    var body: VBoxContainer = parts.box
    _abyss_add_art(body,_realm_boss_result_height(),true)
    text(body,Abyss.BOSS_NAMES[abyss_index],18,Color("#e8d4b5"))
    if abyss_index==2: _guardian_series_panel(body,abyss_progress)
    _realm_boss_result_action(parts,_review_board_label(),_review_finished_board.bind(parts.dialog),true)
    if abyss_index==2 and not FinalSeries.player_won(abyss_progress):
        var next_label: String = _campaign_phrase("Neue Serie","Retry Series","Repetir série") if FinalSeries.guardian_won(abyss_progress) else (_campaign_phrase("Runde wiederholen","Replay Round","Repetir ronda") if result==3 else _campaign_phrase("Nächste Runde","Next Round","Próxima ronda"))
        _realm_boss_result_action(parts,"⚔ " + next_label,_abyss_retry,true)
    elif result == 1:
        _realm_boss_result_action(parts,"✦ " + _campaign_phrase("Geschichte fortsetzen","Continue Story","Continuar história"),_abyss_victory,true)
    else:
        _realm_boss_result_action(parts,"⚔ " + _campaign_phrase("Erneut kämpfen","Retry Battle","Repetir batalha"),_abyss_retry,true)
    _realm_boss_result_action(parts,"‹ " + _campaign_phrase("Geschichte verlassen","Leave Story","Sair da história"),_abyss_back_to_reader)
    _hd_realm_finish(parts)
    _hd_beta_boss_fit(parts, false)
    _open_realm_dialog(parts)

func _abyss_retry() -> void:
    if not abyss_active or result==0: return
    var direct_next: bool = abyss_index==2 and not FinalSeries.player_won(abyss_progress) and not FinalSeries.guardian_won(abyss_progress)
    var candidate: Dictionary = abyss_progress.duplicate(true)
    if abyss_index==2:
        if not FinalSeries.start_next(candidate): return
    else: candidate.game = {}
    # Save the new board and the score in one atomic progress write.
    var game: Dictionary = Abyss.begin_battle(candidate,abyss_index)
    if game.is_empty() or not Abyss.save_progress(candidate): return
    abyss_progress = candidate
    abyss_generation += 1
    match_generation += 1
    cells = game.cells.duplicate()
    turn = int(game.turn)
    result = 0
    recorded = false
    busy = false
    abyss_last_human = -1
    cube.reset_view()
    _abyss_save()
    draw()
    if direct_next:
        _abyss_begin()
    else:
        _abyss_intro()

func _abyss_victory() -> void:
    if not abyss_active or result != 1: return
    if not Realm2.can_face_boss(1,abyss_index): return
    if abyss_index==2 and not FinalSeries.player_won(abyss_progress): return
    if not Abyss.record_victory(abyss_progress,abyss_index): return
    abyss_generation += 1
    match_generation += 1
    busy = false
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    # No glass-shatter after ordinary boss victories; the Manhwa resumes.
    # Glass and breakthrough sound are exclusively for actual Realm entry.
    _abyss_back_to_reader()

func _abyss_menu() -> void:
    if not abyss_active: return
    var parts: Dictionary = _realm_dialog("Abyss of Memories",410)
    _realm_story_compact(parts)
    var body: VBoxContainer = parts.box
    text(body,Abyss.BOSS_NAMES[clampi(abyss_index,0,2)],20,Color("#dfd4e5"))
    action(body,_campaign_phrase("⚔ Kampf fortsetzen","⚔ Continue Battle","⚔ Continuar batalha"),_abyss_begin,true)
    action(body,_campaign_phrase("‹ Zur Geschichte","‹ Back to Story","‹ Voltar à história"),_abyss_back_to_reader)
    var settings: Button = action(body,_campaign_phrase("Einstellungen","Settings","Definições"),show_ascend_settings)
    settings.name = "AscendBattleSettingsEntry"
    var pause_frame: PanelContainer = parts.frame
    pause_frame.anchor_top = 0.31
    pause_frame.anchor_bottom = 0.69
    _hd_menu_dialog(parts, true)
    action(body,_campaign_phrase("Neustart","Restart","Reiniciar"),show_mode_picker)
    action(body,Z("Regeln ansehen"),show_rules)
    action(body,_achievements_label(),show_realm_titles)
    action(body,"Zen Ascend",show_ascend_home)
    _open_realm_dialog(parts)

func _abyss_back_to_reader(open_reader: bool = true) -> void:
    if not abyss_active: return
    abyss_generation += 1
    match_generation += 1
    if result != 1: _abyss_save()
    abyss_active = false
    busy = false
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    cube.clear_abyss_skin()
    cube.set_skin(int(data.economy.get("equipped",0)))
    match_realm = int(Realms.state(data).selected)
    bot_level = Realms.fixed_bot_level(match_realm)
    cells.fill(0)
    turn = 1
    result = 0
    recorded = false
    abyss_last_human = -1
    if realm_backdrop != null:
        realm_backdrop.texture = load(Realms.REALM_ART[match_realm])
        _refresh_arena_presentation()
    ZenChronicles.set_campaign_board_active(false)
    draw()
    _hd_restore_selected_board()
    if open_reader: ZenChronicles.open_abyss_reader()
    else: sync_realm_music(true)

# -------- Campaign 2.0: Shadow native 4x4 battles and story handoff --------
func start_shadow_battle() -> void:
    if not Realm2.unlocked(0): return
    shadow_progress = Shadow.load_progress()
    var next_action: Dictionary = Shadow.next_action(shadow_progress)
    if next_action.get("type") != "battle":
        ZenChronicles.open_shadow_reader()
        return
    shadow_index = int(next_action.get("boss",-1))
    if shadow_index < 0 or shadow_index >= 3: return
    if not Realm2.can_face_boss(0,shadow_index):
        ZenChronicles.open_campaign_challenges(0,true)
        return
    shadow_active = true
    campaign_practice_active = false
    campaign_awards = []
    realm_story_active = false
    abyss_active = false
    shadow_generation += 1
    match_generation += 1
    ZenChronicles.set_campaign_board_active(true)
    against_bot = true
    owners = [0,1]
    recorded = false
    busy = false
    var game: Dictionary = Shadow.begin_battle(shadow_progress,shadow_index)
    if game.is_empty(): return
    _hd_remember_chapter(0,0 >= 1 and 0 <= 4)
    hd_direct_realm = false
    cells = game.cells.duplicate()
    turn = clampi(int(game.get("turn",1)),1,2)
    result = clampi(int(game.get("result",0)),0,3)
    recorded = result != 0
    shadow_last_human = int(game.get("last_human",-1))
    bot_level = Shadow.BOT_LEVELS[shadow_index]
    cube.reset_view()
    cube.clear_abyss_skin()
    cube.clear_boss_skin()
    cube.set_boss_skin(shadow_index)
    if realm_backdrop != null:
        var arena: Texture2D = Shadow.battle_backdrop(shadow_index)
        if arena != null: realm_backdrop.texture = arena
        _refresh_arena_presentation()
    _shadow_save()
    sync_realm_music()
    draw()
    if result != 0: _shadow_result()
    else: _shadow_intro()

func _shadow_save() -> bool:
    if not shadow_active: return false
    var starter: int = FinalSeries.round_starter(shadow_progress.get("game",{}))
    shadow_progress.game = {
        "boss":shadow_index,
        "cells":cells.duplicate(),
        "turn":turn,
        "starter":starter,
        "result":result,
        "last_human":shadow_last_human
    }
    var ok: bool = Shadow.save_progress(shadow_progress)
    if not ok: push_warning("Shadow Realm: could not save battle")
    return ok

func _shadow_add_art(parent: VBoxContainer, height: float = 245.0, zoom: bool = false) -> void:
    var portrait: Texture2D = Shadow.boss_art(shadow_index)
    if portrait == null: return
    var art := TextureRect.new()
    art.texture = portrait
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var image_ratio: float = float(portrait.get_height()) / maxf(1.0,float(portrait.get_width()))
    var display_width: float = get_viewport().get_visible_rect().size.x * 0.84
    art.custom_minimum_size.y = minf(height,maxf(180.0,display_width * image_ratio))
    art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(art)

func _shadow_intro() -> void:
    if not shadow_active: return
    var parts: Dictionary = _realm_dialog(Shadow.BOSS_NAMES[shadow_index],670)
    _realm_boss_intro_layout(parts)
    var body: VBoxContainer = parts.box
    _shadow_add_art(body,_realm_boss_portrait_height())
    var opening: Array = [
        "The mist conceals the path, but never the next move.",
        "The mirror remembers every repeated mistake.",
        "At the veil gate, patience is the final blade."
    ]
    text(body,opening[shadow_index],16,Color("#dfd4e5"))
    if shadow_index==2: _guardian_series_panel(body,shadow_progress)
    text(body,_boss_starter_caption(shadow_progress.get("game",{})),14,Color("#e1c99d"))
    _realm_boss_primary_action(parts,_campaign_phrase("⚔ Kampf fortsetzen","⚔ Continue Battle","⚔ Continuar batalha") if move_count() > 0 else _campaign_phrase("⚔ Kampf beginnen","⚔ Start Battle","⚔ Começar batalha"),_shadow_begin)
    action(body,_campaign_phrase("‹ Zur Geschichte","‹ Back to Story","‹ Voltar à história"),_shadow_back_to_reader)
    _hd_beta_boss_fit(parts, true)
    _open_realm_dialog(parts)

func _shadow_begin() -> void:
    if not shadow_active: return
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    if result == 0 and turn == 2 and not busy:
        busy = true
        call_deferred("bot_turn")
    draw()

func _shadow_result() -> void:
    if not shadow_active or result == 0: return
    var label: String = "Der Schleier weicht" if result == 1 else ("Unentschieden" if result == 3 else "Niederlage")
    if lang() == "en":
        label = "The veil fades" if result == 1 else ("Draw" if result == 3 else "Defeat")
    elif lang() == "pt":
        label = "O véu desvanece" if result == 1 else ("Empate" if result == 3 else "Derrota")
    var parts: Dictionary = _realm_dialog(label,520)
    _realm_boss_result_layout(parts)
    _hd_realm_layout(parts, _hd_realm_outcome(result == 1), label, false)
    var body: VBoxContainer = parts.box
    _shadow_add_art(body,_realm_boss_result_height(),true)
    text(body,Shadow.BOSS_NAMES[shadow_index],18,Color("#e8d4b5"))
    if shadow_index==2: _guardian_series_panel(body,shadow_progress)
    _realm_boss_result_action(parts,_review_board_label(),_review_finished_board.bind(parts.dialog),true)
    if shadow_index==2 and not FinalSeries.player_won(shadow_progress):
        var next_label: String = _campaign_phrase("Neue Serie","Retry Series","Repetir série") if FinalSeries.guardian_won(shadow_progress) else (_campaign_phrase("Runde wiederholen","Replay Round","Repetir ronda") if result==3 else _campaign_phrase("Nächste Runde","Next Round","Próxima ronda"))
        _realm_boss_result_action(parts,"⚔ " + next_label,_shadow_retry,true)
    elif result == 1:
        _realm_boss_result_action(parts,"✦ " + _campaign_phrase("Geschichte fortsetzen","Continue Story","Continuar história"),_shadow_victory,true)
    else:
        _realm_boss_result_action(parts,"⚔ " + _campaign_phrase("Erneut kämpfen","Retry Battle","Repetir batalha"),_shadow_retry,true)
    _realm_boss_result_action(parts,"‹ " + _campaign_phrase("Geschichte verlassen","Leave Story","Sair da história"),_shadow_back_to_reader)
    _hd_realm_finish(parts)
    _hd_beta_boss_fit(parts, false)
    _open_realm_dialog(parts)

func _shadow_retry() -> void:
    if not shadow_active or result==0: return
    var direct_next: bool = shadow_index==2 and not FinalSeries.player_won(shadow_progress) and not FinalSeries.guardian_won(shadow_progress)
    var candidate: Dictionary = shadow_progress.duplicate(true)
    if shadow_index==2:
        if not FinalSeries.start_next(candidate): return
    else: candidate.game = {}
    # Save the new board and the score in one atomic progress write.
    var game: Dictionary = Shadow.begin_battle(candidate,shadow_index)
    if game.is_empty() or not Shadow.save_progress(candidate): return
    shadow_progress = candidate
    shadow_generation += 1
    match_generation += 1
    cells = game.cells.duplicate()
    turn = int(game.turn)
    result = 0
    recorded = false
    busy = false
    shadow_last_human = -1
    cube.reset_view()
    _shadow_save()
    draw()
    if direct_next:
        _shadow_begin()
    else:
        _shadow_intro()

func _shadow_victory() -> void:
    if not shadow_active or result != 1: return
    if not Realm2.can_face_boss(0,shadow_index): return
    if shadow_index==2 and not FinalSeries.player_won(shadow_progress): return
    if not Shadow.record_victory(shadow_progress,shadow_index): return
    shadow_generation += 1
    match_generation += 1
    busy = false
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    # The Veil dissolves quietly. Epic glass fracture is reserved for
    # Shadow → Abyss and Abyss → Ember after all 3+3 requirements.
    _shadow_back_to_reader()

func _shadow_menu() -> void:
    if not shadow_active: return
    var parts: Dictionary = _realm_dialog("Shadow Realm",410)
    _realm_story_compact(parts)
    var body: VBoxContainer = parts.box
    text(body,Shadow.BOSS_NAMES[clampi(shadow_index,0,2)],20,Color("#dfd4e5"))
    action(body,_campaign_phrase("⚔ Kampf fortsetzen","⚔ Continue Battle","⚔ Continuar batalha"),_shadow_begin,true)
    action(body,_campaign_phrase("‹ Zur Geschichte","‹ Back to Story","‹ Voltar à história"),_shadow_back_to_reader)
    var settings: Button = action(body,_campaign_phrase("Einstellungen","Settings","Definições"),show_ascend_settings)
    settings.name = "AscendBattleSettingsEntry"
    var pause_frame: PanelContainer = parts.frame
    pause_frame.anchor_top = 0.31
    pause_frame.anchor_bottom = 0.69
    _hd_menu_dialog(parts, true)
    action(body,_campaign_phrase("Neustart","Restart","Reiniciar"),show_mode_picker)
    action(body,Z("Regeln ansehen"),show_rules)
    action(body,_achievements_label(),show_realm_titles)
    action(body,"Zen Ascend",show_ascend_home)
    _open_realm_dialog(parts)

func _shadow_back_to_reader(open_reader: bool = true) -> void:
    if not shadow_active: return
    shadow_generation += 1
    match_generation += 1
    if result != 1: _shadow_save()
    shadow_active = false
    busy = false
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    cube.clear_boss_skin()
    cube.set_skin(int(data.economy.get("equipped",0)))
    match_realm = int(Realms.state(data).selected)
    bot_level = Realms.fixed_bot_level(match_realm)
    cells.fill(0)
    turn = 1
    result = 0
    recorded = false
    shadow_last_human = -1
    if realm_backdrop != null:
        realm_backdrop.texture = load(Realms.REALM_ART[match_realm])
        _refresh_arena_presentation()
    ZenChronicles.set_campaign_board_active(false)
    draw()
    _hd_restore_selected_board()
    if open_reader: ZenChronicles.open_shadow_reader()
    else: sync_realm_music(true)


func start_ember_battle() -> void:
    if not Realm2.unlocked(2): return
    guardian_chapter = 2
    ember_model = Ember
    _start_guardian_battle()

func start_celestial_battle() -> void:
    if not Realm2.unlocked(3): return
    guardian_chapter = 3
    ember_model = Celestial
    _start_guardian_battle()

func start_satori_battle() -> void:
    if not Realm2.unlocked(4): return
    guardian_chapter = 4
    ember_model = Satori
    _start_guardian_battle()

func start_shattered_moon_battle() -> void:
    if not Moon.unlocked() and not Moon.qa_mode(): return
    guardian_chapter = 5 # separate post-Satori story chapter
    ember_model = Moon
    _start_guardian_battle()

func _open_guardian_reader() -> void:
    if guardian_chapter==5: ZenChronicles.open_shattered_moon_preview()
    elif guardian_chapter==4: ZenChronicles.open_satori_campaign_preview()
    elif guardian_chapter==3: ZenChronicles.open_celestial_campaign_preview()
    else: ZenChronicles.open_ember_reader()

func _start_guardian_battle() -> void:
    ember_progress = ember_model.load_progress()
    var next_action: Dictionary = ember_model.next_action(ember_progress)
    if next_action.get("type") != "battle":
        _open_guardian_reader()
        return
    ember_index = int(next_action.get("boss",-1))
    if ember_index < 0 or ember_index >= 3: return
    if guardian_chapter not in [4,5] and not Realm2.can_face_boss(guardian_chapter,ember_index):
        ZenChronicles.open_campaign_challenges(guardian_chapter,true)
        return
    ember_active = true
    campaign_practice_active = false
    campaign_awards = []
    realm_story_active = false
    abyss_active = false
    shadow_active = false
    ember_generation += 1
    match_generation += 1
    ZenChronicles.set_campaign_board_active(true)
    against_bot = true
    owners = [0,1]
    recorded = false
    busy = false
    var game: Dictionary = ember_model.begin_battle(ember_progress,ember_index)
    if game.is_empty(): return
    _hd_remember_chapter(guardian_chapter,guardian_chapter >= 1 and guardian_chapter <= 4)
    hd_direct_realm = false
    cells = game.cells.duplicate()
    turn = clampi(int(game.get("turn",1)),1,2)
    result = clampi(int(game.get("result",0)),0,3)
    recorded = result != 0
    ember_last_human = int(game.get("last_human",-1))
    bot_level = ember_model.BOT_LEVELS[ember_index]
    cube.reset_view()
    cube.clear_abyss_skin()
    cube.clear_boss_skin()
    cube.set_boss_skin(ember_index+(9 if guardian_chapter>=4 else (6 if guardian_chapter==3 else 3)))
    if realm_backdrop != null:
        var arena: Texture2D = ember_model.battle_backdrop(ember_index)
        if arena != null: realm_backdrop.texture = arena
        _refresh_arena_presentation()
    _ember_save()
    sync_realm_music()
    draw()
    if result != 0: _ember_result()
    else: _ember_intro()

func _ember_save() -> bool:
    if not ember_active: return false
    var starter: int = FinalSeries.round_starter(ember_progress.get("game",{}))
    ember_progress.game = {
        "boss":ember_index,
        "cells":cells.duplicate(),
        "turn":turn,
        "starter":starter,
        "result":result,
        "last_human":ember_last_human
    }
    var ok: bool = ember_model.save_progress(ember_progress)
    if not ok: push_warning("Ember Temple: could not save battle")
    return ok

func _ember_add_art(parent: VBoxContainer, height: float = 245.0, zoom: bool = false) -> void:
    var portrait: Texture2D = ember_model.boss_art(ember_index)
    if portrait == null: return
    var art := TextureRect.new()
    art.texture = portrait
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var image_ratio: float = float(portrait.get_height()) / maxf(1.0,float(portrait.get_width()))
    var display_width: float = get_viewport().get_visible_rect().size.x * 0.84
    art.custom_minimum_size.y = minf(height,maxf(180.0,display_width * image_ratio))
    art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(art)

func _ember_intro() -> void:
    if not ember_active: return
    var parts: Dictionary = _realm_dialog(ember_model.BOSS_NAMES[ember_index],670)
    _realm_boss_intro_layout(parts)
    var body: VBoxContainer = parts.box
    _ember_add_art(body,_realm_boss_portrait_height())
    var opening: Array = [
        "See beyond the first move.",
        "A strategy without discipline is only a spark.",
        "Show me the shape of your fire."
    ]
    if guardian_chapter==3: opening = ["Every decision creates a thousand possibilities.","Let thunder shake the heavens.","Then show me what you have become."]
    if guardian_chapter==4: opening = ["See clearly before you move.","A victory need not define you.","What remains when the game is over?"]
    if guardian_chapter==5: opening = ["The echoes have not faded.","Cross the silence with an open heart.","What can you release beneath the broken moon?"]
    text(body,opening[ember_index],16,Color("#dfd4e5"))
    _guardian_series_panel(body,ember_progress)
    text(body,_boss_starter_caption(ember_progress.get("game",{})),14,Color("#e1c99d"))
    _realm_boss_primary_action(parts,_campaign_phrase("⚔ Kampf fortsetzen","⚔ Continue Battle","⚔ Continuar batalha") if move_count() > 0 else _campaign_phrase("⚔ Kampf beginnen","⚔ Start Battle","⚔ Começar batalha"),_ember_begin)
    action(body,_campaign_phrase("‹ Zur Geschichte","‹ Back to Story","‹ Voltar à história"),_ember_back_to_reader)
    _hd_beta_boss_fit(parts, true)
    _open_realm_dialog(parts)

func _ember_begin() -> void:
    if not ember_active: return
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    if result == 0 and turn == 2 and not busy:
        busy = true
        call_deferred("bot_turn")
    draw()

func _ember_result() -> void:
    if not ember_active or result == 0: return
    var label: String = "Die Flamme wird ruhig" if result == 1 else ("Unentschieden" if result == 3 else "Niederlage")
    if lang() == "en":
        label = "The flame grows quiet" if result == 1 else ("Draw" if result == 3 else "Defeat")
    elif lang() == "pt":
        label = "A chama acalma" if result == 1 else ("Empate" if result == 3 else "Derrota")
    if guardian_chapter==3 and result==1: label = _campaign_phrase("Klarheit","Clarity","Clareza")
    if guardian_chapter==4 and result==1: label = _campaign_phrase("Das letzte Erwachen","The Final Awakening","O Despertar Final")
    if guardian_chapter==5 and result==1: label = _campaign_phrase("Die letzte Überfahrt","The Last Crossing","A Última Travessia")
    var parts: Dictionary = _realm_dialog(label,520)
    _realm_boss_result_layout(parts)
    _hd_realm_layout(parts, _hd_realm_outcome(result == 1), label, false)
    var body: VBoxContainer = parts.box
    _ember_add_art(body,_realm_boss_result_height(),true)
    text(body,ember_model.BOSS_NAMES[ember_index],18,Color("#e8d4b5"))
    _guardian_series_panel(body,ember_progress)
    _realm_boss_result_action(parts,_review_board_label(),_review_finished_board.bind(parts.dialog),true)
    if not ember_model.player_won(ember_progress):
        var next_label: String = _campaign_phrase("Neue Serie","Retry Series","Repetir série") if ember_model.guardian_won(ember_progress) else (_campaign_phrase("Runde wiederholen","Replay Round","Repetir ronda") if result==3 else _campaign_phrase("Nächste Runde","Next Round","Próxima ronda"))
        _realm_boss_result_action(parts,"⚔ " + next_label,_ember_retry,true)
    elif result == 1:
        _realm_boss_result_action(parts,"✦ " + _campaign_phrase("Geschichte fortsetzen","Continue Story","Continuar história"),_ember_victory,true)
    else:
        _realm_boss_result_action(parts,"⚔ " + _campaign_phrase("Erneut kämpfen","Retry Battle","Repetir batalha"),_ember_retry,true)
    _realm_boss_result_action(parts,"‹ " + _campaign_phrase("Geschichte verlassen","Leave Story","Sair da história"),_ember_back_to_reader)
    _hd_realm_finish(parts)
    _hd_beta_boss_fit(parts, false)
    _open_realm_dialog(parts)

func _ember_retry() -> void:
    if not ember_active or result==0: return
    var direct_next: bool = not ember_model.player_won(ember_progress) and not ember_model.guardian_won(ember_progress)
    var candidate: Dictionary = ember_progress.duplicate(true)
    if not ember_model.start_next(candidate): return
    # Save the new board and the score in one atomic progress write.
    var game: Dictionary = ember_model.begin_battle(candidate,ember_index)
    if game.is_empty() or not ember_model.save_progress(candidate): return
    ember_progress = candidate
    ember_generation += 1
    match_generation += 1
    cells = game.cells.duplicate()
    turn = int(game.turn)
    result = 0
    recorded = false
    busy = false
    ember_last_human = -1
    cube.reset_view()
    _ember_save()
    draw()
    if direct_next:
        _ember_begin()
    else:
        _ember_intro()

func _ember_victory() -> void:
    if not ember_active or result != 1: return
    if guardian_chapter not in [4,5] and not Realm2.can_face_boss(guardian_chapter,ember_index): return
    if not ember_model.player_won(ember_progress): return
    if not ember_model.record_victory(ember_progress,ember_index): return
    ember_generation += 1
    match_generation += 1
    busy = false
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    # The Veil dissolves quietly. Epic glass fracture is reserved for
    # Shadow → Abyss and Abyss → Ember after all 3+3 requirements.
    _ember_back_to_reader()

func _ember_menu() -> void:
    if not ember_active: return
    var parts: Dictionary = _realm_dialog("Shattered Moon" if guardian_chapter==5 else Realm2.REALM_NAMES[guardian_chapter],410)
    _realm_story_compact(parts)
    var body: VBoxContainer = parts.box
    text(body,ember_model.BOSS_NAMES[clampi(ember_index,0,2)],20,Color("#dfd4e5"))
    action(body,_campaign_phrase("⚔ Kampf fortsetzen","⚔ Continue Battle","⚔ Continuar batalha"),_ember_begin,true)
    action(body,_campaign_phrase("‹ Zur Geschichte","‹ Back to Story","‹ Voltar à história"),_ember_back_to_reader)
    var settings: Button = action(body,_campaign_phrase("Einstellungen","Settings","Definições"),show_ascend_settings)
    settings.name = "AscendBattleSettingsEntry"
    var pause_frame: PanelContainer = parts.frame
    pause_frame.anchor_top = 0.31
    pause_frame.anchor_bottom = 0.69
    _hd_menu_dialog(parts, true)
    action(body,_campaign_phrase("Neustart","Restart","Reiniciar"),show_mode_picker)
    action(body,Z("Regeln ansehen"),show_rules)
    action(body,_achievements_label(),show_realm_titles)
    action(body,"Zen Ascend",show_ascend_home)
    _open_realm_dialog(parts)

func _ember_back_to_reader(open_reader: bool = true) -> void:
    if not ember_active: return
    ember_generation += 1
    match_generation += 1
    if not bool(ember_progress.defeated[ember_index]): _ember_save()
    ember_active = false
    busy = false
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    cube.clear_boss_skin()
    cube.set_skin(int(data.economy.get("equipped",0)))
    match_realm = int(Realms.state(data).selected)
    bot_level = Realms.fixed_bot_level(match_realm)
    cells.fill(0)
    turn = 1
    result = 0
    recorded = false
    ember_last_human = -1
    if realm_backdrop != null:
        realm_backdrop.texture = load(Realms.REALM_ART[match_realm])
        _refresh_arena_presentation()
    ZenChronicles.set_campaign_board_active(false)
    draw()
    _hd_restore_selected_board()
    if open_reader: _open_guardian_reader()
    else: sync_realm_music(true)


# ---- Zen Realm Chronicles: NORMAL Abyss bot matches, not puzzles ----
func start_campaign_practice(chapter: int, direct_entry: bool = false, begin_match: bool = true) -> void:
    if chapter not in [0,1,2,3,4] or not Realm2.unlocked(chapter): return
    if move_count()>0 and result==0:
        # Do not replace a live board when moving between Realms.
        if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
        return
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    if chapter==0:
        if not Realms.select(data,0): return
        campaign_practice_active = false
        campaign_awards = []
        cube.clear_abyss_skin()
        cube.set_skin(int(data.economy.get("equipped",0)))
        ZenChronicles.set_campaign_board_active(false)
        SaveManager.save_data(data)
        if realm_backdrop != null:
            realm_backdrop.texture = load(Realms.REALM_ART[0])
            _refresh_arena_presentation()
        hd_direct_realm = false
        _hd_remember_chapter(0,false)
        match_realm = 0
        bot_level = Realms.fixed_bot_level(0)
        sync_realm_music()
        if begin_match:
            start_game(true,Realms.fixed_bot_level(0))
        else:
            against_bot = true
            owners = [0,1]
            cube.reset_view()
            draw()
        return
    # Direct free play is available in an earned Realm. The existing record_*_match
    # functions still enforce page 19 for Celestial/Satori challenge credit.
    if not direct_entry and chapter==3 and int(Celestial.load_progress().page)<19: return
    if not direct_entry and chapter==4 and int(Satori.load_progress().page)<19: return
    hd_direct_realm = direct_entry
    campaign_practice_active = true
    practice_chapter = chapter
    if direct_entry: match_realm = [0,0,1,2,3][chapter]
    elif chapter==4: match_realm = 3
    ember_active = false
    abyss_active = false
    shadow_active = false
    realm_story_active = false
    against_bot = true
    bot_level = (4 if practice_chapter==4 else (2 if practice_chapter in [2,3] else 1))
    owners = [0,1]
    ZenChronicles.set_campaign_board_active(true)
    cube.clear_boss_skin()
    cube.clear_abyss_skin()
    if realm_backdrop != null:
        var arena: Texture2D = Satori.battle_backdrop() if practice_chapter==4 else (Celestial.battle_backdrop() if practice_chapter==3 else (Ember.battle_backdrop() if practice_chapter==2 else Abyss.battle_backdrop()))
        if arena != null: realm_backdrop.texture = arena
        _refresh_arena_presentation()
    sync_realm_music()
    if begin_match:
        _campaign_practice_restart()
    else:
        match_generation += 1
        cells.fill(0)
        turn = 1
        result = 0
        recorded = false
        busy = false
        match_blocked_threat = false
        cube.reset_view()
        draw()

func _campaign_practice_restart() -> void:
    if not campaign_practice_active: return
    match_generation += 1
    cells.fill(0)
    result = 0
    recorded = false
    busy = false
    campaign_awards = []
    campaign_award_index = 0
    match_blocked_threat = false
    var total: int = int(Realm2.load_progress().satori_stats.played if practice_chapter==4 else (Realm2.load_progress().celestial_stats.played if practice_chapter==3 else (Realm2.load_progress().ember_stats.played if practice_chapter==2 else Realm2.load_progress().abyss_stats.played)))
    turn = 1 if total % 2 == 0 else 2
    cube.reset_view()
    draw()
    if turn == 2:
        busy = true
        call_deferred("bot_turn")

# Only first-time achievements returned by record_abyss/ember/celestial_match
# are celebrated. Reopening a match result never repeats the ceremony or sound.
func _campaign_practice_show_next_award() -> void:
    if not is_inside_tree() or not campaign_practice_active or result == 0: return
    if campaign_award_index >= campaign_awards.size():
        call_deferred("_campaign_practice_result")
        return
    var title_name: String = campaign_awards[campaign_award_index]
    campaign_award_index += 1
    var description: String = ""
    for task_index in range(3):
        if Realm2.task_title(practice_chapter,task_index) == title_name:
            description = Realm2.task_description(practice_chapter,task_index,lang())
            break
    if description.is_empty():
        description = _campaign_phrase("Ein neuer Schritt auf deinem Zen-Pfad.",
            "A new step on your Zen path.","Mais um passo no teu caminho Zen.")
    var saved_match_generation: int = match_generation
    var celebration: ZenUnlockCeremony = UnlockCeremony.new()
    celebration.name = "RealmChallengeEarnedCeremony"
    add_child(celebration)
    celebration.finished.connect(func():
        if is_inside_tree() and campaign_practice_active and result != 0 and match_generation == saved_match_generation:
            call_deferred("_campaign_practice_show_next_award")
    )
    celebration.present("challenge",Abyss.battle_backdrop() if practice_chapter==1 else Realm2.SOURCE_ART[practice_chapter],
        title_name,description,bool(data.settings.get("sound",true)),[world_music],lang())

func _campaign_practice_result() -> void:
    if not campaign_practice_active or result == 0: return
    var heading: String = _campaign_phrase("Sieg","Victory","Vitória") if result==1 else (
        _campaign_phrase("Unentschieden","Draw","Empate") if result==3 else
        _campaign_phrase("Niederlage","Defeat","Derrota"))
    var parts: Dictionary = _realm_dialog(heading,520)
    _campaign_result_compact(parts)
    var body: VBoxContainer = parts.box
    _hd_realm_layout(parts, heading, Realm2.REALM_NAMES[practice_chapter] + " · Zen-Bot", true)
    if not campaign_awards.is_empty():
        text(body,_campaign_phrase("🏆 Realm-Challenge abgeschlossen!","🏆 Realm challenge earned!","🏆 Desafio de reino concluído!"),18,Color("#c8e8b4"))
        for title_name in campaign_awards:
            text(body,"✓ " + title_name,17,Color("#e5d2ac"))
    text(body,_campaign_phrase("Realm-Challenges: %d/3","Realm challenges: %d/3","Desafios do reino: %d/3") %
        Realm2.completed_count(Realm2.load_progress(),practice_chapter),16,Color("#e8ddc5"))
    action(body,_review_board_label(),_review_finished_board.bind(parts.dialog),true)
    if Realm2.final_boss_waiting(practice_chapter):
        action(body,_campaign_phrase("⚔ Finalen Boss betreten","⚔ Enter Final Boss","⚔ Enfrentar o chefe final"),_enter_campaign_final_guardian.bind(practice_chapter),true)
    elif Realm2.completed_count(Realm2.load_progress(),practice_chapter)==3 and Realm2.bosses_won(practice_chapter)<3:
        action(body,_campaign_phrase("Geschichte fortsetzen","Continue Story","Continuar história"),_open_campaign_story_from_match.bind(practice_chapter),true)
    action(body,_campaign_phrase("⚔ Noch eine Partie","⚔ Play Again","⚔ Jogar novamente"),_campaign_practice_begin_again,true)
    action(body,_campaign_phrase("‹ Zu den Realm-Challenges","‹ Realm Challenges","‹ Desafios do reino"),_campaign_practice_back)
    if hd_direct_realm:
        action(body,_campaign_phrase("Zen Ascend","Zen Ascend","Zen Ascend"),show_ascend_home)
    _hd_realm_finish(parts, _campaign_realm_quote(practice_chapter))
    _open_realm_dialog(parts)

func _enter_campaign_final_guardian(chapter: int) -> void:
    if not Realm2.final_boss_waiting(chapter): return
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    ZenChronicles.request_final_guardian(chapter)

func _open_campaign_story_from_match(chapter: int) -> void:
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    if chapter==0: ZenChronicles.open_shadow_reader()
    elif chapter==1: ZenChronicles.open_abyss_reader()
    elif chapter==2: ZenChronicles.open_ember_campaign_preview()
    elif chapter==3: ZenChronicles.open_celestial_campaign_preview()
    else: ZenChronicles.open_satori_campaign_preview()

func _campaign_practice_begin_again() -> void:
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    _campaign_practice_restart()

func _campaign_practice_menu() -> void:
    if not campaign_practice_active: return
    var parts: Dictionary = _realm_dialog(Realm2.REALM_NAMES[practice_chapter] + " · Zen-Bot",420)
    _realm_story_compact(parts)
    var body: VBoxContainer = parts.box
    action(body,_campaign_phrase("⚔ Partie fortsetzen","⚔ Continue Match","⚔ Continuar partida"),_campaign_practice_begin,true)
    action(body,_campaign_phrase("‹ Zu den Realm-Challenges","‹ Realm Challenges","‹ Desafios do reino"),_campaign_practice_back)
    var settings: Button = action(body,_campaign_phrase("Einstellungen","Settings","Definições"),show_ascend_settings)
    settings.name = "AscendBattleSettingsEntry"
    var pause_frame: PanelContainer = parts.frame
    pause_frame.anchor_top = 0.31
    pause_frame.anchor_bottom = 0.69
    _hd_menu_dialog(parts, true)
    action(body,_campaign_phrase("Neustart","Restart","Reiniciar"),show_mode_picker)
    action(body,Z("Regeln ansehen"),show_rules)
    action(body,_achievements_label(),show_realm_titles)
    _open_realm_dialog(parts)

func _campaign_practice_begin() -> void:
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)

func _campaign_practice_back() -> void:
    if not campaign_practice_active: return
    match_generation += 1
    campaign_practice_active = false
    campaign_awards = []
    busy = false
    if is_instance_valid(active_realm_dialog): _close_realm_dialog(active_realm_dialog)
    cube.clear_abyss_skin()
    cube.set_skin(int(data.economy.get("equipped",0)))
    match_realm = int(Realms.state(data).selected)
    bot_level = Realms.fixed_bot_level(match_realm)
    cells.fill(0)
    turn = 1
    result = 0
    recorded = false
    if realm_backdrop != null:
        realm_backdrop.texture = load(Realms.REALM_ART[match_realm])
        _refresh_arena_presentation()
    ZenChronicles.set_campaign_board_active(false)
    sync_realm_music()
    draw()
    var return_chapter: int = practice_chapter
    hd_direct_realm = false
    _hd_restore_selected_board()
    ZenChronicles.open_campaign_challenges(return_chapter)

func _show_ember_vfx_test() -> void:
    if not Realm2.qa_mode(): return
    var parts: Dictionary = _realm_dialog("Ember Boss · VFX Test",680)
    var body: VBoxContainer = parts.box
    text(body,_campaign_phrase("Nur Vorschau – kein Spielstand wird verändert.","Preview only – no progress is changed.","Pré-visualização sem alterar o progresso."),14)
    var frame: SubViewportContainer = SubViewportContainer.new()
    frame.custom_minimum_size = Vector2(0,340)
    frame.stretch = true
    body.add_child(frame)
    var view: SubViewport = SubViewport.new()
    view.own_world_3d = true
    view.transparent_bg = true
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    frame.add_child(view)
    var preview: AscendRenderer = AscendRenderer.new()
    view.add_child(preview)
    preview.set_boss_skin(3)
    for i in range(3):
        action(body,Ember.BOSS_NAMES[i],preview.set_boss_skin.bind(i+3))
    action(body,"↻ 90°",preview.rotate_cube.bind(Vector2(196.35,0)))
    action(body,_campaign_phrase("Zurück","Back","Voltar"),show_ascend_menu)
    _open_realm_dialog(parts)
