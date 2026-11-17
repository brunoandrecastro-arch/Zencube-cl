extends Control
# Standalone QA effect: real screen-space GLASS fracture rather than ice or magical fog.
# An expanding radial spiderweb, a hard flash, and transparent flying panes reveal
# an already visible 5x5 preview beneath the opening.
signal fracture_finished
var elapsed: float = 0.0
var duration: float = 3.15
var running: bool = false
var crack_paths: Array = []
var shard_data: Array = []
var splinters: Array = []
var headline: Label
var subtitle: Label
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    visible = false
    rng.seed = 20261117
    _make_quote()
    set_process(false)

func _make_quote() -> void:
    var group: VBoxContainer = VBoxContainer.new()
    group.anchor_left = 0.05
    group.anchor_right = 0.95
    group.anchor_top = 0.085
    group.anchor_bottom = 0.085
    group.offset_bottom = 145.0
    group.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(group)
    headline = Label.new()
    headline.text = "Enlightenment was never the end.\nIt was the beginning."
    headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    headline.add_theme_font_size_override("font_size", 24)
    headline.add_theme_color_override("font_color", Color("fff8e5"))
    group.add_child(headline)
    subtitle = Label.new()
    subtitle.text = "ZEN MASTER AWAKENS"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 18)
    subtitle.add_theme_color_override("font_color", Color("f5d7a4"))
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
    _generate_glass()
    set_process(true)
    if OS.get_name() == "Android":
        Input.vibrate_handheld(125)

func _generate_glass() -> void:
    crack_paths.clear()
    shard_data.clear()
    splinters.clear()
    var bounds: Vector2 = get_viewport_rect().size
    var mid: Vector2 = bounds * Vector2(0.5, 0.52)
    var radius: float = bounds.length() * 0.70
    var spokes: int = 22
    var spoke_data: Array = []
    # Each jagged ray shares its vertices with neighbouring sectors so
    # the entire pane cracks as one continuous radial spiderweb.
    for i in range(spokes):
        var angle: float = TAU*float(i)/float(spokes)+rng.randf_range(-0.045,0.045)
        var unit: Vector2 = Vector2(cos(angle),sin(angle))
        var path: PackedVector2Array = PackedVector2Array([mid])
        for ring in range(1,7):
            var r: float = radius*float(ring)/6.0
            var jitter: float = rng.randf_range(-0.065,0.065)*r
            path.append(mid+unit*r+unit.orthogonal()*jitter)
        spoke_data.append(path)
        crack_paths.append(path)
    for ring in range(1,6):
        for i in range(spokes):
            var first: Vector2 = spoke_data[i][ring]
            var second: Vector2 = spoke_data[(i+1)%spokes][ring]
            var middle: Vector2 = (first+second)*0.5
            middle += (first-second).orthogonal()*rng.randf_range(-0.05,0.05)
            crack_paths.append(PackedVector2Array([first,middle,second]))
    # The glass fills the screen, but panes are physically displaced after impact.
    # NO opaque full-screen tint is drawn once the pane breaks: a true hole opens.
    for i in range(spokes):
        var next_i: int = (i+1)%spokes
        for ring in range(1,7):
            var a: Vector2 = spoke_data[i][ring-1]
            var b: Vector2 = spoke_data[next_i][ring-1]
            var c: Vector2 = spoke_data[i][ring]
            var d: Vector2 = spoke_data[next_i][ring]
            for tri in [PackedVector2Array([a,c,d]),PackedVector2Array([a,d,b])]:
                var ctr: Vector2 = (tri[0]+tri[1]+tri[2])/3.0
                var dir: Vector2 = (ctr-mid).normalized()
                if dir.length_squared() < 0.01:
                    dir = Vector2(cos(TAU*float(i)/float(spokes)),sin(TAU*float(i)/float(spokes)))
                shard_data.append({
                    "vertices":tri,
                    "center":ctr,
                    "dir":dir,
                    "speed":rng.randf_range(370.0,1000.0),
                    "spin":rng.randf_range(-2.9,2.9),
                    "alpha":rng.randf_range(0.09,0.22),
                    "ring":ring
                })
    for i in range(160):
        splinters.append({
            "angle":rng.randf_range(-PI,PI),
            "offset":rng.randf_range(2.0,65.0),
            "speed":rng.randf_range(60.0,920.0),
            "radius":rng.randf_range(0.5,2.6)
        })

