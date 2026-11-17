extends Node3D
# QA-only bridge: an intentionally easy real 4x4 Satori victory triggers the 5x5 awakening.
# Not connected to main, Play Alpha, save files or the 4x4 Realm Chronicles.
const Four = preload("res://core/ZenAscend.gd")
const Five = preload("res://core/ZenMaster.gd")
const Mirror = preload("res://ui/ZenMirrorBreak.gd")
var cells: Array = []
var lines: Array = []
var pivot: Node3D
var camera: Camera3D
var tiles: Array = []
var marks: Array = []
var status: Label
var mirror: Control
var transition_started: bool = false
var touch_positions: Dictionary = {}
var touch_origin: Vector2 = Vector2.ZERO
var tap_cell: int = -1
var dragged: bool = false
var mouse_pressed: bool = false
var touch_seen: bool = false
var fracture_sound: AudioStreamPlayer
var preview_cube: Node3D
var hud_layer: CanvasLayer

func _ready() -> void:
    lines = Four.generate_lines()
    assert(lines.size() == 204)
    _world()
    _interface()
    _seed_final_test()

func _mat(color: Color, unshaded: bool = false) -> StandardMaterial3D:
    var m: StandardMaterial3D = StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.65
    m.metallic = 0.08
    if unshaded:
        m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return m

func _world() -> void:
    pivot = Node3D.new()
    pivot.name = "SatoriFourByFour"
    add_child(pivot)
    camera = Camera3D.new()
    camera.position = Vector3(0,0,10.2)
    camera.fov = 44
    camera.current = true
    add_child(camera)
    var env: WorldEnvironment = WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("191522")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("f0e1b8")
    env.environment.ambient_light_energy = 0.8
    add_child(env)
    var sun: DirectionalLight3D = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-36,-30,0)
    sun.light_energy = 1.7
    sun.light_color = Color("ffe6bc")
    add_child(sun)
    var fill: DirectionalLight3D = DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(26,125,0)
    fill.light_energy = 0.75
    fill.light_color = Color("c4b5e8")
    add_child(fill)
    var backdrop: Sprite3D = Sprite3D.new()
    backdrop.texture = load("res://assets/realms/satori_realm.webp") as Texture2D
    backdrop.pixel_size = 0.012
    backdrop.shaded = false
    backdrop.modulate = Color(0.64,0.58,0.7,0.48)
    backdrop.position = Vector3(0,0,-9.5)
    add_child(backdrop)
    var core: MeshInstance3D = MeshInstance3D.new()
    var core_mesh: BoxMesh = BoxMesh.new()
    core_mesh.size = Vector3(3.2,3.2,3.2)
    core.mesh = core_mesh
    core.material_override = _mat(Color("342b3c"))
    pivot.add_child(core)
    for c in range(Four.CELLS):
        var f: int = int(c/16)
        var tile: MeshInstance3D = MeshInstance3D.new()
        var mesh: BoxMesh = BoxMesh.new()
        mesh.size = Vector3(0.755,0.755,0.085)
        tile.mesh = mesh
        tile.basis = Basis(CubeGeometry.U[f],-CubeGeometry.V[f],CubeGeometry.N[f])
        tile.position = Four.center(c)
        tile.material_override = _mat(Color("6c5c7e") if f == 0 else Color("645f77"))
        pivot.add_child(tile)
        tiles.append(tile)
        var body: StaticBody3D = StaticBody3D.new()
        body.set_meta("cell",c)
        tile.add_child(body)
        var collision: CollisionShape3D = CollisionShape3D.new()
        var shape: BoxShape3D = BoxShape3D.new()
        shape.size = mesh.size
        collision.shape = shape
        body.add_child(collision)
        var mark: Node3D = Node3D.new()
        mark.position.z = 0.09
        tile.add_child(mark)
        marks.append(mark)
    pivot.rotation = Vector3(0.16,-0.17,0.0)
    _create_void_preview()
    fracture_sound = AudioStreamPlayer.new()
    fracture_sound.stream = _sound()
    fracture_sound.volume_db = -7.0
    add_child(fracture_sound)

