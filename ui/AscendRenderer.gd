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
var ember_flame_material: ShaderMaterial
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
        core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        core_material.albedo_color = _ember_glow()
        core_material.emission_enabled = true
        core_material.emission = _ember_glow()
        core_material.emission_energy_multiplier = 0.7
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
        m.emission_energy_multiplier = 0.20 if highlight else 0.38
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
        return
    if not is_instance_valid(ember_fire):
        ember_fire = Node3D.new()
        ember_fire.name = "EmberFlameVFX"
        pivot.add_child(ember_fire)
        # Explicit geometry + unshaded shader works without bloom or GPU particles.
        var flame_shader: Shader = Shader.new()
        flame_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;
uniform vec4 flame_tint : source_color = vec4(1.0, 0.35, 0.06, 1.0);
void fragment() {
    float h = 1.0 - UV.y;
    float x = UV.x;
    float t = TIME;
    float wave = sin(x*37.0 + sin(t*3.0+x*10.0)*1.3);
    float tips = 0.28 + 0.44*pow(0.5+0.5*wave,1.8) + 0.12*sin(x*16.0-t*5.0);
    float cut = 1.0-smoothstep(tips-0.10,tips+0.035,h);
    float base = smoothstep(0.0,0.10,h);
    float ends = smoothstep(0.0,0.045,x)*(1.0-smoothstep(0.955,1.0,x));
    float inner = clamp(1.0-h/max(tips,0.1),0.0,1.0);
    vec3 hot = mix(flame_tint.rgb,vec3(1.0,0.9,0.42),smoothstep(0.15,0.85,inner));
    ALBEDO = hot;
    ALPHA = cut*base*ends*(0.72+0.27*inner);
}
"""
        ember_flame_material = ShaderMaterial.new()
        ember_flame_material.shader = flame_shader
        var flame_mesh: QuadMesh = QuadMesh.new()
        flame_mesh.size = Vector2(3.32,1.28)
        for side in range(4):
            var flame: MeshInstance3D = MeshInstance3D.new()
            flame.name = "AnimatedFlame%d" % side
            flame.mesh = flame_mesh
            flame.material_override = ember_flame_material
            flame.position = Vector3(0,2.13,0)
            if side < 2:
                flame.position.z = 1.67 if side == 0 else -1.67
            else:
                flame.position.x = 1.67 if side == 2 else -1.67
                flame.rotation.y = PI*0.5
            ember_fire.add_child(flame)
        # Bright actual 3D outer edges; do not cover the X/O tiles.
        var d: float = 1.64
        for sign_a in [-1.0,1.0]:
            for sign_b in [-1.0,1.0]:
                _rod(ember_fire,Vector3(-d,sign_a*d,sign_b*d),Vector3(d,sign_a*d,sign_b*d),Color("#ff9c36"),0.018)
                _rod(ember_fire,Vector3(sign_a*d,-d,sign_b*d),Vector3(sign_a*d,d,sign_b*d),Color("#ff9c36"),0.018)
                _rod(ember_fire,Vector3(sign_a*d,sign_b*d,-d),Vector3(sign_a*d,sign_b*d,d),Color("#ff9c36"),0.018)
    ember_flame_material.set_shader_parameter("flame_tint",_ember_glow())
    ember_fire.visible = true

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
