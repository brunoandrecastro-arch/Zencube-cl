extends CanvasLayer
## Godot real-time 3D grid transformation, not a pre-rendered video.
## Phase 0: Moon Garden fractures; the old cube remains 3×3 on Shadow page 1.
## Phase 1: after reading that original page, 3×3 physically becomes 4×4.
signal finished

const FRACTURE_SOUND = preload("res://assets/audio/zen_mirror_shatter.wav")
const ASCEND_SOUND = preload("res://assets/audio/zen_realm_breakthrough.wav")
const MOON_ART = preload("res://assets/zen_world_moon.webp")
const SHADOW_ART = preload("res://assets/realms/shadow_realm.webp")
const PORTAL_SHADER := """
shader_type canvas_item;
render_mode unshaded;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float phase = 0.0;
void fragment() {
    vec2 q = (UV - vec2(0.5, 0.50)) * vec2(1.2, 1.0);
    float radius = length(q);
    float halo = exp(-pow((radius-0.29) / 0.035, 2.0));
    float weave = 0.5+0.5*sin(atan(q.y,q.x)*9.0+radius*40.0-phase*4.0);
    float shimmer = halo*mix(0.32,1.0,weave);
    float wave = exp(-pow((radius-0.28-progress*0.50) / 0.06, 2.0));
    COLOR = vec4(0.58+0.28*weave,0.25+0.29*weave,0.93,clamp(shimmer*0.6+wave*0.24,0.0,0.78));
}
"""

var _mode: int = 0
var _time: float = 0.0
var _duration: float = 6.2
var _active: bool = false
var _triggered_sound: bool = false
var _cube3: Node3D
var _cube4: Node3D
var _turner: Node3D
var _portal_material: ShaderMaterial
var _caption: Label
var _skip: Button
var _effect: AudioStreamPlayer
var _lang: String = "en"

