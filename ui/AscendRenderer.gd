class_name AscendRenderer
extends Node3D
# Independent premium 4x4 cube. No modification to CubeRenderer/Classic.
var pivot: Node3D
var camera: Camera3D
var tiles: Array = []
var marks: Array = []
var skin: Dictionary = {}
var skin_texture: Texture2D
var active_cells: Array = []
var winner_cells: Array = []
const BossSkins = preload("res://core/ZenRealmBossSkins.gd")
const AbyssSkins = preload("res://core/ZenAbyssSkins.gd")
var boss_skin_id: int = -1
var boss_skin_texture: Texture2D
var boss_skin_cache: Dictionary = {}
var abyss_skin_id: int = -1
var abyss_skin_texture: Texture2D
var abyss_skin_cache: Dictionary = {}
var ember_fire: Node3D
var ember_emitters: Array[CPUParticles3D] = []
func _ready() -> void:
    pivot = Node3D.new()
    add_child(pivot)
    camera = Camera3D.new()
    camera.position = Vector3(0,0,9.4)
    camera.fov = 42
    camera.current = true
    add_child(camera)
    var world: WorldEnvironment = WorldEnvironment.new()
    world.environment = Environment.new()
    world.environment.background_mode = Environment.BG_COLOR
    world.environment.background_color = Color(0.0,0.0,0.0,0.0)
    world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    world.environment.ambient_light_color = Color("fff0da")
    world.environment.ambient_light_energy = 0.7
    add_child(world)
    var sun: DirectionalLight3D = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-38,-30,0)
    sun.light_energy = 1.2
    add_child(sun)
    var fill: DirectionalLight3D = DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(28,135,0)
    fill.light_energy = 0.55
    fill.light_color = Color("c3e0cf")
    add_child(fill)
    var core: MeshInstance3D = MeshInstance3D.new()
    var core_mesh: BoxMesh = BoxMesh.new()
    core_mesh.size = Vector3(3.2,3.2,3.2)
    core.mesh = core_mesh
    core.name = "CubeCore"
    pivot.add_child(core)
    var podium: MeshInstance3D = MeshInstance3D.new()
    var pod_mesh: CylinderMesh = CylinderMesh.new()
    pod_mesh.top_radius = 2.25
    pod_mesh.bottom_radius = 2.34
    pod_mesh.height = 0.13
    pod_mesh.radial_segments = 48
    podium.mesh = pod_mesh
    podium.material_override = mat(Color("ccb89c"))
    podium.position = Vector3(0,-2.36,0)
    add_child(podium)
    for c in range(ZenAscend.CELLS):
        var f: int = int(c / 16)
        var tile: MeshInstance3D = MeshInstance3D.new()
        var mesh: BoxMesh = BoxMesh.new()
        mesh.size = Vector3(0.755,0.755,0.085)
        tile.mesh = mesh
        tile.basis = Basis(CubeGeometry.U[f], -CubeGeometry.V[f], CubeGeometry.N[f])
        tile.position = ZenAscend.center(c)
        tile.set_meta("cell",c)
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
        mark.position.z = 0.065
        tile.add_child(mark)
        marks.append(mark)
    reset_view()
    set_skin(0)

func mat(color: Color, unlit: bool = false) -> StandardMaterial3D:
    var result: StandardMaterial3D = StandardMaterial3D.new()
    result.albedo_color = color
    result.roughness = 0.72
    if unlit: result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return result

func set_skin(index: int) -> void:
    var skin_index: int = clampi(index,0,ZenCollection.SKINS.size()-1)
    skin = ZenCollection.SKINS[skin_index]
    skin_texture = load("res://assets/skins/skin_%02d.webp" % skin_index) as Texture2D
    _apply_core_skin()
    repaint(active_cells,winner_cells)

func set_boss_skin(index: int) -> void:
    if index < 0 or index >= BossSkins.PROFILES.size():
        return
    boss_skin_id = index
    if not boss_skin_cache.has(index):
        boss_skin_cache[index] = BossSkins.make_surface(index)
    boss_skin_texture = boss_skin_cache[index]
    _apply_core_skin()
    repaint(active_cells,winner_cells)

func set_abyss_skin(index: int) -> void:
    if index < 0 or index >= AbyssSkins.PROFILES.size(): return
    abyss_skin_id = index
    if not abyss_skin_cache.has(index): abyss_skin_cache[index] = AbyssSkins.make_surface(index)
    abyss_skin_texture = abyss_skin_cache[index]
    _apply_core_skin()
    repaint(active_cells,winner_cells)