func _create_void_preview() -> void:
    # A real 5x5 150-tile cube materializes THROUGH the opening before scene change.
    preview_cube = Node3D.new()
    preview_cube.name = "VoidSanctuaryFiveByFiveReveal"
    preview_cube.visible = false
    preview_cube.scale = Vector3.ONE*0.62
    preview_cube.rotation = Vector3(0.32,-0.58,0.05)
    preview_cube.position.z = -0.26
    add_child(preview_cube)
    var core: MeshInstance3D = MeshInstance3D.new()
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = Vector3(3.2,3.2,3.2)
    core.mesh = mesh
    core.material_override = _mat(Color("171322"))
    preview_cube.add_child(core)
    for c in range(Five.CELLS):
        var face: int = Five.face(c)
        var tile: MeshInstance3D = MeshInstance3D.new()
        var box: BoxMesh = BoxMesh.new()
        box.size = Vector3(0.566,0.566,0.077)
        tile.mesh = box
        tile.basis = Basis(CubeGeometry.U[face],-CubeGeometry.V[face],CubeGeometry.N[face])
        tile.position = Five.center(c)
        var tint: Color = Color("2b2546") if face % 2 == 0 else Color("3f315a")
        tile.material_override = _mat(tint)
        preview_cube.add_child(tile)
    var halo: OmniLight3D = OmniLight3D.new()
    halo.light_color = Color("b284f7")
    halo.light_energy = 2.1
    halo.omni_range = 6.0
    halo.position = Vector3(-1.6,1.3,3.0)
    preview_cube.add_child(halo)

func _sound() -> AudioStreamWAV:
    # Original synthetic glass fracture / rising tone. No copyrighted sample.
    var wave: AudioStreamWAV = AudioStreamWAV.new()
    wave.format = AudioStreamWAV.FORMAT_16_BITS
    wave.mix_rate = 22050
    wave.stereo = false
    var rate: int = 22050
    var frames: int = int(float(rate) * 2.1)
    var data: PackedByteArray = PackedByteArray()
    data.resize(frames*2)
    var random: RandomNumberGenerator = RandomNumberGenerator.new()
    random.seed = 5115
    for i in range(frames):
        var t: float = float(i)/float(rate)
        var crack: float = random.randf_range(-1.0,1.0) * (exp(-t*14.0) + 0.75*exp(-absf(t-0.72)*36.0) + 0.55*exp(-absf(t-1.12)*46.0))
        var shimmer: float = sin(TAU*(1090.0*t+520.0*t*t)) * exp(-t*3.3)
        var echo: float = sin(TAU*(880.0*t+150.0*t*t)) * exp(-t*2.2)
        var sample: float = (crack*0.42 + shimmer*0.25 + echo*0.18)*0.68
        data.encode_s16(i*2,clampi(int(sample*32767.0),-32768,32767))
    wave.data = data
    return wave

