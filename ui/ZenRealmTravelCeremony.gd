class_name ZenRealmTravelCeremony
extends CanvasLayer
# Standalone two-world portal sequence; achievements keep their own choir.
signal finished
const PORTAL_SOUND = preload("res://assets/audio/zen_realm_breakthrough.wav")
const MIRROR_SOUND = preload("res://assets/audio/zen_mirror_shatter.wav")
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
# Physical mirror shatter: UV-mapped polygons carry the previous Realm
# artwork away as broken glass. No fracture is used during normal world travel.
class GlassCrackWeb:
    extends Control
    func _draw() -> void:
        if size.x <= 1.0 or size.y <= 1.0: return
        var origin: Vector2 = size*Vector2(0.49,0.46)
        var reach: float = size.length()*0.68
        for ray in range(26):
            var a: float = TAU*float(ray)/26.0 + sin(float(ray)*8.23)*0.07
            var forward: Vector2 = Vector2(cos(a),sin(a))
            var side: Vector2 = Vector2(-forward.y,forward.x)
            var line: PackedVector2Array = PackedVector2Array([origin])
            for step in range(1,8):
                var f: float = float(step)/7.0
                line.append(origin+forward*reach*f+side*sin(float(ray*19+step*31))*12.0*f)
            draw_polyline(line,Color(0.91,0.97,1.0,0.9),1.8,true)
            for split in [2,4,6]:
                var direction: float = -0.75 if (ray+split)%2 == 0 else 0.75
                draw_line(line[split],line[split]+forward.rotated(direction)*reach*0.10,
                    Color(0.83,0.94,1.0,0.65),1.0,true)
        draw_arc(origin,18.0,0.0,TAU,28,Color(1.0,1.0,1.0,0.90),2.5,true)
        draw_arc(origin,39.0,0.0,TAU,32,Color(0.9,0.97,1.0,0.65),1.6,true)

