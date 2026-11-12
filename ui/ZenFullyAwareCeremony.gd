class_name ZenFullyAwareCeremony
extends CanvasLayer
## The last 4x4 title celebrates once when the achievement first completes.
## The regular rank-up gong scene stays unchanged visually and acoustically.
signal finished
const BACKDROP = preload("res://assets/realms/satori_realm.webp")
const WAVE = preload("res://assets/effects/zen_golden_wave.png")
const GONG = preload("res://assets/audio/zen_temple_gong.wav")
const DISPLAY_SECONDS: float = 7.5
var _started: bool = false
var _closed: bool = false
var _overlay: Control
var _gong: AudioStreamPlayer
var _music_sources: Array = []

func _copy(lang: String, de: String, en: String, pt: String) -> String:
    if lang == "en": return en
    if lang == "pt": return pt
    return de

func _label(parent: Node, value: String, points: int, tint: Color) -> Label:
    var l: Label = Label.new()
    l.text = value
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size", points)
    l.add_theme_color_override("font_color", tint)
    parent.add_child(l)
    return l

func _wave(parent: Node, delay: float) -> void:
    var ripple: TextureRect = TextureRect.new()
    ripple.texture = WAVE
    ripple.position = Vector2(4, 0)
    ripple.size = Vector2(236, 236)
    ripple.pivot_offset = Vector2(118, 118)
    ripple.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    ripple.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    ripple.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ripple.modulate.a = 0.0
    ripple.scale = Vector2(0.38, 0.38)
    parent.add_child(ripple)
    var tw: Tween = create_tween().set_parallel(true)
    tw.tween_property(ripple, "scale", Vector2(1.85, 1.85), 2.7).set_delay(delay).set_trans(Tween.TRANS_SINE)
    tw.tween_property(ripple, "modulate:a", 0.83, 0.35).set_delay(delay)
    tw.tween_property(ripple, "modulate:a", 0.0, 1.9).set_delay(delay + 0.50)

func _sparkles(parent: Node) -> void:
    var bounds: Vector2 = get_viewport().get_visible_rect().size
    for i in range(30):
        var star: Label = Label.new()
        star.text = "✦" if i % 3 == 0 else "✧"
        star.add_theme_font_size_override("font_size", 15 + (i % 5) * 3)
        star.add_theme_color_override("font_color", Color("efdfaa") if i % 2 == 0 else Color("b8f6eb"))
        star.position = Vector2(bounds.x * (0.06 + float((i * 47) % 87) / 100.0), bounds.y * (0.63 + float(i % 6) / 23.0))
        star.modulate.a = 0.0
        star.mouse_filter = Control.MOUSE_FILTER_IGNORE
        parent.add_child(star)
        var drift: Tween = create_tween().set_parallel(true)
        var delay: float = float(i % 9) * 0.22
        var lifetime: float = 3.1 + float(i % 4) * 0.39
        drift.tween_property(star, "position:y", star.position.y - bounds.y * 0.65, lifetime).set_delay(delay).set_trans(Tween.TRANS_SINE)
        drift.tween_property(star, "modulate:a", 0.9, 0.45).set_delay(delay)
        drift.tween_property(star, "modulate:a", 0.0, 0.75).set_delay(delay + lifetime - 0.75)

