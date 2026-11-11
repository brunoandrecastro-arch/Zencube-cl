class_name ZenRankCeremony
extends CanvasLayer
## ZenCube's original one-time rank-up celebration. Presentation only:
## no changes to bot decisions, earnings, ranks, game state or stored saves.
signal finished

const Asc = preload("res://core/ZenAscension.gd")
const Locale = preload("res://core/ZenLocalization.gd")
const GONG_IMAGE = preload("res://assets/effects/zen_temple_gong.png")
const WAVE_IMAGE = preload("res://assets/effects/zen_golden_wave.png")
const GONG_AUDIO = preload("res://assets/audio/zen_temple_gong.wav")
const SECONDS: float = 5.5

var _active: bool = false
var _closed: bool = false
var _overlay: Control
var _gong_player: AudioStreamPlayer
var _music_levels: Array = []

func present(new_rank: int, language: String, effects_on: bool, music_sources: Array) -> void:
    if _active:
        return
    _active = true
    layer = 20
    var rank: int = clampi(new_rank, 1, 5)
    _build(rank, language)
    _duck_music(music_sources)
    if effects_on:
        _gong_player.play()
    get_tree().create_timer(SECONDS).timeout.connect(skip)

func _copy(de: String, en: String, pt: String, language: String) -> String:
    if language == "en": return en
    if language == "pt": return pt
    return de

func _make_text(parent: Node, value: String, size: int, color: Color) -> Label:
    var text_label: Label = Label.new()
    text_label.text = value
    text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text_label.add_theme_font_size_override("font_size", size)
    text_label.add_theme_color_override("font_color", color)
    text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(text_label)
    return text_label

func _golden_wave(parent: Node, delay: float) -> void:
    var wave: TextureRect = TextureRect.new()
    wave.texture = WAVE_IMAGE
    wave.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    wave.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    wave.position = Vector2(3.0, 0.0)
    wave.size = Vector2(244.0, 244.0)
    wave.pivot_offset = Vector2(122.0, 122.0)
    wave.mouse_filter = Control.MOUSE_FILTER_IGNORE
    wave.modulate.a = 0.0
    wave.scale = Vector2(0.46, 0.46)
    parent.add_child(wave)
    var pulse: Tween = create_tween().set_parallel(true)
    pulse.tween_property(wave, "scale", Vector2(1.65, 1.65), 2.0).set_delay(delay).set_trans(Tween.TRANS_SINE)
    pulse.tween_property(wave, "modulate:a", 0.90, 0.32).set_delay(delay)
    pulse.tween_property(wave, "modulate:a", 0.0, 1.46).set_delay(delay + 0.36)

func _leaves(parent: Node) -> void:
    # Lightweight animated zen leaves: no GPU particles, no random external assets.
    var rect: Vector2 = get_viewport().get_visible_rect().size
    for index in range(16):
        var leaf: Polygon2D = Polygon2D.new()
        leaf.polygon = PackedVector2Array([
            Vector2(0,-12), Vector2(6,-3), Vector2(4,5),
            Vector2(0,11), Vector2(-4,5), Vector2(-6,-3)
        ])
        leaf.color = Color("f4d187") if index % 3 == 0 else Color("b6c98e")
        leaf.position = Vector2(rect.x * (0.08 + randf() * 0.84), rect.y * (0.80 + randf() * 0.16))
        leaf.rotation = randf_range(-1.2, 1.2)
        leaf.modulate.a = 0.0
        parent.add_child(leaf)
        var delay: float = randf_range(0.35, 1.65)
        var drift: float = randf_range(-90.0, 90.0)
        var duration: float = randf_range(2.55, 3.75)
        var anim: Tween = create_tween().set_parallel(true)
        anim.tween_property(leaf, "position", leaf.position + Vector2(drift, -rect.y * 0.72), duration).set_delay(delay).set_trans(Tween.TRANS_SINE)
        anim.tween_property(leaf, "rotation", leaf.rotation + randf_range(-2.7, 2.7), duration).set_delay(delay)
        anim.tween_property(leaf, "modulate:a", 0.86, 0.45).set_delay(delay)
        anim.tween_property(leaf, "modulate:a", 0.0, 0.70).set_delay(delay + duration - 0.70)

