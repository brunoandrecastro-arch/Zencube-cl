class_name CubeRenderer
extends Node3D
var pivot: Node3D
var camera: Camera3D
var tiles: Array = []
var marks: Array = []
var overlay: Node3D
var mint = Color("453329")
var peach = Color("16515a") # High-contrast deep jade O across all face colors
var selected: int = -1
func _ready() -> void:
	pivot = Node3D.new()
	add_child(pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0,0,9.3)
	camera.fov = 42
	add_child(camera)
	camera.current = true
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.0,0.0,0.0,0.0)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("fff4e5")
	env.environment.ambient_light_energy = 0.65
	add_child(env)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35,-30,0)
	light.light_energy = 1.1
	add_child(light)
	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(30,140,0)
	fill.light_color = Color("c8ae8b")
	fill.light_energy = 0.6
	add_child(fill)
	# A walnut-colored core fills the narrow seams between the beige face tiles.
	var core = MeshInstance3D.new()
	var core_mesh = BoxMesh.new()
	core_mesh.size = Vector3(3.03,3.03,3.03)
	core.mesh = core_mesh
	core.material_override = material(Color("6a5240"))
	pivot.add_child(core)
	# Minimal stationary sand-and-stone podium evokes a Japanese dry garden.
	# This is decorative geometry only; it never receives picking/collision.
	var plinth = MeshInstance3D.new()
	var plinth_mesh = CylinderMesh.new()
	plinth_mesh.top_radius = 2.24
	plinth_mesh.bottom_radius = 2.34
	plinth_mesh.height = 0.12
	plinth_mesh.radial_segments = 64
	plinth.mesh = plinth_mesh
	plinth.material_override = material(Color("d4c1a2"))
	plinth.position = Vector3(0,-2.34,-0.6)
	add_child(plinth)
	for px in [-2.24,2.21]:
		var pebble = MeshInstance3D.new()
		var stone_mesh = SphereMesh.new()
		stone_mesh.radius = 0.32
		stone_mesh.height = 0.34
		pebble.mesh = stone_mesh
		pebble.material_override = material(Color("aaa28d"))
		pebble.position = Vector3(px,-2.23,-0.7)
		add_child(pebble)
	for c in range(54):
		var f = CubeGeometry.face(c)
		var tile = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.94,0.94,0.08)
		tile.mesh = mesh
		tile.basis = Basis(CubeGeometry.U[f],-CubeGeometry.V[f],CubeGeometry.N[f])
		tile.position = CubeGeometry.center(c)
		var face_base = [Color("c0b69a"),Color("c0b69a"),Color("74805b"),Color("b68165"),Color("e8d0ab"),Color("d8b995")][f]
		tile.material_override = material(face_base)
		pivot.add_child(tile)
		tiles.append(tile)
		var body = StaticBody3D.new()
		body.set_meta("cell",c)
		tile.add_child(body)
		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = mesh.size
		shape.shape = box
		body.add_child(shape)
		var mark = Node3D.new()
		mark.transform = tile.transform
		mark.position += CubeGeometry.N[f]*0.075
		pivot.add_child(mark)
		marks.append(mark)
	overlay = Node3D.new()
	pivot.add_child(overlay)
	reset_view()
func material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.78
	if glow:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat
func reset_view() -> void:
	pivot.rotation = Vector3(0.43,-0.58,-0.04)
	camera.position.z = 9.3
func rotate_cube(delta: Vector2) -> void:
	pivot.basis = (Basis(Vector3.UP,delta.x*0.008)*Basis(Vector3.RIGHT,delta.y*0.008)*pivot.basis).orthonormalized()
func zoom(factor: float) -> void:
	camera.position.z = clampf(camera.position.z*factor,6.3,12.5)
func focus_faces(faces: Array) -> void:
	var normal = Vector3.ZERO
	for f in faces: normal += CubeGeometry.N[int(f)]
	if normal.length() < 0.1: return
	normal = normal.normalized()
	# Transform the selected outward normal to camera-facing +Z.
	pivot.basis = Basis(Quaternion(normal,Vector3(0,0,1)))
