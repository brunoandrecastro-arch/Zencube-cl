extends Node3D
# Editor-playable 5x5 experiment. Intentionally not linked from the shipping menu.
# No store access, persistence, achievements, or existing realm code is modified.
const Mode = preload("res://core/ZenMaster.gd")
var pivot: Node3D
var camera: Camera3D
var tiles: Array = []
var marks: Array = []
var overlay: Node3D
var cells: Array = []
var lines: Array = []
var turn: int = 1
var winner: int = 0
var versus_bot: bool = true
var status: Label
var mode_label: Label
var finger_positions: Dictionary = {}
var first_position: Vector2 = Vector2.ZERO
var first_cell: int = -1
var dragged: bool = false
var mouse_down: bool = false
var touch_seen: bool = false

const FACE_COLORS = ["302c45", "26364b", "344440", "55433a", "45405e", "313d4c"]

func _ready() -> void:
    lines = Mode.generate_lines()
    assert(lines.size() == Mode.EXPECTED_LINES)
    _make_world()
    _make_ui()
    _restart(true)

func _material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
    var mat: StandardMaterial3D = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = 0.08
    mat.roughness = 0.61
    if unshaded:
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return mat

func _make_world() -> void:
    pivot = Node3D.new()
    pivot.name = "ZenMasterCube"
    add_child(pivot)
    camera = Camera3D.new()
    camera.position = Vector3(0, 0, 11.75)
    camera.fov = 44
    camera.current = true
    add_child(camera)
    var env: WorldEnvironment = WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("100b1e")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("c7bfdd")
    env.environment.ambient_light_energy = 0.60
    add_child(env)
    # Void Sanctuary preview: a dim violet temple backdrop, separate from Satori.
    var backdrop: Sprite3D = Sprite3D.new()
    backdrop.texture = load("res://assets/realms/shadow_realm.webp") as Texture2D
    backdrop.pixel_size = 0.012
    backdrop.shaded = false
    backdrop.modulate = Color(0.64,0.48,0.88,0.48)
    backdrop.position = Vector3(0,0,-10.0)
    add_child(backdrop)
    var sun: DirectionalLight3D = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-40, -30, 0)
    sun.light_energy = 1.45
    sun.light_color = Color("f6e4c9")
    add_child(sun)
    var fill: DirectionalLight3D = DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(26, 135, 0)
    fill.light_energy = 0.70
    fill.light_color = Color("adcbd1")
    add_child(fill)
    var core: MeshInstance3D = MeshInstance3D.new()
    var core_mesh: BoxMesh = BoxMesh.new()
    core_mesh.size = Vector3(3.2, 3.2, 3.2)
    core.mesh = core_mesh
    core.material_override = _material(Color("171826"))
    pivot.add_child(core)
    overlay = Node3D.new()
    pivot.add_child(overlay)
    for cell in range(Mode.CELLS):
        var f: int = Mode.face(cell)
        var tile: MeshInstance3D = MeshInstance3D.new()
        var box_mesh: BoxMesh = BoxMesh.new()
        box_mesh.size = Vector3(0.566, 0.566, 0.08)
        tile.mesh = box_mesh
        tile.basis = Basis(CubeGeometry.U[f], -CubeGeometry.V[f], CubeGeometry.N[f])
        tile.position = Mode.center(cell)
        tile.material_override = _material(Color(FACE_COLORS[f]))
        pivot.add_child(tile)
        tiles.append(tile)
        var collider: StaticBody3D = StaticBody3D.new()
        collider.set_meta("cell", cell)
        tile.add_child(collider)
        var collision: CollisionShape3D = CollisionShape3D.new()
        var box: BoxShape3D = BoxShape3D.new()
        box.size = box_mesh.size
        collision.shape = box
        collider.add_child(collision)
        var mark: Node3D = Node3D.new()
        mark.position.z = 0.085
        tile.add_child(mark)
        marks.append(mark)
    var podium: MeshInstance3D = MeshInstance3D.new()
    var disk: CylinderMesh = CylinderMesh.new()
    disk.top_radius = 2.10
    disk.bottom_radius = 2.16
    disk.height = 0.13
    disk.radial_segments = 48
    podium.mesh = disk
    podium.material_override = _material(Color("353050"))
    podium.position = Vector3(0,-2.37,0)
    add_child(podium)
    pivot.rotation = Vector3(0.45, -0.64, 0.06)

