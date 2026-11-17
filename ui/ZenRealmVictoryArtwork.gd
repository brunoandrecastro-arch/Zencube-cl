class_name ZenRealmVictoryArtwork
extends PanelContainer
## One unique Kuze-versus-defeated-boss cinematic composite per encounter.
## Uses high-quality, *existing approved* Kuze and individual boss artwork,
## not the simple placeholder SVGs. All compositing is in Godot on-device.
const Story = preload("res://story/ZenRealmChronicles.gd")
const KUZE_ART := preload("res://assets/zen_campaign/zen_campaign_first_demon.webp")
const IMAGE_MAT := """
shader_type canvas_item;
render_mode unshaded;
uniform float hero_side = 1.0;
uniform vec4 realm_tint : source_color = vec4(0.76, 0.72, 0.98, 1.0);
void fragment() {
    vec4 ink = texture(TEXTURE, UV);
    float left_fade = 1.0 - smoothstep(0.38, 0.67, UV.x);
    float right_fade = smoothstep(0.27, 0.63, UV.x);
    ink.a *= mix(right_fade, left_fade, hero_side);
    ink.rgb = mix(ink.rgb, ink.rgb * realm_tint.rgb, 0.22);
    COLOR = ink;
}
"""
const REALM_TONES: Array[Color] = [
    Color("#a6adff"), Color("#ffab73"), Color("#c2e9ff"), Color("#ffe7a7")
]
var stage_id: int = -1

func _make_full_image(parent: Control, texture: Texture2D, hero_side: bool, tint: Color) -> TextureRect:
    var image: TextureRect = TextureRect.new()
    image.texture = texture
    image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var shader: Shader = Shader.new()
    shader.code = IMAGE_MAT
    var material: ShaderMaterial = ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("hero_side", 1.0 if hero_side else 0.0)
    material.set_shader_parameter("realm_tint",tint)
    image.material = material
    parent.add_child(image)
    image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    return image

func present(stage: int, language: String = "de") -> void:
    stage_id = clampi(stage,0,Story.LAST_STAGE-1)
    name = "ZenRealmVictoryArt_%02d" % stage_id
    custom_minimum_size = Vector2(0,245)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    var chapter: int = Story.chapter(stage_id)
    var tone: Color = REALM_TONES[chapter]
    var panel: StyleBoxFlat = StyleBoxFlat.new()
    panel.bg_color = Color("#131e27")
    panel.border_color = tone.darkened(0.12)
    panel.set_border_width_all(2)
    panel.set_corner_radius_all(14)
    add_theme_stylebox_override("panel",panel)

    var frame: Control = Control.new()
    frame.name = "CinematicVictoryFrame"
    frame.custom_minimum_size.y = 235
    frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    frame.clip_contents = true
    add_child(frame)
    var backdrop: TextureRect = TextureRect.new()
    backdrop.texture = load(Story.CHAPTER_ART[chapter]) as Texture2D
    backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    backdrop.modulate = Color(0.52,0.56,0.65,0.85)
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    frame.add_child(backdrop)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var boss_art: Texture2D = Story.boss_texture(stage_id)
    # The two portraits merge into a single picture with soft side blending.
    # Kuze is visible on the left; his defeated rival on the right.
    _make_full_image(frame,KUZE_ART,true,tone)
    if boss_art != null:
        var defeated: TextureRect = _make_full_image(frame,boss_art,false,tone)
        defeated.name = "DefeatedBoss_%02d" % stage_id
        defeated.modulate = Color(0.87,0.84,0.79,0.87)
    var shade: ColorRect = ColorRect.new()
    shade.color = Color(0.02,0.05,0.08,0.15)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    frame.add_child(shade)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var crown: Label = Label.new()
    crown.text = "✦  " + Story.text_for(language,"boss_%d" % stage_id).to_upper()
    crown.add_theme_font_size_override("font_size",17)
    crown.add_theme_color_override("font_color",Color("#fff1cc"))
    crown.add_theme_color_override("font_shadow_color",Color(0,0,0,1))
    crown.add_theme_constant_override("shadow_offset_x",1)
    crown.add_theme_constant_override("shadow_offset_y",2)
    crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
    frame.add_child(crown)
    crown.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    crown.offset_left = 10
    crown.offset_right = -10
    crown.offset_top = -34
    crown.offset_bottom = -3