func clear_abyss_skin() -> void:
    abyss_skin_id = -1
    abyss_skin_texture = null
    _apply_core_skin()
    repaint(active_cells,winner_cells)

func clear_boss_skin() -> void:
    boss_skin_id = -1
    boss_skin_texture = null
    _apply_core_skin()
    repaint(active_cells,winner_cells)

func _apply_core_skin() -> void:
    if pivot == null or not pivot.has_node("CubeCore"): return
    var core: MeshInstance3D = pivot.get_node("CubeCore") as MeshInstance3D
    var core_color: Color = Color(str(AbyssSkins.get_profile(abyss_skin_id).core)) if abyss_skin_id >= 0 else (Color(str(BossSkins.get_profile(boss_skin_id).core)) if boss_skin_id >= 0 else Color(str(skin.core)))
    var core_material: StandardMaterial3D = mat(core_color)
    if _ember_fire_active():
        core_material.emission_enabled = true
        core_material.emission = _ember_glow()
        core_material.emission_energy_multiplier = 0.48
    core.material_override = core_material
    _sync_ember_fire()

func _tile_mat(face_index: int, highlight: bool) -> StandardMaterial3D:
    var palette: Dictionary = AbyssSkins.get_profile(abyss_skin_id) if abyss_skin_id >= 0 else (BossSkins.get_profile(boss_skin_id) if boss_skin_id >= 0 else skin)
    var base: Color = Color(str(palette.faces[face_index]))
    if highlight: base = base.lightened(0.32)
    var m: StandardMaterial3D = mat(base)
    m.metallic = float(palette.metal)
    m.roughness = float(palette.rough)
    m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    var texture: Texture2D = abyss_skin_texture if abyss_skin_id >= 0 else (boss_skin_texture if boss_skin_id >= 0 else skin_texture)
    if texture != null: m.albedo_texture = texture
    if _ember_fire_active():
        m.emission_enabled = true
        m.emission = _ember_glow()
        m.emission_texture = texture
        m.emission_energy_multiplier = 0.12 if highlight else 0.25
    return m

# Ember VFX are cosmetic only: no collisions, no extra cells or shop ownership.
func _ember_fire_active() -> bool:
    return abyss_skin_id < 0 and boss_skin_id >= 3 and boss_skin_id <= 5

func _ember_glow() -> Color:
    match boss_skin_id:
        3: return Color("#ff5920")
        4: return Color("#ff932a")
        _: return Color("#ffc052")

func _sync_ember_fire() -> void:
    if not _ember_fire_active():
        if is_instance_valid(ember_fire):
            ember_fire.visible = false
            for emitter in ember_emitters:
                emitter.emitting = false
        return
    if not is_instance_valid(ember_fire):
        ember_fire = Node3D.new()
        ember_fire.name = "EmberFlameVFX"
        pivot.add_child(ember_fire)
        var image: Image = Image.create(32,64,false,Image.FORMAT_RGBA8)
        for y in range(64):
            var v: float = float(y)/63.0
            for x in range(32):
                var u: float = float(x)/31.0
                var bend: float = sin(v*5.0)*0.09
                var width: float = 0.39*(0.25+0.75*v)
                var edge: float = absf(u-0.5-bend)/width
                var alpha: float = clampf(1.0-edge,0.0,1.0)
                alpha = alpha*alpha*sin(v*PI)
                image.set_pixel(x,y,Color(1.0,0.5+0.5*v,0.14+0.62*v,alpha))
        var flame_material: StandardMaterial3D = StandardMaterial3D.new()
        flame_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        flame_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        flame_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
        flame_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
        flame_material.vertex_color_use_as_albedo = true
        flame_material.albedo_texture = ImageTexture.create_from_image(image)
        var flame_mesh: QuadMesh = QuadMesh.new()
        flame_mesh.size = Vector2(0.32,0.78)
        flame_mesh.material = flame_material
        # Four low-density edge emitters keep the 16 tiles per face legible.
        for side in range(4):
            var emitter: CPUParticles3D = CPUParticles3D.new()
            emitter.name = "EdgeFlame%d" % side
            emitter.emitting = false
            emitter.amount = 12
            emitter.lifetime = 0.85
            emitter.preprocess = 0.8
            emitter.randomness = 0.8
            emitter.local_coords = true
            emitter.mesh = flame_mesh
            emitter.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
            emitter.emission_box_extents = Vector3(1.35,0.04,0.06)
            emitter.position = Vector3(0,1.65,0)
            if side < 2:
                emitter.position.z = 1.58 if side == 0 else -1.58
            else:
                emitter.position.x = 1.58 if side == 2 else -1.58
                emitter.emission_box_extents = Vector3(0.06,0.04,1.35)
            emitter.direction = Vector3.UP
            emitter.spread = 16.0
            emitter.gravity = Vector3(0,0.35,0)
            emitter.initial_velocity_min = 0.35
            emitter.initial_velocity_max = 0.9
            emitter.scale_amount_min = 0.4
            emitter.scale_amount_max = 0.9
            ember_fire.add_child(emitter)
            ember_emitters.append(emitter)
    ember_fire.visible = true
    for emitter in ember_emitters:
        var fade: Gradient = Gradient.new()
        fade.offsets = PackedFloat32Array([0.0,0.18,0.65,1.0])
        fade.colors = PackedColorArray([Color(1,0.85,0.45,0),_ember_glow(),Color(0.9,0.18,0.03,0.45),Color(0.5,0.05,0.0,0)])
        emitter.color_ramp = fade
        emitter.emitting = true