func _make_ui() -> void:
    var canvas: CanvasLayer = CanvasLayer.new()
    add_child(canvas)
    var ui_root: Control = Control.new()
    ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
    ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(ui_root)
    var top: PanelContainer = PanelContainer.new()
    ui_root.add_child(top)
    top.set_anchors_preset(Control.PRESET_TOP_WIDE)
    top.offset_left = 12
    top.offset_right = -12
    top.offset_top = 18
    top.offset_bottom = 129
    var top_style: StyleBoxFlat = StyleBoxFlat.new()
    top_style.bg_color = Color("26233c")
    top_style.corner_radius_top_left = 15
    top_style.corner_radius_top_right = 15
    top_style.corner_radius_bottom_left = 15
    top_style.corner_radius_bottom_right = 15
    top_style.content_margin_left = 12
    top_style.content_margin_right = 12
    top_style.content_margin_top = 8
    top_style.content_margin_bottom = 8
    top.add_theme_stylebox_override("panel", top_style)
    var header: VBoxContainer = VBoxContainer.new()
    top.add_child(header)
    mode_label = Label.new()
    mode_label.text = "VOID SANCTUARY · ZEN MASTER 5×5"
    mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    mode_label.add_theme_font_size_override("font_size", 17)
    mode_label.add_theme_color_override("font_color", Color("e6d7ac"))
    header.add_child(mode_label)
    var buttons: HBoxContainer = HBoxContainer.new()
    header.add_child(buttons)
    var bot_button: Button = Button.new()
    bot_button.text = "Zen-Bot"
    bot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bot_button.pressed.connect(_restart.bind(true))
    buttons.add_child(bot_button)
    var local_button: Button = Button.new()
    local_button.text = "2 Spieler"
    local_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    local_button.pressed.connect(_restart.bind(false))
    buttons.add_child(local_button)
    var restart_button: Button = Button.new()
    restart_button.text = "Neu"
    restart_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    restart_button.pressed.connect(_restart_current)
    buttons.add_child(restart_button)
    var replay_button: Button = Button.new()
    replay_button.text = "Satori-Test"
    replay_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    replay_button.pressed.connect(_return_to_satori)
    buttons.add_child(replay_button)
    status = Label.new()
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.add_theme_color_override("font_color", Color("f0ede2"))
    header.add_child(status)

    var footer: Label = Label.new()
    ui_root.add_child(footer)
    footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    footer.offset_left = 22
    footer.offset_right = -22
    footer.offset_top = -63
    footer.offset_bottom = -17
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    footer.add_theme_font_size_override("font_size", 15)
    footer.add_theme_color_override("font_color", Color("e6d7ac"))
    footer.text = "Drehen · Zoomen · Tippen"

func _return_to_satori() -> void:
    get_tree().change_scene_to_file("res://ZenMasterBridgeTest.tscn")

func _restart_current() -> void:
    _restart(versus_bot)

func _restart(bot: bool) -> void:
    versus_bot = bot
    cells.resize(Mode.CELLS)
    cells.fill(0)
    turn = 1
    winner = 0
    for node in marks:
        for child in node.get_children():
            child.visible = false
            child.queue_free()
    for i in range(Mode.CELLS):
        tiles[i].material_override = _material(Color(FACE_COLORS[Mode.face(i)]))
    for child in overlay.get_children():
        child.visible = false
        child.queue_free()
    _set_status()

func _set_status() -> void:
    if winner == 3:
        status.text = "Unentschieden · Alle Felder sind belegt"
    elif winner == 1:
        status.text = "X gewinnt! · Fünf in einer Reihe"
    elif winner == 2:
        status.text = ("Zen-Bot gewinnt!" if versus_bot else "O gewinnt!") + " · Fünf in einer Reihe"
    else:
        status.text = ("Du bist am Zug (X)" if versus_bot else ("X ist am Zug" if turn == 1 else "O ist am Zug"))

func _rod(parent: Node3D, a: Vector3, b: Vector3, color: Color, radius: float) -> void:
    if a.distance_to(b) < 0.001:
        return
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = a.distance_to(b)
    mesh.radial_segments = 10
    var rod: MeshInstance3D = MeshInstance3D.new()
    rod.mesh = mesh
    rod.position = (a + b) * 0.5
    rod.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
    rod.material_override = _material(color, true)
    parent.add_child(rod)

func _paint_mark(cell: int, player: int) -> void:
    var node: Node3D = marks[cell]
    if player == 1:
        var gold: Color = Color("f5d9a0")
        _rod(node, Vector3(-0.16, -0.16, 0), Vector3(0.16, 0.16, 0), gold, 0.044)
        _rod(node, Vector3(-0.16, 0.16, 0), Vector3(0.16, -0.16, 0), gold, 0.044)
    else:
        var ring: MeshInstance3D = MeshInstance3D.new()
        var torus: TorusMesh = TorusMesh.new()
        torus.inner_radius = 0.12
        torus.outer_radius = 0.215
        torus.rings = 28
        torus.ring_segments = 16
        ring.mesh = torus
        ring.rotation.x = PI / 2.0
        ring.material_override = _material(Color("88e8d3"), true)
        node.add_child(ring)