func present(mode: int, language: String = "en") -> void:
    _mode = clampi(mode,0,1)
    _lang = language if language in ["de","en","pt"] else "en"
    layer = 160
    var background: ColorRect = ColorRect.new()
    background.color = Color("#0b0b19")
    background.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(background)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var scenic: TextureRect = TextureRect.new()
    scenic.texture = MOON_ART if _mode==0 else SHADOW_ART
    scenic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    scenic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    scenic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scenic.modulate = Color(0.62,0.57,0.74,0.9)
    background.add_child(scenic)
    var shade: ColorRect = ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.035,0.013,0.10,0.54)
    background.add_child(shade)
    var vortex: ColorRect = ColorRect.new()
    vortex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vortex.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var shader: Shader = Shader.new()
    shader.code = PORTAL_SHADER
    _portal_material = ShaderMaterial.new()
    _portal_material.shader = shader
    vortex.material = _portal_material
    background.add_child(vortex)
    # An independent true 3D cube with exact 3×3 and 4×4 face subdivisions.
    var cube_box: SubViewportContainer = SubViewportContainer.new()
    cube_box.stretch = true
    cube_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    cube_box.anchor_left = 0.04
    cube_box.anchor_right = 0.96
    cube_box.anchor_top = 0.21
    cube_box.anchor_bottom = 0.83
    background.add_child(cube_box)
    var viewport: SubViewport = SubViewport.new()
    viewport.size = Vector2i(600,750)
    viewport.transparent_bg = true
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    cube_box.add_child(viewport)
    var stage: Node3D = Node3D.new()
    viewport.add_child(stage)
    var camera: Camera3D = Camera3D.new()
    camera.position = Vector3(3.9,3.1,5.4)
    camera.fov = 48.0
    stage.add_child(camera)
    camera.look_at(Vector3.ZERO,Vector3.UP)
    camera.current = true
    var light: OmniLight3D = OmniLight3D.new()
    light.position = Vector3(2.7,4.6,3.2)
    light.light_color = Color("#c9a9ff")
    light.light_energy = 2.8
    stage.add_child(light)
    var fill: OmniLight3D = OmniLight3D.new()
    fill.position = Vector3(-3.0,-1.0,-1.0)
    fill.light_color = Color("#b869ee")
    fill.light_energy = 1.4
    stage.add_child(fill)
    _turner = Node3D.new()
    stage.add_child(_turner)
    _cube3 = _make_cube(3)
    _cube4 = _make_cube(4)
    _turner.add_child(_cube3)
    _turner.add_child(_cube4)
    _cube4.visible = false
    var info: VBoxContainer = VBoxContainer.new()
    info.anchor_left = 0.05
    info.anchor_right = 0.95
    info.anchor_top = 0.045
    info.anchor_bottom = 0.23
    info.alignment = BoxContainer.ALIGNMENT_CENTER
    background.add_child(info)
    var heading: Label = Label.new()
    heading.text = _words(["THE FRACTURE","DER BRUCH","A FRATURA"]) if _mode==0 else _words(["THE AWAKENING","DAS ERWACHEN","O DESPERTAR"])
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size",31)
    heading.add_theme_color_override("font_color",Color("#e3caf8"))
    info.add_child(heading)
    _caption = Label.new()
    _caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _caption.add_theme_font_size_override("font_size",20)
    _caption.add_theme_color_override("font_color",Color("#f1d9ff"))
    _caption.text = _words(["His journey through darkness had only begun.","Sein Weg durch die Dunkelheit hatte erst begonnen.","A viagem pela escuridão tinha apenas começado."]) if _mode==0 else _words(["The rules have changed.","Die Regeln haben sich verändert.","As regras mudaram."])
    info.add_child(_caption)
    _skip = Button.new()
    _skip.text = _words(["Continue ›","Weiter ›","Continuar ›"])
    _skip.custom_minimum_size.y = 60
    _skip.anchor_left = 0.19
    _skip.anchor_right = 0.81
    _skip.anchor_top = 0.88
    _skip.anchor_bottom = 0.94
    _skip.pressed.connect(_finish)
    background.add_child(_skip)
    _effect = AudioStreamPlayer.new()
    _effect.stream = FRACTURE_SOUND if _mode==0 else ASCEND_SOUND
    _effect.volume_db = -8.0
    add_child(_effect)
    _active = true
    set_process(true)

func _words(options: Array) -> String:
    return options[1] if _lang=="de" else (options[2] if _lang=="pt" else options[0])

func _material(base: Color, glow: float) -> StandardMaterial3D:
    var m: StandardMaterial3D = StandardMaterial3D.new()
    m.albedo_color = base
    m.metallic = 0.23
    m.roughness = 0.38
    if glow>0.0:
        m.emission_enabled = true
        m.emission = base
        m.emission_energy_multiplier = glow
    return m

func _rod(parent: Node3D, a: Vector3, b: Vector3, material: Material, thickness: float) -> void:
    var dir: Vector3 = b-a
    if dir.length()<0.001: return
    var rod: MeshInstance3D = MeshInstance3D.new()
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = thickness
    mesh.bottom_radius = thickness
    mesh.height = dir.length()
    rod.mesh = mesh
    rod.material_override = material
    rod.position = (a+b)*0.5
    rod.basis = Basis(Quaternion(Vector3.UP,dir.normalized()))
    parent.add_child(rod)