func _rod(parent: Node3D, from: Vector3, to: Vector3, color: Color, width: float) -> void:
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.height = from.distance_to(to)
    mesh.top_radius = width
    mesh.bottom_radius = width
    mesh.radial_segments = 10
    var node: MeshInstance3D = MeshInstance3D.new()
    node.mesh = mesh
    node.position = (from+to)*0.5
    node.quaternion = Quaternion(Vector3.UP,(to-from).normalized())
    node.material_override = mat(color,true)
    parent.add_child(node)

func repaint(cells: Array, victories: Array = []) -> void:
    active_cells = cells.duplicate()
    winner_cells = victories.duplicate()
    if tiles.size() != ZenAscend.CELLS or skin.is_empty(): return
    for c in range(ZenAscend.CELLS):
        var highlight: bool = victories.has(c)
        tiles[c].material_override = _tile_mat(int(c/16),highlight)
        for n in marks[c].get_children(): n.queue_free()
        # Immediate freeing before the next mark prevents ghost marks after a reset.
        # Nodes remain queued for deletion until the next frame but won't be shown.
        for n in marks[c].get_children(): n.visible = false
        if cells.size() <= c: continue
        if int(cells[c]) == 1:
            _rod(marks[c],Vector3(-0.19,-0.19,0.01),Vector3(0.19,0.19,0.01),Color("fff4d8"),0.075)
            _rod(marks[c],Vector3(-0.19,0.19,0.01),Vector3(0.19,-0.19,0.01),Color("fff4d8"),0.075)
            _rod(marks[c],Vector3(-0.19,-0.19,0.065),Vector3(0.19,0.19,0.065),Color("322a28"),0.046)
            _rod(marks[c],Vector3(-0.19,0.19,0.065),Vector3(0.19,-0.19,0.065),Color("322a28"),0.046)
        elif int(cells[c]) == 2:
            var circle: MeshInstance3D = MeshInstance3D.new()
            var torus: TorusMesh = TorusMesh.new()
            torus.inner_radius = 0.15
            torus.outer_radius = 0.29
            torus.rings = 24
            torus.ring_segments = 16
            circle.mesh = torus
            circle.rotation.x = PI/2.0
            circle.position.z = 0.058
            circle.material_override = mat(Color("08788c"),true)
            marks[c].add_child(circle)

func pick(pos: Vector2) -> int:
    var begin: Vector3 = camera.project_ray_origin(pos)
    var end: Vector3 = begin + camera.project_ray_normal(pos)*100.0
    var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(begin,end))
    if result.is_empty(): return -1
    return int(result.collider.get_meta("cell",-1))
func reset_view() -> void:
    pivot.rotation = Vector3(0.44,-0.57,0.04)
    camera.position.z = 9.4
func rotate_cube(change: Vector2) -> void:
    pivot.basis = (Basis(Vector3.UP,change.x*0.008)*Basis(Vector3.RIGHT,change.y*0.008)*pivot.basis).orthonormalized()
func zoom(factor: float) -> void:
    camera.position.z = clampf(camera.position.z*factor,6.4,12.4)
