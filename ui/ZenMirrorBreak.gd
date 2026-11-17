extends Control
# Self-contained animated mirror fracture. No external art or plugins.
signal fracture_finished
var elapsed: float = 0.0
var duration: float = 3.1
var running: bool = false
var shards: Array = []
var particles: Array = []
var headline: Label
var subtitle: Label
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    visible = false
    rng.seed = 20261117
    _build_text()
    set_process(false)

func _build_text() -> void:
    var group: VBoxContainer = VBoxContainer.new()
    group.set_anchors_preset(Control.PRESET_CENTER_TOP)
    group.anchor_left = 0.06
    group.anchor_right = 0.94
    group.offset_top = 112
    group.offset_bottom = 290
    group.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(group)
    headline = Label.new()
    headline.text = "Enlightenment was never the end.\nIt was the beginning."
    headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    headline.add_theme_font_size_override("font_size", 25)
    headline.add_theme_color_override("font_color", Color("fff3c9"))
    group.add_child(headline)
    subtitle = Label.new()
    subtitle.text = "ZEN MASTER AWAKENS"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 18)
    subtitle.add_theme_color_override("font_color", Color("edd2a1"))
    group.add_child(subtitle)
    headline.modulate.a = 0.0
    subtitle.modulate.a = 0.0

func begin() -> void:
    if running:
        return
    elapsed = 0.0
    running = true
    visible = true
    headline.modulate.a = 0.0
    subtitle.modulate.a = 0.0
    _generate_shards()
    set_process(true)
    if OS.get_name() == "Android":
        Input.vibrate_handheld(115)

func _generate_shards() -> void:
    shards.clear()
    particles.clear()
    var mid: Vector2 = get_viewport_rect().size * Vector2(0.5, 0.53)
    var span: float = minf(get_viewport_rect().size.x * 0.39, 270.0)
    # Triangulated irregular mirror glass, with persistent randomly oriented trajectories.
    for row in range(7):
        for col in range(7):
            var x: float = float(col - 3) / 3.0
            var y: float = float(row - 3) / 3.0
            var origin: Vector2 = mid + Vector2(x * span, y * span * 0.74)
            var jitter: Vector2 = Vector2(rng.randf_range(-13,13),rng.randf_range(-13,13))
            var a: Vector2 = origin + jitter
            var angle: float = rng.randf_range(-PI,PI)
            var radius: float = rng.randf_range(20,40)
            var vertices: PackedVector2Array = PackedVector2Array([
                a + Vector2(cos(angle),sin(angle))*radius,
                a + Vector2(cos(angle+2.1),sin(angle+2.1))*radius,
                a + Vector2(cos(angle+4.2),sin(angle+4.2))*radius
            ])
            var direction: Vector2 = (a-mid).normalized()
            if direction.length_squared() < 0.1:
                direction = Vector2(cos(angle),sin(angle))
            var speed: float = rng.randf_range(58.0,210.0)
            shards.append({"points":vertices, "direction":direction,"speed":speed,"spin":rng.randf_range(-2.7,2.7),"center":a,"tint":rng.randf_range(0.0,1.0)})
    for i in range(85):
        particles.append({"angle":rng.randf_range(-PI,PI),"dist":rng.randf_range(0.0,150.0),"speed":rng.randf_range(25.0,200.0),"size":rng.randf_range(0.7,3.7)})

func _process(delta: float) -> void:
    if not running:
        return
    elapsed += delta
    var p: float = clampf(elapsed/duration, 0.0, 1.0)
    # Delay the quote until the glass has shattered.
    headline.modulate.a = clampf((p-0.27)*4.0,0.0,1.0)
    subtitle.modulate.a = clampf((p-0.52)*4.0,0.0,1.0)
    queue_redraw()
    if p >= 1.0:
        running = false
        set_process(false)
        fracture_finished.emit()

func _draw() -> void:
    if not running:
        return
    var area: Vector2 = size
    var center: Vector2 = area * Vector2(0.5, 0.53)
    var p: float = clampf(elapsed/duration,0.0,1.0)
    draw_rect(Rect2(Vector2.ZERO,area),Color(0.06,0.035,0.09,clampf(p*1.6,0.0,0.83)))
    var flash: float = pow(maxf(0.0,1.0-absf(p-0.21)*7.0),2.0)
    if flash > 0.001:
        draw_rect(Rect2(Vector2.ZERO,area),Color(1,0.88,0.65,flash*0.56))
    var flight: float = maxf(0.0,p-0.18)*1.5
    var alpha: float = (1.0-clampf((p-0.58)*2.15,0.0,1.0))
    for item in shards:
        var origin: Vector2 = item.center
        var direction: Vector2 = item.direction
        var offset: Vector2 = direction * float(item.speed) * flight
        var spin: float = float(item.spin) * flight
        var points: PackedVector2Array = PackedVector2Array()
        for point in item.points:
            points.append(origin+(point-origin).rotated(spin)+offset)
        var t: float = float(item.tint)
        draw_colored_polygon(points,Color(0.65+0.3*t,0.69+0.22*t,0.84+0.16*t,alpha*0.32))
        for j in range(points.size()):
            draw_line(points[j],points[(j+1)%points.size()],Color(1.0,0.86,0.63,alpha*0.9),1.5)
    for item in particles:
        var angle: float = item.angle
        var radial: float = float(item.dist)+p*float(item.speed)
        var pos: Vector2 = center+Vector2(cos(angle),sin(angle))*radial
        draw_circle(pos,item.size,Color(1.0,0.86,0.59,alpha*0.88))