func _interface() -> void:
    var layer: CanvasLayer = CanvasLayer.new()
    hud_layer = layer
    add_child(layer)
    var root_ui: Control = Control.new()
    root_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
    root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root_ui)
    var top: PanelContainer = PanelContainer.new()
    top.set_anchors_preset(Control.PRESET_TOP_WIDE)
    top.offset_left = 12
    top.offset_right = -12
    top.offset_top = 18
    top.offset_bottom = 140
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color("292438")
    style.corner_radius_top_left = 14
    style.corner_radius_top_right = 14
    style.corner_radius_bottom_left = 14
    style.corner_radius_bottom_right = 14
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 7
    style.content_margin_bottom = 7
    top.add_theme_stylebox_override("panel",style)
    root_ui.add_child(top)
    var col: VBoxContainer = VBoxContainer.new()
    top.add_child(col)
    var title: Label = Label.new()
    title.text = "SATORI REALM · LETZTE PRÜFUNG 4×4"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size",19)
    title.add_theme_color_override("font_color",Color("f8e2ac"))
    col.add_child(title)
    status = Label.new()
    status.text = "Bot: sehr leicht · Ein X fehlt zum Sieg"
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.add_theme_font_size_override("font_size",15)
    status.add_theme_color_override("font_color",Color("fbf0d5"))
    col.add_child(status)
    var buttons: HBoxContainer = HBoxContainer.new()
    col.add_child(buttons)
    var win_button: Button = Button.new()
    win_button.text = "Sieg + Bruch"
    win_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    win_button.pressed.connect(_quick_win)
    buttons.add_child(win_button)
    var again_button: Button = Button.new()
    again_button.text = "Neu"
    again_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    again_button.pressed.connect(_seed_final_test)
    buttons.add_child(again_button)
    var direct_button: Button = Button.new()
    direct_button.text = "5×5 direkt"
    direct_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    direct_button.pressed.connect(_goto_void)
    buttons.add_child(direct_button)
    var bottom: Label = Label.new()
    bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    bottom.offset_left = 18
    bottom.offset_right = -18
    bottom.offset_top = -78
    bottom.offset_bottom = -24
    bottom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    bottom.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    bottom.add_theme_font_size_override("font_size",17)
    bottom.add_theme_color_override("font_color",Color("f7e7bd"))
    bottom.text = "Setze das vierte X auf das goldene Feld."
    root_ui.add_child(bottom)
    var shatter_layer: CanvasLayer = CanvasLayer.new()
    shatter_layer.layer = 5
    add_child(shatter_layer)
    mirror = Mirror.new()
    mirror.set_anchors_preset(Control.PRESET_FULL_RECT)
    shatter_layer.add_child(mirror)
    mirror.fracture_finished.connect(_goto_void)

func _bar(parent: Node3D, a: Vector3, b: Vector3, color: Color, radius: float = 0.065) -> void:
    var rod: MeshInstance3D = MeshInstance3D.new()
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.height = a.distance_to(b)
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.radial_segments = 10
    rod.mesh = mesh
    rod.position = (a+b)*0.5
    rod.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
    rod.material_override = _mat(color,true)
    parent.add_child(rod)

func _mark(c: int, owner: int) -> void:
    if owner == 1:
        _bar(marks[c],Vector3(-0.22,-0.22,0),Vector3(0.22,0.22,0),Color("f9dfa2"))
        _bar(marks[c],Vector3(-0.22,0.22,0),Vector3(0.22,-0.22,0),Color("f9dfa2"))
    elif owner == 2:
        var torus: TorusMesh = TorusMesh.new()
        torus.inner_radius = 0.18
        torus.outer_radius = 0.30
        var ring: MeshInstance3D = MeshInstance3D.new()
        ring.mesh = torus
        ring.rotation.x = PI/2
        ring.material_override = _mat(Color("b2ece6"),true)
        marks[c].add_child(ring)

func _seed_final_test() -> void:
    if transition_started:
        return
    cells.resize(Four.CELLS)
    cells.fill(0)
    for node in marks:
        for child in node.get_children():
            child.queue_free()
    for i in range(Four.CELLS):
        tiles[i].material_override = _mat(Color("6c5c7e") if i < 16 else Color("645f77"))
    for c in [0,1,2]:
        cells[c] = 1
        _mark(c,1)
    cells[70] = 2
    _mark(70,2)
    tiles[3].material_override = _mat(Color("c59c50"),true)
    status.text = "Bot: sehr leicht · Ein X fehlt zum Sieg"

func _quick_win() -> void:
    if not transition_started:
        _on_tap(3)

func _on_tap(c: int) -> void:
    if transition_started or c < 0 or c >= Four.CELLS or int(cells[c]) != 0:
        return
    cells[c] = 1
    _mark(c,1)
    var wins: Array = Four.winning_lines(cells,lines,1)
    if not wins.is_empty():
        _begin_fracture()
        return
    # Extremely easy, deliberately non-blocking QA bot; never used in normal 4x4.
    for probe in [71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86]:
        if int(cells[probe]) == 0:
            cells[probe] = 2
            _mark(probe,2)
            break
    status.text = "Fast geschafft · Das goldene Feld gewinnt!"