func _make_cube(divisions: int) -> Node3D:
    var assembled: Node3D = Node3D.new()
    var box: MeshInstance3D = MeshInstance3D.new()
    var shape: BoxMesh = BoxMesh.new()
    shape.size = Vector3.ONE*2.38
    box.mesh = shape
    box.material_override = _material(Color("#432e58") if divisions==3 else Color("#352246"),0.22)
    assembled.add_child(box)
    var grid: Material = _material(Color("#c290fb") if divisions==4 else Color("#d6a5ea"),0.72)
    var edge: Material = _material(Color("#f4cfac"),0.66)
    var normals: Array[Vector3] = [Vector3.RIGHT,Vector3.LEFT,Vector3.UP,Vector3.DOWN,Vector3.FORWARD,Vector3.BACK]
    for normal in normals:
        var tangent: Vector3 = (normal.cross(Vector3.UP) if absf(normal.y)<0.9 else normal.cross(Vector3.FORWARD)).normalized()
        var upward: Vector3 = normal.cross(tangent).normalized()
        for i in range(divisions+1):
            var d: float = -1.18+2.36*float(i)/float(divisions)
            _rod(assembled,normal*1.205+tangent*d-upward*1.18,normal*1.205+tangent*d+upward*1.18,edge if i in [0,divisions] else grid,0.020 if i in [0,divisions] else 0.012)
            _rod(assembled,normal*1.205+upward*d-tangent*1.18,normal*1.205+upward*d+tangent*1.18,edge if i in [0,divisions] else grid,0.020 if i in [0,divisions] else 0.012)
    # Visible marks echo the last Manhwa page, without changing game state.
    var face: Vector3 = Vector3.FORWARD
    var u: Vector3 = Vector3.RIGHT
    var v: Vector3 = Vector3.UP
    var mark_gold: Material = _material(Color("#f8d6af"),0.9)
    var mark_cyan: Material = _material(Color("#72d5d7"),0.9)
    var center: Vector3 = face*1.235
    var scale_cell: float = 2.36/float(divisions)
    for i in range(4):
        var x: int = (i*2+1)%divisions
        var y: int = (i+1)%divisions
        var pos: Vector3 = center+u*(-1.18+scale_cell*(float(x)+0.5))+v*(-1.18+scale_cell*(float(y)+0.5))
        var half: float = scale_cell*0.18
        if i%2==0:
            _rod(assembled,pos-u*half-v*half,pos+u*half+v*half,mark_gold,0.03)
            _rod(assembled,pos-u*half+v*half,pos+u*half-v*half,mark_gold,0.03)
        else:
            var ring: MeshInstance3D = MeshInstance3D.new()
            var circle: TorusMesh = TorusMesh.new()
            circle.inner_radius = half*0.85
            circle.outer_radius = half*1.1
            ring.mesh = circle
            ring.material_override = mark_cyan
            ring.position = pos
            ring.basis = Basis(Quaternion(Vector3.UP,face))
            assembled.add_child(ring)
    return assembled

func _process(delta: float) -> void:
    if not _active: return
    _time += delta
    var t: float = clampf(_time/_duration,0.0,1.0)
    _turner.rotation.y += delta*0.45
    _turner.rotation.x = 0.13+sin(_time*0.65)*0.10
    _portal_material.set_shader_parameter("phase",_time)
    _portal_material.set_shader_parameter("progress",t)
    if _mode==0:
        _cube3.scale = Vector3.ONE*(1.0+0.10*sin(_time*2.8))
        if t>0.55:
            _cube3.scale *= 1.0-0.45*(t-0.55)/0.45
    else:
        if t>0.47:
            _cube3.visible = false
            _cube4.visible = true
            _cube4.scale = Vector3.ONE*(0.62+0.38*minf(1.0,(t-0.47)/0.31))
            _caption.text = _words(["ZEN ASCEND · 4×4 UNLOCKED","ZEN ASCEND · 4×4 FREIGESCHALTET","ZEN ASCEND · 4×4 DESBLOQUEADO"])
    if not _triggered_sound and _time>=2.6:
        _triggered_sound = true
        if bool(SaveManager.load_data().get("settings",{}).get("sound",true)): _effect.play()
    if t>=1.0: _finish()

func _finish() -> void:
    if not _active: return
    _active = false
    set_process(false)
    if is_instance_valid(_effect): _effect.stop()
    finished.emit()
    queue_free()