func _build(rank: int, language: String) -> void:
    _overlay = Control.new()
    _overlay.name = "ZenAscensionCeremony"
    _overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_overlay)
    _overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _overlay.modulate.a = 0.0

    var scenery: TextureRect = TextureRect.new()
    scenery.name = "UnsealedWorld"
    scenery.texture = Asc.WORLD_TEXTURES[mini(rank, 4)]
    scenery.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    scenery.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    scenery.modulate = Color(0.70, 0.66, 0.56, 0.88)
    scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _overlay.add_child(scenery)
    scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var shadow: ColorRect = ColorRect.new()
    shadow.color = Color("0e1414", 0.79)
    shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _overlay.add_child(shadow)
    shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _leaves(_overlay)

    var safe: MarginContainer = MarginContainer.new()
    _overlay.add_child(safe)
    safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right"]:
        safe.add_theme_constant_override("margin_" + side, 12)
    safe.add_theme_constant_override("margin_top", 20)
    safe.add_theme_constant_override("margin_bottom", 20)
    var center: CenterContainer = CenterContainer.new()
    safe.add_child(center)
    var panel: PanelContainer = PanelContainer.new()
    panel.name = "AscensionGoldPanel"
    var available: float = get_viewport().get_visible_rect().size.x
    panel.custom_minimum_size.x = minf(412.0, maxf(270.0, available - 34.0))
    var panel_style: StyleBoxFlat = StyleBoxFlat.new()
    panel_style.bg_color = Color("252820", 0.96)
    panel_style.border_color = Color("ddb76f", 0.94)
    panel_style.set_border_width_all(2)
    panel_style.set_corner_radius_all(24)
    panel_style.set_content_margin_all(19.0)
    panel_style.shadow_color = Color(0.04, 0.02, 0.01, 0.74)
    panel_style.shadow_size = 15
    panel.add_theme_stylebox_override("panel", panel_style)
    center.add_child(panel)

    var content: VBoxContainer = VBoxContainer.new()
    content.add_theme_constant_override("separation", 12)
    panel.add_child(content)
    _make_text(content, _copy("ZEN-AUFSTIEG", "ZEN ASCENSION", "ASCENSÃO ZEN", language), 20, Color("dfc391"))
    var art_frame: CenterContainer = CenterContainer.new()
    content.add_child(art_frame)
    var artwork: Control = Control.new()
    artwork.custom_minimum_size = Vector2(250.0, 246.0)
    art_frame.add_child(artwork)
    _golden_wave(artwork, 0.15)
    _golden_wave(artwork, 1.0)
    var gong: TextureRect = TextureRect.new()
    gong.name = "TempleGong"
    gong.texture = GONG_IMAGE
    gong.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    gong.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    gong.position = Vector2(25, 4)
    gong.size = Vector2(200, 200)
    gong.pivot_offset = Vector2(100, 100)
    gong.mouse_filter = Control.MOUSE_FILTER_IGNORE
    gong.scale = Vector2(0.80, 0.80)
    artwork.add_child(gong)
    var appear: Tween = create_tween()
    appear.tween_property(gong, "scale", Vector2.ONE, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

    _make_text(content, Locale.translate(str(Asc.RANKS[rank]), language), 30, Color("f8dfac"))
    _make_text(content, _copy("Dein innerer Frieden wächst.", "Your inner peace grows.", "A tua paz interior cresce.", language), 15, Color("e4d6b8"))
    if rank <= 4:
        var prefix: String = _copy("NEUE WELT", "NEW WORLD", "NOVO MUNDO", language)
        _make_text(content, prefix + "  ·  " + Locale.translate(str(Asc.WORLDS[rank]), language), 16, Color("cce4ba"))
    else:
        _make_text(content, _copy("Höchster Zen-Rang erreicht!", "Highest Zen rank reached!", "Atingiste o nível Zen máximo!", language), 16, Color("cce4ba"))
    if rank == 3:
        _make_text(content, _copy("ZEN ASCEND 4×4 FREIGESCHALTET", "ZEN ASCEND 4×4 UNLOCKED", "ZEN ASCEND 4×4 DESBLOQUEADO", language), 17, Color("f7cd73"))

    var skip_button: Button = Button.new()
    skip_button.name = "SkipCeremony"
    skip_button.text = _copy("Überspringen", "Skip", "Saltar", language)
    skip_button.custom_minimum_size.y = 48
    skip_button.add_theme_color_override("font_color", Color("fff2d3"))
    var skip_style: StyleBoxFlat = StyleBoxFlat.new()
    skip_style.bg_color = Color("536648", 0.95)
    skip_style.set_corner_radius_all(14)
    skip_style.set_content_margin_all(10.0)
    skip_button.add_theme_stylebox_override("normal", skip_style)
    content.add_child(skip_button)
    skip_button.pressed.connect(skip)
    _gong_player = AudioStreamPlayer.new()
    _gong_player.name = "ZenTempleGongSFX"
    _gong_player.stream = GONG_AUDIO
    _gong_player.volume_db = -5.0
    add_child(_gong_player)
    create_tween().tween_property(_overlay, "modulate:a", 1.0, 0.38)

func _duck_music(music_sources: Array) -> void:
    for source in music_sources:
        if source is AudioStreamPlayer and is_instance_valid(source) and source.playing:
            _music_levels.append({"player": source, "volume": source.volume_db})
            source.create_tween().tween_property(source, "volume_db", minf(-16.0, source.volume_db), 0.6)

func skip() -> void:
    if _closed:
        return
    _closed = true
    if is_instance_valid(_gong_player):
        _gong_player.stop()
    for state in _music_levels:
        var player: AudioStreamPlayer = state["player"] as AudioStreamPlayer
        if is_instance_valid(player):
            player.create_tween().tween_property(player, "volume_db", float(state["volume"]), 0.50)
    finished.emit()
    queue_free()