func _begin_fracture() -> void:
    transition_started = true
    status.text = "SIEG! Der neue Weg öffnet sich."
    # Mirror starts with the visible 4x4, then glass cracks and exposes an actual 5x5 preview.
    hud_layer.visible = false
    mirror.begin()
    var tween: Tween = create_tween()
    tween.tween_interval(0.99)
    tween.tween_callback(fracture_sound.play)
    tween.tween_property(pivot,"scale",Vector3.ONE*0.04,0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
    tween.tween_callback(_reveal_void_preview)


func _reveal_void_preview() -> void:
    if not transition_started:
        return
    pivot.visible = false
    preview_cube.visible = true
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(preview_cube,"scale",Vector3.ONE,1.3).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
    tween.tween_property(preview_cube,"rotation",preview_cube.rotation+Vector3(-0.14,0.64,0.0),1.3)

func _goto_void() -> void:
    get_tree().change_scene_to_file("res://ZenMasterCampaign.tscn")

func _pick(pos: Vector2) -> int:
    var origin: Vector3 = camera.project_ray_origin(pos)
    var target: Vector3 = origin+camera.project_ray_normal(pos)*100.0
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin,target))
    if hit.is_empty():
        return -1
    return int(hit.collider.get_meta("cell",-1))

func _rotate(d: Vector2) -> void:
    pivot.basis = (Basis(Vector3.UP,d.x*0.008)*Basis(Vector3.RIGHT,d.y*0.008)*pivot.basis).orthonormalized()

func _unhandled_input(event: InputEvent) -> void:
    if transition_started:
        return
    if event is InputEventScreenTouch:
        touch_seen = true
        if event.pressed:
            touch_positions[event.index] = event.position
            if touch_positions.size() == 1:
                touch_origin = event.position
                tap_cell = _pick(event.position)
                dragged = false
            else:
                dragged = true
        else:
            if touch_positions.size() == 1 and not dragged and event.position.distance_to(touch_origin) < 14:
                var released: int = _pick(event.position)
                if released >= 0 and released == tap_cell:
                    _on_tap(released)
            touch_positions.erase(event.index)
    elif event is InputEventScreenDrag:
        touch_seen = true
        if touch_positions.size() >= 2:
            var ids: Array = touch_positions.keys()
            var before: float = touch_positions[ids[0]].distance_to(touch_positions[ids[1]])
            touch_positions[event.index] = event.position
            var after: float = touch_positions[ids[0]].distance_to(touch_positions[ids[1]])
            if before > 4 and after > 4:
                camera.position.z = clampf(camera.position.z*before/after,7.0,13.8)
            dragged = true
        elif touch_positions.size() == 1:
            touch_positions[event.index] = event.position
            if event.position.distance_to(touch_origin) > 14:
                dragged = true
            if dragged:
                _rotate(event.relative)
    elif event is InputEventMouseButton:
        if touch_seen or OS.get_name() == "Android":
            return
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            camera.position.z = clampf(camera.position.z*0.92,7.0,13.8)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            camera.position.z = clampf(camera.position.z*1.08,7.0,13.8)
        elif event.button_index == MOUSE_BUTTON_LEFT:
            mouse_pressed = event.pressed
            if event.pressed:
                touch_origin = event.position
                tap_cell = _pick(event.position)
                dragged = false
            elif not dragged and event.position.distance_to(touch_origin) < 14:
                var released: int = _pick(event.position)
                if released == tap_cell:
                    _on_tap(released)
    elif event is InputEventMouseMotion and mouse_pressed and not touch_seen:
        if event.position.distance_to(touch_origin) > 14:
            dragged = true
        if dragged:
            _rotate(event.relative)
