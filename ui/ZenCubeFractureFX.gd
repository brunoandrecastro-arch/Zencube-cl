extends Node3D
## Deterministic, performance-bounded physical shard animation for ZenCube.
## Godot GL Compatibility. No extra textures, no particle plugin, no new gameplay state.
var old_shards: Array[Dictionary] = []
var new_shards: Array[Dictionary] = []
var old_root: Node3D
var new_root: Node3D
var ring: MeshInstance3D
var ring_material: StandardMaterial3D

func build() -> void:
    old_root = Node3D.new()
    old_root.name = "Fractured3x3"
    add_child(old_root)
    new_root = Node3D.new()
    new_root.name = "Reforming4x4"
    add_child(new_root)
    _create_shell(3, old_root, old_shards)
    _create_shell(4, new_root, new_shards)
    old_root.visible = false
    new_root.visible = false
    ring = MeshInstance3D.new()
    ring.name = "AscensionShockwave"
    var mesh: TorusMesh = TorusMesh.new()
    mesh.inner_radius = 1.75
    mesh.outer_radius = 1.81
    ring.mesh = mesh
    ring_material = StandardMaterial3D.new()
    ring_material.albedo_color = Color("#d7a4ff")
    ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    ring_material.emission_enabled = true
    ring_material.emission = Color("#d7a4ff")
    ring_material.emission_energy_multiplier = 2.6
    ring.material_override = ring_material
    ring.rotation_degrees = Vector3(63,13,19)
    ring.visible = false
    add_child(ring)

func _create_shell(n: int, parent: Node3D, pieces: Array[Dictionary]) -> void:
    var step: float = 2.34/float(n)
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = Vector3.ONE*(step*0.92)
    var wood: StandardMaterial3D = StandardMaterial3D.new()
    wood.albedo_color = Color("#aa795b") if n==3 else Color("#563579")
    wood.metallic = 0.28
    wood.roughness = 0.44
    wood.emission_enabled = true
    wood.emission = Color("#f6ab63") if n==3 else Color("#a568f5")
    wood.emission_energy_multiplier = 0.38 if n==3 else 0.60
    var accent: StandardMaterial3D = StandardMaterial3D.new()
    accent.albedo_color = Color("#d5a36d") if n==3 else Color("#8951b4")
    accent.emission_enabled = true
    accent.emission = Color("#ffc986") if n==3 else Color("#d2aaff")
    accent.emission_energy_multiplier = 0.95
    var i: int = 0
    for x in range(n):
        for y in range(n):
            for z in range(n):
                if x>0 and x<n-1 and y>0 and y<n-1 and z>0 and z<n-1: continue
                var home: Vector3 = Vector3(float(x)-(float(n-1)*0.5),float(y)-(float(n-1)*0.5),float(z)-(float(n-1)*0.5))*step
                var direction: Vector3 = Vector3(sin(float(i)*2.399+0.32),cos(float(i)*1.871+0.2),sin(float(i)*3.118+1.3)).normalized()
                var burst: Vector3 = home*1.55+direction*(2.1+0.77*absf(sin(float(i)*0.79)))
                var spin: Vector3 = Vector3(1.1+float(i%4)*0.5,1.3+float(i%5)*0.42,0.7+float(i%3)*0.39)
                var shard: MeshInstance3D = MeshInstance3D.new()
                shard.mesh = mesh
                shard.material_override = accent if (i%7==0) else wood
                shard.position = home
                parent.add_child(shard)
                pieces.append({"node":shard,"home":home,"burst":burst,"spin":spin})
                i+=1

func fracture(amount: float) -> void:
    old_root.visible = true
    new_root.visible = false
    var p: float = clampf(amount,0.0,1.0)
    var eased: float = 1.0-pow(1.0-p,2.3)
    for item in old_shards:
        var shard: MeshInstance3D = item["node"] as MeshInstance3D
        shard.position = (item["home"] as Vector3).lerp(item["burst"] as Vector3,eased)
        shard.rotation = (item["spin"] as Vector3)*eased*1.55
        shard.scale = Vector3.ONE*(1.0-0.38*p)

func assemble(amount: float) -> void:
    old_root.visible = false
    new_root.visible = true
    var p: float = clampf(amount,0.0,1.0)
    var eased: float = p*p*(3.0-2.0*p)
    for item in new_shards:
        var shard: MeshInstance3D = item["node"] as MeshInstance3D
        shard.position = (item["burst"] as Vector3).lerp(item["home"] as Vector3,eased)
        shard.rotation = (item["spin"] as Vector3)*(1.0-eased)*1.8
        shard.scale = Vector3.ONE*(0.46+0.54*eased)

func shockwave(amount: float) -> void:
    ring.visible = true
    var p: float = clampf(amount,0.0,1.0)
    ring.scale = Vector3.ONE*(0.2+3.35*p)
    ring_material.albedo_color.a = 1.0-p
    ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func hide_effects() -> void:
    if old_root!=null: old_root.visible = false
    if new_root!=null: new_root.visible = false
    if ring!=null: ring.visible = false