func _show_win(line: Array) -> void:
    for c in line:
        tiles[int(c)].material_override = _material(Color("71875f"))
    for i in range(line.size() - 1):
        var a: int = int(line[i])
        var b: int = int(line[i + 1])
        var pa: Vector3 = Mode.center(a, Mode.SURFACE + 0.13)
        var pb: Vector3 = Mode.center(b, Mode.SURFACE + 0.13)
        if Mode.face(a) == Mode.face(b):
            _rod(overlay, pa, pb, Color("ffe5a4"), 0.022)
        else:
            var na: Vector3 = CubeGeometry.N[Mode.face(a)]
            var nb: Vector3 = CubeGeometry.N[Mode.face(b)]
            var tangent: Vector3 = na.cross(nb)
            var corner: Vector3 = (na + nb) * (Mode.SURFACE + 0.13) + tangent * pa.dot(tangent)
            _rod(overlay, pa, corner, Color("ffe5a4"), 0.022)
            _rod(overlay, corner, pb, Color("ffe5a4"), 0.022)

func _on_tap(cell: int) -> void:
    if cell < 0 or cell >= Mode.CELLS or winner != 0 or int(cells[cell]) != 0:
        return
    if versus_bot and turn != 1:
        return
    _play_move(cell)

func _play_move(cell: int) -> void:
    if cell < 0 or cell >= Mode.CELLS or winner != 0 or int(cells[cell]) != 0:
        return
    cells[cell] = turn
    _paint_mark(cell, turn)
    var victories: Array = Mode.winning_lines(cells, lines, turn)
    if not victories.is_empty():
        winner = turn
        _show_win(victories[0])
    elif not cells.has(0):
        winner = 3
    else:
        turn = 3 - turn
    _set_status()
    if winner == 0 and versus_bot and turn == 2:
        call_deferred("_bot_turn")

func _bot_turn() -> void:
    if winner != 0 or not versus_bot or turn != 2:
        return
    var choice: int = Mode.next_move(cells, lines, 2, 1)
    if choice >= 0:
        _play_move(choice)

func _pick(position: Vector2) -> int:
    var origin: Vector3 = camera.project_ray_origin(position)
    var endpoint: Vector3 = origin + camera.project_ray_normal(position) * 100.0
    var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, endpoint))
    if hit.is_empty():
        return -1
    return int(hit.collider.get_meta("cell", -1))

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        touch_seen = true
        if event.pressed:
            finger_positions[event.index] = event.position
            if finger_positions.size() == 1:
                first_position = event.position
                first_cell = _pick(event.position)
                dragged = false
            else:
                dragged = true
        else:
            if finger_positions.size() == 1 and not dragged and event.position.distance_to(first_position) <= 14:
                var released: int = _pick(event.position)
                if released >= 0 and released == first_cell:
                    _on_tap(released)
            finger_positions.erase(event.index)
            if finger_positions.is_empty():
                first_cell = -1
    elif event is InputEventScreenDrag:
        touch_seen = true
        if finger_positions.size() >= 2:
            var keys: Array = finger_positions.keys()
            var before: float = finger_positions[keys[0]].distance_to(finger_positions[keys[1]])
            finger_positions[event.index] = event.position
            var after: float = finger_positions[keys[0]].distance_to(finger_positions[keys[1]])
            if before > 4 and after > 4:
                camera.position.z = clampf(camera.position.z * before / after, 6.8, 15.0)
            dragged = true
        elif finger_positions.size() == 1:
            finger_positions[event.index] = event.position
            if event.position.distance_to(first_position) > 14:
                dragged = true
            if dragged:
                _rotate(event.relative)
    elif event is InputEventMouseButton:
        if touch_seen or OS.get_name() == "Android":
            return
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            camera.position.z = clampf(camera.position.z * 0.93, 6.8, 15.0)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            camera.position.z = clampf(camera.position.z * 1.07, 6.8, 15.0)
        elif event.button_index == MOUSE_BUTTON_LEFT:
            mouse_down = event.pressed
            if event.pressed:
                first_position = event.position
                first_cell = _pick(event.position)
                dragged = false
            elif not dragged and event.position.distance_to(first_position) <= 14:
                var released: int = _pick(event.position)
                if released == first_cell:
                    _on_tap(released)
    elif event is InputEventMouseMotion and mouse_down and not touch_seen:
        if event.position.distance_to(first_position) > 14:
            dragged = true
        if dragged:
            _rotate(event.relative)

func _rotate(relative: Vector2) -> void:
    pivot.basis = (Basis(Vector3.UP, relative.x * 0.008) * Basis(Vector3.RIGHT, relative.y * 0.008) * pivot.basis).orthonormalized()
