class_name ZenRealmTravelCeremony
extends CanvasLayer
# Standalone two-world portal sequence; achievements keep their own choir.
signal finished
const PORTAL_SOUND = preload("res://assets/audio/zen_realm_breakthrough.wav")
const GOLDEN_WAVE = preload("res://assets/effects/zen_golden_wave.png")
const PORTAL_SHADER: String = """
shader_type canvas_item;
render_mode unshaded;
uniform float reveal : hint_range(0.0, 1.0) = 0.0;
void fragment() {
    vec4 scene = texture(TEXTURE, UV);
    vec2 centered = (UV - vec2(0.5)) * vec2(0.80, 1.0);
    float distance_to_center = length(centered);
    float radius = mix(-0.035, 0.76, reveal);
    float distance_to_ring = distance_to_center - radius;
    float alpha = 1.0 - smoothstep(-0.024, 0.030, distance_to_ring);
    float glow = exp(-pow(distance_to_ring / 0.028, 2.0)) * (1.0 - reveal * 0.55);
    scene.rgb = mix(scene.rgb, vec3(1.0, 0.84, 0.56), min(0.78, glow * 0.75));
    scene.a *= alpha;
    COLOR = scene;
}
"""
var _closed: bool = false
var _backdrop: Control
var _player: AudioStreamPlayer
var _music_levels: Array = []

func _full_image(parent: Control, texture_path: String) -> TextureRect:
    var image: TextureRect = TextureRect.new()
    image.texture = load(texture_path)
    image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(image)
    image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    return image

func _caption(parent: Control, words: String, size: int, tint: Color) -> Label:
    var result: Label = Label.new()
    result.text = words
    result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    result.add_theme_font_size_override("font_size", size)
    result.add_theme_color_override("font_color", tint)
    result.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(result)
    return result

func present(previous_art: String, destination_art: String, destination_name: String,
        breakthrough: bool, sound_enabled: bool, music_sources: Array, language: String = "en") -> void:
    layer = 27
    var duration: float = 4.5 if breakthrough else 2.4
    _backdrop = Control.new()
    _backdrop.name = "ZenRealmPortalTransition"
    _backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_backdrop)
    _backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    # The previous world stays visible while a circular doorway reveals the next.
    _full_image(_backdrop, previous_art)
    var revealed: TextureRect = _full_image(_backdrop, destination_art)
    var shader: Shader = Shader.new()
    shader.code = PORTAL_SHADER
    var material: ShaderMaterial = ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("reveal", 0.0)
    revealed.material = material
    var transition: Tween = create_tween()
    transition.tween_property(material, "shader_parameter/reveal", 1.0, 3.1 if breakthrough else 1.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

    # A warm gold ripple adds depth without covering the Realm artwork.
    var halo: TextureRect = TextureRect.new()
    halo.texture = GOLDEN_WAVE
    halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    halo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    halo.modulate = Color(1.0, 0.85, 0.56, 0.0)
    _backdrop.add_child(halo)
    halo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var ripple: Tween = halo.create_tween()
    ripple.tween_property(halo, "modulate:a", 0.47 if breakthrough else 0.22, 0.4)
    ripple.tween_property(halo, "modulate:a", 0.0, duration - 0.55)

    var veil: ColorRect = ColorRect.new()
    veil.color = Color(0.03, 0.09, 0.11, 0.22)
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _backdrop.add_child(veil)
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var frame: PanelContainer = PanelContainer.new()
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.08, 0.17, 0.18, 0.89)
    style.border_color = Color(0.86, 0.71, 0.45, 0.94)
    style.set_border_width_all(2)
    style.set_corner_radius_all(24)
    frame.add_theme_stylebox_override("panel", style)
    _backdrop.add_child(frame)
    frame.anchor_left = 0.07
    frame.anchor_right = 0.93
    frame.anchor_top = 0.35
    frame.anchor_bottom = 0.66
    frame.modulate.a = 0.0
    var stack: VBoxContainer = VBoxContainer.new()
    stack.alignment = BoxContainer.ALIGNMENT_CENTER
    stack.add_theme_constant_override("separation", 18)
    frame.add_child(stack)
    var heading: String = "NEW REALM UNLOCKED" if breakthrough else "ENTERING REALM"
    if language == "de": heading = "NEUES REICH FREIGESCHALTET" if breakthrough else "REICHWECHSEL"
    if language == "pt": heading = "NOVO REINO DESBLOQUEADO" if breakthrough else "A ENTRAR NO REINO"
    _caption(stack, "✦  " + heading + "  ✦", 17, Color("ffe6b1"))
    _caption(stack, destination_name, 29, Color("fff4d5"))
    if breakthrough:
        var subtitle: String = "A new path begins." if language == "en" else ("Ein neuer Weg beginnt." if language == "de" else "Começa um novo caminho.")
        _caption(stack, subtitle, 15, Color("cfdfd4"))
    var continue_button: Button = Button.new()
    continue_button.text = "Continue ›" if language == "en" else ("Weiter ›" if language == "de" else "Continuar ›")
    continue_button.custom_minimum_size = Vector2(160, 48)
    continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    continue_button.pressed.connect(close)
    stack.add_child(continue_button)
    var text_tween: Tween = frame.create_tween()
    text_tween.tween_interval(0.45 if breakthrough else 0.2)
    text_tween.tween_property(frame, "modulate:a", 1.0, 0.55)

    _player = AudioStreamPlayer.new()
    _player.stream = PORTAL_SOUND
    _player.volume_db = -8.5 if breakthrough else -15.0
    add_child(_player)
    for source in music_sources:
        if source is AudioStreamPlayer and is_instance_valid(source) and source.playing:
            _music_levels.append({"source":source,"volume":source.volume_db})
            source.create_tween().tween_property(source, "volume_db", -22.0, 0.36)
    if sound_enabled: _player.play()
    get_tree().create_timer(duration).timeout.connect(close)

func close() -> void:
    if _closed: return
    _closed = true
    if is_instance_valid(_player): _player.stop()
    for entry in _music_levels:
        var source: AudioStreamPlayer = entry.source
        if is_instance_valid(source) and source.playing:
            source.create_tween().tween_property(source, "volume_db", float(entry.volume), 0.55)
    finished.emit()
    queue_free()