func pick(pos: Vector2) -> int:
	var origin = camera.project_ray_origin(pos)
	var ray = PhysicsRayQueryParameters3D.create(origin,origin+camera.project_ray_normal(pos)*100)
	var result = get_world_3d().direct_space_state.intersect_ray(ray)
	if result.is_empty(): return -1
	return result.collider.get_meta("cell",-1)
func bar(parent: Node3D, a: Vector3, b: Vector3, color: Color, width: float = 0.055) -> void:
	var node = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = width
	mesh.bottom_radius = width
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 8
	node.mesh = mesh
	node.material_override = material(color,true)
	node.position = (a+b)*0.5
	var direction = (b-a).normalized()
	node.quaternion = Quaternion(Vector3.UP,direction)
	parent.add_child(node)
func paint(board: BoardModel, hints: bool, preview: Array = [], animate_cell: int = -1) -> void:
	for child in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()
	var rule = RulesEngine.new()
	var tx = rule.threats(board.cells,1) if hints else []
	var to = rule.threats(board.cells,2) if hints else []
	var winning = []
	for line in board.win_lines: winning.append_array(line)
	for c in range(54):
		var color = [Color("c0b69a"),Color("c0b69a"),Color("74805b"),Color("b68165"),Color("e8d0ab"),Color("d8b995")][CubeGeometry.face(c)]
		if tx.has(c): color = Color("b3c2a0")
		if to.has(c): color = Color("d5a58d")
		if preview.has(c): color = Color("c2b094")
		if winning.has(c): color = Color("a5b38e")
		if c == selected: color = color.lightened(0.18)
		tiles[c].material_override = material(color)
		if winning.has(c):
			var pulse = create_tween().set_loops(2)
			pulse.tween_property(tiles[c].material_override,"albedo_color",color.lightened(0.2),0.25)
			pulse.tween_property(tiles[c].material_override,"albedo_color",color,0.35)
		for child in marks[c].get_children():
			marks[c].remove_child(child)
			child.queue_free()
		if board.cells[c] == 1:
			bar(marks[c],Vector3(-0.23,-0.23,0),Vector3(0.23,0.23,0),mint,0.043)
			bar(marks[c],Vector3(-0.23,0.23,0),Vector3(0.23,-0.23,0),mint,0.043)
		elif board.cells[c] == 2:
			# The ivory outer rim and dark-jade inner ring remain legible on
			# terracotta, cream, brown and green cube faces (also at small sizes).
			var border_ring = MeshInstance3D.new()
			var border_torus = TorusMesh.new()
			border_torus.inner_radius = 0.175
			border_torus.outer_radius = 0.325
			border_torus.rings = 32
			border_torus.ring_segments = 12
			border_ring.mesh = border_torus
			border_ring.rotation.x = PI/2
			border_ring.material_override = material(Color("fff0d1"),true)
			marks[c].add_child(border_ring)
			var ring = MeshInstance3D.new()
			var torus = TorusMesh.new()
			torus.inner_radius = 0.205
			torus.outer_radius = 0.295
			torus.rings = 32
			torus.ring_segments = 12
			ring.mesh = torus
			ring.position.z = 0.014
			ring.rotation.x = PI/2
			ring.material_override = material(peach,true)
			marks[c].add_child(ring)
		if c == animate_cell:
			marks[c].scale = Vector3.ONE*0.3
			create_tween().tween_property(marks[c],"scale",Vector3.ONE,0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for line in board.win_lines: draw_line(line,Color("a37e4d"))
	if not preview.is_empty(): draw_line(preview,Color("8f785f"))
func draw_line(line: Array, color: Color) -> void:
	for k in range(line.size()-1):
		var a = line[k]
		var b = line[k+1]
		var p = CubeGeometry.center(a,1.62)
		var q = CubeGeometry.center(b,1.62)
		if CubeGeometry.face(a) == CubeGeometry.face(b): bar(overlay,p,q,color,0.025)
		else:
			var edge = CubeGeometry.edge_point(a,b)
			# Two surface segments, never a chord through the cube interior.
			bar(overlay,p,edge,color,0.025)
			bar(overlay,edge,q,color,0.025)