func present(language: String, sound_on: bool, music_sources: Array) -> void:
    if _started: return
    _started = true
    layer = 22
    _music_sources = music_sources.duplicate()
    _overlay = Control.new()
    _overlay.name = "FullyAwareCeremony"
    _overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_overlay)
    _overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _overlay.modulate.a = 0.0

    var landscape: TextureRect = TextureRect.new()
    landscape.texture = BACKDROP
    landscape.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    landscape.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    landscape.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _overlay.add_child(landscape)
    landscape.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var dim: ColorRect = ColorRect.new()
    dim.color = Color("0e1c24", 0.72)
    dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _overlay.add_child(dim)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _sparkles(_overlay)

    var center: CenterContainer = CenterContainer.new()
    _overlay.add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var panel: PanelContainer = PanelContainer.new()
    panel.name = "SatoriCompletionPanel"
    panel.custom_minimum_size.x = minf(410.0, maxf(265.0, get_viewport().get_visible_rect().size.x - 34.0))
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color("192d32", 0.97)
    style.border_color = Color("f6d68a", 0.96)
    style.set_border_width_all(2)
    style.set_corner_radius_all(25)
    style.set_content_margin_all(18.0)
    style.shadow_color = Color(0.02, 0.08, 0.1, 0.82)
    style.shadow_size = 20
    panel.add_theme_stylebox_override("panel", style)
    center.add_child(panel)
    var content: VBoxContainer = VBoxContainer.new()
    content.add_theme_constant_override("separation", 10)
    panel.add_child(content)
    _label(content, _copy(language,"SATORI · VOLLENDUNG", "SATORI · ASCENSION", "SATORI · PLENITUDE"), 19, Color("d5ebde"))
    var art: CenterContainer = CenterContainer.new()
    content.add_child(art)
    var canvas: Control = Control.new()
    canvas.custom_minimum_size = Vector2(244, 236)
    art.add_child(canvas)
    for i in range(3): _wave(canvas, float(i) * 0.82)
    var lotus: Label = Label.new()
    lotus.text = "✧\n❀\n✧"
    lotus.position = Vector2(72, 42)
    lotus.add_theme_font_size_override("font_size", 49)
    lotus.add_theme_color_override("font_color", Color("f5e4aa"))
    lotus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    canvas.add_child(lotus)
    var halo: Tween = create_tween()
    lotus.modulate.a = 0.0
    halo.tween_property(lotus, "modulate:a", 1.0, 1.4)
    _label(content, "FULLY AWARE", 34, Color("fff0ba"))
    _label(content, _copy(language,"Du hast den höchsten Titel erreicht.", "You have reached the highest title.", "Alcançaste o título mais elevado."), 16, Color("dfeddf"))
    _label(content, _copy(language,"Vier Realms. Ein klarer Geist. Ein letzter Schritt zur Erleuchtung.","Four realms. One clear mind. A final step toward awakening.","Quatro reinos. Uma mente clara. Um último passo para o despertar."), 14, Color("c2dcd8"))
    var close_button: Button = Button.new()
    close_button.name = "SkipFullyAware"
    close_button.text = _copy(language, "Weiter", "Continue", "Continuar")
    close_button.custom_minimum_size.y = 50
    var button_style: StyleBoxFlat = StyleBoxFlat.new()
    button_style.bg_color = Color("526d61", 0.97)
    button_style.set_corner_radius_all(14)
    button_style.set_content_margin_all(12.0)
    close_button.add_theme_stylebox_override("normal", button_style)
    close_button.add_theme_color_override("font_color", Color("fff3d8"))
    content.add_child(close_button)
    close_button.pressed.connect(skip)

    for source in _music_sources:
        if source is AudioStreamPlayer and is_instance_valid(source) and source.playing:
            source.create_tween().tween_property(source, "volume_db", minf(-17.0, source.volume_db), 0.6)
    _gong = AudioStreamPlayer.new()
    _gong.stream = GONG
    _gong.volume_db = -6.0
    add_child(_gong)
    if sound_on: _gong.play()
    create_tween().tween_property(_overlay, "modulate:a", 1.0, 0.5)
    get_tree().create_timer(DISPLAY_SECONDS).timeout.connect(skip)

func skip() -> void:
    if _closed: return
    _closed = true
    if is_instance_valid(_gong): _gong.stop()
    for source in _music_sources:
        if source is AudioStreamPlayer and is_instance_valid(source) and source.playing:
            source.create_tween().tween_property(source, "volume_db", -2.0, 0.55)
    finished.emit()
    queue_free()
