extends Control
# Crisp ice/window-glass fracture: spiderweb cracks, translucent plates and falling glass.
# Only used by the isolated Satori -> Void QA build.
signal fracture_finished
var elapsed: float = 0.0
var duration: float = 3.7
var running: bool = false
var shard_data: Array = []
var crack_paths: Array = []
var frost_specks: Array = []
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
    group.anchor_left = 0.05
    group.anchor_right = 0.95
    group.anchor_top = 0.1
    group.anchor_bottom = 0.1
    group.offset_top = 0
    group.offset_bottom = 150
    group.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(group)
    headline = Label.new()
    headline.text = "Enlightenment was never the end.\nIt was the beginning."
    headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    headline.add_theme_font_size_override("font_size", 25)
    headline.add_theme_color_override("font_color", Color("e4f7ff"))
    group.add_child(headline)
    subtitle = Label.new()
    subtitle.text = "ZEN MASTER AWAKENS"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 18)
    subtitle.add_theme_color_override("font_color", Color("c2e7ff"))
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
    _generate_fracture()
    set_process(true)
    if OS.get_name() == "Android":
        Input.vibrate_handheld(100)

func _generate_fracture() -> void:
    shard_data.clear()
    crack_paths.clear()
    frost_specks.clear()
    var bounds: Vector2 = get_viewport_rect().size
    var middle: Vector2 = bounds * Vector2(0.5, 0.52)
    var rad: float = minf(bounds.x * 0.56, 305.0)
    # Rigid window shards emerge from consecutive radial cracks and branching
    # fracture rings; these are transparent triangles, not fantasy explosions.
    var spokes: int = 17
    for i in range(spokes):
        var angle: float = (TAU * float(i) / float(spokes)) + rng.randf_range(-0.10,0.10)
        var unit: Vector2 = Vector2(cos(angle), sin(angle))
        var points: PackedVector2Array = PackedVector2Array([middle])
        for layer in range(1, 6):
            var radius: float = rad * float(layer) / 5.0
            var offset: Vector2 = unit * radius
            offset += unit.orthogonal() * rng.randf_range(-12.0,12.0)
            points.append(middle + offset)
        crack_paths.append(points)
    for ring in range(1, 5):
        for i in range(spokes):
            var a: Vector2 = crack_paths[i][ring]
            var b: Vector2 = crack_paths[(i+1)%spokes][ring]
            var midpoint: Vector2 = (a+b)*0.5 + (a-b).orthogonal()*rng.randf_range(-0.14,0.14)
            crack_paths.append(PackedVector2Array([a,midpoint,b]))
    # Build translucent ice plate triangles from the adjacent radial sectors.
    for i in range(spokes):
        var next_i: int = (i+1)%spokes
        for ring in range(1,5):
            var inner_a: Vector2 = crack_paths[i][ring-1]
            var inner_b: Vector2 = crack_paths[next_i][ring-1]
            var outer_a: Vector2 = crack_paths[i][ring]
            var outer_b: Vector2 = crack_paths[next_i][ring]
            var center: Vector2 = (inner_a+inner_b+outer_a+outer_b)*0.25
            var direction: Vector2 = (center-middle).normalized()
            shard_data.append({"points":PackedVector2Array([inner_a,outer_a,outer_b]),
                "center":center,"direction":direction,"speed":rng.randf_range(55.0,180.0),
                "rotation":rng.randf_range(-1.5,1.5),"alpha":rng.randf_range(0.22,0.44)})
            if ring > 1:
                shard_data.append({"points":PackedVector2Array([inner_a,outer_b,inner_b]),
                    "center":center,"direction":direction,"speed":rng.randf_range(65.0,175.0),
                    "rotation":rng.randf_range(-1.3,1.3),"alpha":rng.randf_range(0.2,0.4)})
    for i in range(64):
        frost_specks.append({"angle":rng.randf_range(-PI,PI),"distance":rng.randf_range(12.0,rad),
            "speed":rng.randf_range(20.0,110.0),"size":rng.randf_range(0.6,2.3)})

func _process(delta: float) -> void:
    if not running:
        return
    elapsed += delta
    var progress: float = clampf(elapsed / duration, 0.0, 1.0)
    headline.modulate.a = clampf((progress-0.39)*4.0,0.0,1.0)
    subtitle.modulate.a = clampf((progress-0.59)*4.0,0.0,1.0)
    queue_redraw()
    if progress >= 1.0:
        running = false
        set_process(false)
        fracture_finished.emit()

func _draw() -> void:
    if not running:
        return
    var progress: float = clampf(elapsed/duration,0.0,1.0)
    var middle: Vector2 = size * Vector2(0.5,0.52)
    draw_rect(Rect2(Vector2.ZERO,size),Color(0.035,0.065,0.10,0.08 + progress*0.75))
    # Three successive phases: etched ice cracks -> sharp snap -> falling plates.
    var crack_phase: float = clampf(progress*4.6,0.0,1.0)
    var glass_alpha: float = 1.0-clampf((progress-0.70)*3.2,0.0,1.0)
    if progress < 0.44:
        for path in crack_paths:
            for j in range(path.size()-1):
                var segment_progress: float = float(j)/float(maxi(1,path.size()-1))
                if segment_progress > crack_phase:
                    break
                draw_line(path[j],path[j+1],Color(0.17,0.42,0.60,0.62),4.0)
                draw_line(path[j],path[j+1],Color(0.91,0.98,1.0,0.96),1.4)
    var snap: float = maxf(0.0,1.0-absf(progress-0.29)*18.0)
    if snap > 0:
        draw_rect(Rect2(Vector2.ZERO,size),Color(0.88,0.97,1.0,snap*0.50))
    if progress >= 0.29:
        var flight: float = clampf((progress-0.29)*1.85,0.0,1.0)
        for item in shard_data:
            var ctr: Vector2 = item.center
            var shift: Vector2 = item.direction*float(item.speed)*flight+Vector2(0,flight*flight*120.0)
            var points: PackedVector2Array = PackedVector2Array()
            for point in item.points:
                points.append(ctr+(point-ctr).rotated(float(item.rotation)*flight)+shift)
            draw_colored_polygon(points,Color(0.66,0.89,1.0,float(item.alpha)*glass_alpha))
            for j in range(points.size()):
                draw_line(points[j],points[(j+1)%points.size()],Color(0.93,0.985,1.0,glass_alpha*0.87),1.1)
        for particle in frost_specks:
            var angle: float = particle.angle
            var distance: float = particle.distance+flight*float(particle.speed)
            var pt: Vector2 = middle+Vector2(cos(angle),sin(angle))*distance
            draw_circle(pt,particle.size,Color(0.77,0.93,1.0,glass_alpha*0.8))