func _process(delta: float) -> void:
    if not running:
        return
    elapsed += delta
    var progress: float = clampf(elapsed/duration,0.0,1.0)
    headline.modulate.a = clampf((progress-0.47)*5.5,0.0,1.0)
    subtitle.modulate.a = clampf((progress-0.64)*6.0,0.0,1.0)
    queue_redraw()
    if progress >= 1.0:
        running = false
        set_process(false)
        fracture_finished.emit()

func _draw() -> void:
    if not running:
        return
    var progress: float = clampf(elapsed/duration,0.0,1.0)
    var middle: Vector2 = size*Vector2(0.5,0.52)
    # First 0.95 sec: white razor-sharp spiderweb cracks explode radially.
    var reveal: float = clampf(progress*3.0,0.0,1.0)
    if progress < 0.34:
        draw_rect(Rect2(Vector2.ZERO,size),Color(0.025,0.035,0.05,0.14))
        for path in crack_paths:
            for j in range(path.size()-1):
                if float(j)/float(maxi(1,path.size()-1)) > reveal:
                    break
                draw_line(path[j],path[j+1],Color(0.0,0.015,0.045,0.72),4.0)
                draw_line(path[j],path[j+1],Color(0.97,0.99,1.0,0.98),1.8)
        for i in range(11):
            draw_arc(middle,2.0+float(i)*3.2,0.0,TAU,32,Color(1.0,1.0,1.0,0.035),1.0)
    # A fast hard photographic impact, no green chroma or ice-blue wash.
    var strike: float = maxf(0.0,1.0-absf(progress-0.33)*24.0)
    if strike > 0.001:
        draw_rect(Rect2(Vector2.ZERO,size),Color(1.0,1.0,1.0,strike*0.79))
    if progress < 0.33:
        return
    var flight: float = clampf((progress-0.33)/0.48,0.0,1.0)
    var ease: float = flight*flight*(3.0-2.0*flight)
    var fade: float = 1.0-clampf((progress-0.63)*3.0,0.0,1.0)
    for glass in shard_data:
        var ctr: Vector2 = glass.center
        var dir: Vector2 = glass.dir
        var speed: float = glass.speed
        var drift: Vector2 = dir*speed*ease+Vector2(0.0,75.0*ease*ease)
        var theta: float = float(glass.spin)*ease
        var verts: PackedVector2Array = PackedVector2Array()
        for point in glass.vertices:
            verts.append(ctr+(point-ctr).rotated(theta)+drift)
        var opacity: float = fade*float(glass.alpha)
        if opacity <= 0.01:
            continue
        draw_colored_polygon(verts,Color(0.87,0.96,1.0,opacity))
        for j in range(3):
            draw_line(verts[j],verts[(j+1)%3],Color(1.0,1.0,1.0,fade*0.93),1.15)
        draw_line(verts[0],verts[2],Color(0.53,0.75,0.94,fade*0.23),2.0)
    # White glints are NOT dense smoke or snow. The opening remains transparent.
    for dust in splinters:
        var alpha: float = fade*0.93
        if alpha < 0.01:
            break
        var a: float = dust.angle
        var r: float = dust.offset+dust.speed*ease
        var location: Vector2 = middle+Vector2(cos(a),sin(a))*r
        draw_line(location,location+Vector2(cos(a),sin(a))*7.0,Color(1.0,1.0,1.0,alpha),dust.radius)
