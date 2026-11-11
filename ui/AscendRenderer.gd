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
    if pivot != null and pivot.has_node("CubeCore"):
        var core: MeshInstance3D = pivot.get_node("CubeCore") as MeshInstance3D
        core.material_override = mat(Color(str(skin.core)))
    repaint(active_cells,winner_cells)

func _tile_mat(face_index: int, highlight: bool) -> StandardMaterial3D:
    var base: Color = Color(str(skin.faces[face_index]))
    if highlight: base = base.lightened(0.32)
    var m: StandardMaterial3D = mat(base)
    m.metallic = float(skin.metal)
    m.roughness = float(skin.rough)
    m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    if skin_texture != null: m.albedo_texture = skin_texture
    return m

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