class MirrorGlassShatter:
    extends Control
    var break_progress: float = 0.0:
        set(value):
            break_progress = clampf(value,0.0,1.0)
            _update_shards()
    var crack_strength: float = 0.0:
        set(value):
            crack_strength = clampf(value,0.0,1.0)
            _update_shards()
    var pieces: Array = []
    var crack_web: GlassCrackWeb
    var center: Vector2 = Vector2.ZERO

    # Convex Voronoi half-plane clipping gives a seamless unbroken mirror.
    static func _clip_cell(poly: PackedVector2Array, site: Vector2, other: Vector2) -> PackedVector2Array:
        var output: PackedVector2Array = PackedVector2Array()
        if poly.is_empty(): return output
        var boundary: Vector2 = (site+other)*0.5
        var normal: Vector2 = other-site
        var prev: Vector2 = poly[poly.size()-1]
        var before: float = (prev-boundary).dot(normal)
        for point in poly:
            var after: float = (point-boundary).dot(normal)
            if (before <= 0.0) != (after <= 0.0):
                var divisor: float = before-after
                if absf(divisor) > 0.0001:
                    output.append(prev.lerp(point,before/divisor))
            if after <= 0.0: output.append(point)
            prev = point
            before = after
        return output

    func build_glass(texture: Texture2D, dimensions: Vector2) -> void:
        size = dimensions
        center = dimensions*Vector2(0.49,0.46)
        if texture == null or dimensions.x < 2.0 or dimensions.y < 2.0: return
        var rng: RandomNumberGenerator = RandomNumberGenerator.new()
        rng.seed = 20261116
        var sites: Array[Vector2] = []
        for y in range(9):
            for x in range(6):
                sites.append(Vector2((float(x)+0.5+rng.randf_range(-0.30,0.30))*dimensions.x/6.0,
                    (float(y)+0.5+rng.randf_range(-0.30,0.30))*dimensions.y/9.0))
        for i in range(20):
            var angle: float = TAU*float(i)/20.0 + rng.randf_range(-0.09,0.09)
            var radius: float = minf(dimensions.x,dimensions.y)*rng.randf_range(0.035,0.22)
            sites.append(center+Vector2(cos(angle),sin(angle))*radius)
        var texture_size: Vector2 = texture.get_size()
        var scale_to_cover: float = maxf(dimensions.x/texture_size.x,dimensions.y/texture_size.y)
        var image_offset: Vector2 = (dimensions-texture_size*scale_to_cover)*0.5
        var rectangle: PackedVector2Array = PackedVector2Array([
            Vector2.ZERO,Vector2(dimensions.x,0.0),dimensions,Vector2(0.0,dimensions.y)])
        for i in range(sites.size()):
            var polygon: PackedVector2Array = rectangle.duplicate()
            for j in range(sites.size()):
                if i == j: continue
                polygon = _clip_cell(polygon,sites[i],sites[j])
                if polygon.size() < 3: break
            if polygon.size() < 3: continue
            var midpoint: Vector2 = Vector2.ZERO
            for point in polygon: midpoint += point
            midpoint /= float(polygon.size())
            var local_polygon: PackedVector2Array = PackedVector2Array()
            var uv: PackedVector2Array = PackedVector2Array()
            for point in polygon:
                local_polygon.append(point-midpoint)
                uv.append((point-image_offset)/scale_to_cover)
            var shard: Polygon2D = Polygon2D.new()
            shard.name = "MirrorGlassShard_%02d" % pieces.size()
            shard.texture = texture
            shard.polygon = local_polygon
            shard.uv = uv
            shard.position = midpoint
            shard.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
            add_child(shard)
            var outline: Line2D = Line2D.new()
            outline.points = local_polygon
            outline.add_point(local_polygon[0])
            outline.width = 1.7
            outline.default_color = Color(0.92,0.98,1.0,0.90)
            outline.antialiased = true
            outline.modulate.a = 0.0
            shard.add_child(outline)
            var away: Vector2 = (midpoint-center).normalized()
            if away.length_squared() < 0.01: away = Vector2.UP
            away = away.rotated(rng.randf_range(-0.35,0.35))
            pieces.append({"node":shard,"edge":outline,"origin":midpoint,
                "direction":away,"travel":rng.randf_range(210.0,530.0),
                "spin":rng.randf_range(-2.7,2.7),
                "delay":clampf(midpoint.distance_to(center)/dimensions.length()*0.20,0.0,0.20)})
        crack_web = GlassCrackWeb.new()
        crack_web.name = "MirrorImpactSpiderweb"
        crack_web.mouse_filter = Control.MOUSE_FILTER_IGNORE
        crack_web.size = dimensions
        crack_web.modulate.a = 0.0
        add_child(crack_web)
        _update_shards()

    func _update_shards() -> void:
        if is_instance_valid(crack_web):
            crack_web.modulate.a = crack_strength*(1.0-break_progress)
        for item in pieces:
            var shard: Polygon2D = item["node"] as Polygon2D
            var outline: Line2D = item["edge"] as Line2D
            var lag: float = float(item["delay"])
            var p: float = clampf((break_progress-lag)/(1.0-lag),0.0,1.0)
            var eased: float = p*p*(3.0-2.0*p)
            shard.position = (item["origin"] as Vector2)+(item["direction"] as Vector2)*float(item["travel"])*eased+Vector2(0.0,330.0)*p*p
            shard.rotation = float(item["spin"])*eased
            shard.scale = Vector2.ONE*(1.0-0.07*p)
            shard.modulate.a = clampf((1.0-p)*2.0,0.0,1.0)
            outline.modulate.a = crack_strength*(1.0-p)*0.90

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
    var duration: float = 4.7 if breakthrough else 2.4
    _backdrop = Control.new()
    _backdrop.name = "ZenRealmPortalTransition"
    _backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_backdrop)
    _backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    if breakthrough:
        # Old Realm artwork is the mirror itself. Each UV-mapped polygon flies
        # away to reveal the NEW Realm already rendered behind it.
        _full_image(_backdrop,destination_art)
        var previous_texture: Texture2D = load(previous_art) as Texture2D
        var glass: MirrorGlassShatter = MirrorGlassShatter.new()
        glass.name = "EpicRealmScreenFracture"
        glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _backdrop.add_child(glass)
        glass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        glass.build_glass(previous_texture,get_viewport().get_visible_rect().size)
        var impact: Tween = glass.create_tween()
        impact.tween_interval(0.38)
        impact.tween_property(glass,"crack_strength",1.0,0.26).set_trans(Tween.TRANS_CUBIC)
        impact.tween_interval(0.12)
        impact.tween_property(glass,"break_progress",1.0,1.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
        var flash: ColorRect = ColorRect.new()
        flash.name = "MirrorShatterImpactFlash"
        flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
        flash.color = Color(0.89,0.97,1.0,0.0)
        _backdrop.add_child(flash)
        flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        var burst: Tween = flash.create_tween()
        burst.tween_interval(0.37)
        burst.tween_property(flash,"color:a",0.76,0.08)
        burst.tween_property(flash,"color:a",0.0,0.52).set_trans(Tween.TRANS_CUBIC)
    else:
        # Routine movement keeps its calm, existing circular portal.
        _full_image(_backdrop,previous_art)
        var revealed: TextureRect = _full_image(_backdrop,destination_art)
        var shader: Shader = Shader.new()
        shader.code = PORTAL_SHADER
        var material: ShaderMaterial = ShaderMaterial.new()
        material.shader = shader
        material.set_shader_parameter("reveal",0.0)
        revealed.material = material
        create_tween().tween_property(material,"shader_parameter/reveal",1.0,1.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

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
    ripple.tween_interval(1.20 if breakthrough else 0.0)
    ripple.tween_property(halo, "modulate:a", 0.32 if breakthrough else 0.22, 0.4)
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
    text_tween.tween_interval(2.10 if breakthrough else 0.2)
    text_tween.tween_property(frame, "modulate:a", 1.0, 0.55)

    _player = AudioStreamPlayer.new()
    _player.stream = MIRROR_SOUND if breakthrough else PORTAL_SOUND
    _player.volume_db = -5.0 if breakthrough else -15.0
    add_child(_player)
    for source in music_sources:
        if source is AudioStreamPlayer and is_instance_valid(source) and source.playing:
            _music_levels.append({"source":source,"volume":source.volume_db})
            source.create_tween().tween_property(source, "volume_db", -22.0, 0.36)
    if sound_enabled:
        if breakthrough:
            get_tree().create_timer(0.38).timeout.connect(func():
                if is_instance_valid(_player): _player.play())
        else:
            _player.play()
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
