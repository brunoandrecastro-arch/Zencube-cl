class_name ZenUnlockCeremony
extends CanvasLayer
# Reusable full-screen in-game ceremony. Choir for achievements and titles;
# a distinct cinematic sound for first-time Realm breakthroughs.
signal finished
const CHOIR = preload("res://assets/audio/zen_achievement_choir.wav")
const PORTAL = preload("res://assets/audio/zen_realm_breakthrough.wav")
const GOLDEN_WAVE = preload("res://assets/effects/zen_golden_wave.png")
const DURATION: float = 4.3
var _closed: bool = false
var _root: Control
var _player: AudioStreamPlayer
var _music_sources: Array = []

func _text(parent: Node, value: String, points: int, tint: Color) -> Label:
    var l: Label = Label.new()
    l.text = value
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size",points)
    l.add_theme_color_override("font_color",tint)
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(l)
    return l

func present(kind: String, picture: String, title: String, quote: String, sound_on: bool, songs: Array) -> void:
    layer = 25
    _music_sources = songs.duplicate()
    _root = Control.new()
    _root.name = "ZenUnlockCeremonyOverlay"
    _root.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_root)
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _root.modulate.a = 0.0
    var image: TextureRect = TextureRect.new()
    image.texture = load(picture)
    image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.add_child(image)
    image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var shade: ColorRect = ColorRect.new()
    shade.color = Color("071e1d",0.60) if kind == "realm" else Color("101a25",0.72)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.add_child(shade)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    # A soft golden shockwave and brief reveal flash make an achievement feel earned.
    var halo: TextureRect = TextureRect.new()
    halo.texture = GOLDEN_WAVE
    halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    halo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    halo.modulate = Color(1.0,0.87,0.58,0.0)
    halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.add_child(halo)
    halo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var halo_tween: Tween = halo.create_tween()
    halo_tween.tween_property(halo,"modulate:a",0.57,0.65)
    halo_tween.tween_property(halo,"modulate:a",0.0,1.45)
    var flash: ColorRect = ColorRect.new()
    flash.color = Color(1.0,0.92,0.72,0.23 if kind == "realm" else 0.10)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _root.add_child(flash)
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    flash.create_tween().tween_property(flash,"color:a",0.0,1.1)
    var column: VBoxContainer = VBoxContainer.new()
    column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    column.anchor_left = 0.07
    column.anchor_right = 0.93
    column.anchor_top = 0.30
    column.anchor_bottom = 0.75
    column.add_theme_constant_override("separation",22)
    column.alignment = BoxContainer.ALIGNMENT_CENTER
    _root.add_child(column)
    _text(column,"✦   NEW REALM UNLOCKED   ✦" if kind == "realm" else "✦   ACHIEVEMENT UNLOCKED   ✦",20,Color("f6e7b6"))
    var title_label: Label = _text(column,title,32,Color("fff2cf"))
    title_label.pivot_offset = Vector2(0,24)
    title_label.scale = Vector2(0.92,0.92)
    _text(column,quote,17,Color("e0e8dc"))
    var skip: Button = Button.new()
    skip.text = "Continue ›"
    skip.custom_minimum_size = Vector2(130,52)
    skip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    var normal: StyleBoxFlat = StyleBoxFlat.new()
    normal.bg_color = Color("1d3933",0.94)
    normal.border_color = Color("e3be7b")
    normal.set_corner_radius_all(15)
    normal.set_border_width_all(2)
    skip.add_theme_stylebox_override("normal",normal)
    skip.add_theme_color_override("font_color",Color("f7e9bf"))
    skip.pressed.connect(close)
    column.add_child(skip)
    _player = AudioStreamPlayer.new()
    _player.stream = PORTAL if kind == "realm" else CHOIR
    _player.volume_db = -7.0
    add_child(_player)
    for source in _music_sources:
        if source is AudioStreamPlayer and is_instance_valid(source) and source.playing:
            source.create_tween().tween_property(source,"volume_db",-20.0,0.4)
    if sound_on: _player.play()
    _root.create_tween().tween_property(_root,"modulate:a",1.0,0.45)
    _root.create_tween().tween_property(title_label,"scale",Vector2.ONE,1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    get_tree().create_timer(DURATION).timeout.connect(close)

func close() -> void:
    if _closed: return
    _closed = true
    if is_instance_valid(_player): _player.stop()
    for source in _music_sources:
        if source is AudioStreamPlayer and is_instance_valid(source) and source.playing:
            source.create_tween().tween_property(source,"volume_db",-2.0,0.55)
    finished.emit()
    queue_free()
