extends SceneTree
# Standalone Realm Chronicles smoke and regression tests.
const Story = preload("res://story/ZenRealmChronicles.gd")
const BossSkins = preload("res://core/ZenRealmBossSkins.gd")
const Realms = preload("res://core/ZenAscendRealms.gd")
var errors: int = 0
var backups: Dictionary = {}

func check(value: bool, label: String) -> void:
    if not value:
        errors += 1
        printerr("REALM CHRONICLES FAIL: ", label)

func _initialize() -> void:
    call_deferred("run")

func _keep(path: String) -> void:
    if FileAccess.file_exists(path):
        backups[path] = FileAccess.get_file_as_bytes(path)

func _restore() -> void:
    for path in [SaveManager.PATH, Story.SAVE]:
        if backups.has(path):
            var file := FileAccess.open(path,FileAccess.WRITE)
            file.store_buffer(backups[path])
            file.close()
        elif FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func run() -> void:
    _keep(SaveManager.PATH)
    _keep(Story.SAVE)
    check(Story.save_progress(Story.defaults()),"seed empty story for combined gates")
    check(Story.BOSS_IDS.size()==12,"twelve unique story bosses")
    check(BossSkins.PROFILES.size()==12,"twelve unique 3D material profiles")
    check(Story.CHAPTER_ART.size()==4,"four realm overview previews")
    check(Story.LOCALE["en"].size()==Story.LOCALE["de"].size() and Story.LOCALE["en"].size()==Story.LOCALE["pt"].size(),"complete old DE EN PT keys")
    var extra: Dictionary = load("res://story/ZenRealmChroniclesExtra.gd").TEXT
    check(extra["en"].size()==extra["de"].size() and extra["en"].size()==extra["pt"].size(),"complete new chapters DE EN PT keys")
    for stage in range(12):
        check(Story.boss_level(stage) == [1,2,3,4][int(stage/3)],"fixed Medium/Hard/Master/Grandmaster chapter bot tier")
        check(Story.BOSS_IDS.count(Story.BOSS_IDS[stage])==1,"unique boss skin identifier")
        var art_path: String = Story.BOSS_ART[stage]
        check(ResourceLoader.exists(art_path),"Boss illustration included: "+art_path)
        var tex: Texture2D = load(art_path) as Texture2D
        check(tex != null and tex.get_width() >= 600 and tex.get_height() >= 600,
            "full portrait artwork is imported: "+art_path)
        var hd_path: String = Story.BOSS_HD_ART[stage]
        check(FileAccess.file_exists(hd_path),"approved HD boss art stored in repository: "+hd_path)
        if FileAccess.file_exists(hd_path):
            var record: Variant = JSON.parse_string(FileAccess.get_file_as_string(hd_path))
            check(record is Dictionary and str(record.get("format",""))=="webp-base64","correct HD portrait payload "+hd_path)
            if record is Dictionary:
                var raw: PackedByteArray = Marshalls.base64_to_raw(str(record.get("data","")))
                var img: Image = Image.new()
                check(img.load_webp_from_buffer(raw)==OK and img.get_width()>=300,"approved picture decodes as WebP "+hd_path)
                var used: Texture2D = Story.boss_texture(stage)
                check(used is ImageTexture,"game uses cinematic ImageTexture not vector fallback "+hd_path)
        var procedural: Texture2D = BossSkins.make_surface(stage)
        check(procedural != null and procedural.get_width()==160,"Boss tile surface %d" % stage)
    var lines: Array = ZenAscend.generate_lines()
    check(lines.size()==204,"real 4x4 cube still uses exactly 204 win lines")
    var empty: Array = []
    empty.resize(96)
    empty.fill(0)
    for stage in range(12):
        var choice: int = Story.choose_move(empty,lines,stage)
        check(choice >= 0 and choice < 96,"legal opening for boss %d" % stage)
    var data: Dictionary = SaveManager.defaults()
    data.ascension.rank = 3
    data.ascension.completed = [true, true, true, false, false] # Real Zen Master entitlement survives ZenAscension.ensure()
    Realms.ensure(data)
    data.ascend.help_seen = true
    check(Story.can_enter(data,0),"Shadow opens with Zen Master entitlement")
    check(not Story.can_enter(data,3),"Ember must not skip 8/8 existing Shadow challenges")
    for task in Realms.TASKS[0]:
        Realms.state(data).completed[str(task.id)] = true
    check(not Story.can_enter(data,3),"8/8 Shadow challenges do not skip story bosses")
    var gates: Dictionary = Story.defaults()
    gates.stage = 3
    check(Story.save_progress(gates),"record Shadow boss trio")
    check(Story.can_enter(data,3),"Ember requires Shadow 8/8 + 3/3")
    check(not Story.can_enter(data,6),"Celestial remains locked without 8/8 Ember challenges")
    for task in Realms.TASKS[1]:
        Realms.state(data).completed[str(task.id)] = true
    check(not Story.can_enter(data,6),"Ember 8/8 alone not enough")
    gates.stage = 6
    check(Story.save_progress(gates),"record Ember boss trio")
    check(Story.can_enter(data,6),"Celestial requires Ember 8/8 + 3/3")
    check(not Story.can_enter(data,9),"Satori remains locked without 8/8 Celestial challenges")
    for task in Realms.TASKS[2]:
        Realms.state(data).completed[str(task.id)] = true
    check(not Story.can_enter(data,9),"Celestial 8/8 alone not enough")
    gates.stage = 9
    check(Story.save_progress(gates),"record Celestial boss trio")
    check(Story.can_enter(data,9),"Satori requires Celestial 8/8 + 3/3")
    check(SaveManager.save_data(data),"set up isolated test save")
    check(Story.save_progress(Story.defaults()),"seed independent Realm Chronicles progress")
    var scene: PackedScene = load("res://Ascend.tscn") as PackedScene
    check(scene!=null,"Ascend.tscn still intact")
    if scene == null:
        _restore()
        quit(1)
        return
    var controller: Node = scene.instantiate()
    root.add_child(controller)
    await process_frame
    var classic_disk: String = FileAccess.get_file_as_string(SaveManager.PATH)
    controller.call("start_realm_story")
    check(bool(controller.get("realm_story_active")),"story starts on real 4x4 scene")
    check(int(controller.get("realm_story_stage"))==0,"first story starts with Mist Guardian")
    check(int(controller.get("turn"))==1,"first Shadow boss: player begins")
    controller.call("_realm_story_retry")
    check(int(controller.get("turn"))==2,"Shadow boss retry: boss begins")
    controller.call("_realm_story_retry")
    check(int(controller.get("turn"))==1,"Shadow boss second retry: player begins again")
    check(int(Story.load_progress().starts.get("0",0))==3,"starter parity persisted across three starts")
    var renderer: Node = controller.get("cube")
    check(int(renderer.get("boss_skin_id"))==0,"Mist Guardian material is automatic")
    var story_popup: Control = controller.get("active_realm_dialog") as Control
    check(story_popup != null,"boss introduction overlay exists")
    if story_popup != null:
        var story_frame: PanelContainer = story_popup.get_child(1) as PanelContainer
        check(is_equal_approx(story_frame.anchor_top,0.155) and is_equal_approx(story_frame.anchor_bottom,0.845),"boss dialogue is compact on tall Android screens")
        var stack: VBoxContainer = story_frame.get_child(0) as VBoxContainer
        var redundant_back_found: bool = false
        for immediate_child in stack.get_children():
            if immediate_child is Button:
                redundant_back_found = true
        check(not redundant_back_found,"boss dialog no longer duplicates its Back button")
    var tiles: Array = renderer.get("tiles")
    var tile: MeshInstance3D = tiles[0] as MeshInstance3D
    check(tile.material_override is StandardMaterial3D,"3D BoxMesh receives real material")
    var material: StandardMaterial3D = tile.material_override as StandardMaterial3D
    check(material.albedo_texture!=null,"actual textured cube tile, not only background")
    controller.call("_realm_story_begin")
    controller.call("play",4)
    check(int(controller.get("cells")[4])==1,"real 4x4 move recorded")
    check(int(Story.load_progress().game.cells[4])==1,"partial match persisted")
    # Let a pending bot timer finish, then construct a deterministic winning turn.
    await create_timer(0.52).timeout
    var grid: Array = controller.get("cells")
    grid.fill(0)
    var winning: Array = lines[0]
    for j in range(3): grid[int(winning[j])]=1
    controller.set("cells",grid)
    controller.set("turn",1)
    controller.set("result",0)
    controller.set("busy",false)
    controller.call("play",int(winning[3]))
    check(int(controller.get("result"))==1,"real 204-line win detected")
    check(Story.load_progress().game.result==1,"win retained for restart before advancing")
    check(FileAccess.get_file_as_string(SaveManager.PATH)==classic_disk,"story cannot award currency or alter normal Ascend data")
    controller.call("_realm_story_advance")
    check(int(Story.load_progress().stage)==1,"stage advances after an actual win")
    check(int(controller.get("turn"))==2,"second story boss starts with bot")
    check(int(renderer.get("boss_skin_id"))==1,"Mirror Novice automatically gets new skin")
    for stage in range(12):
        controller.call("_realm_story_set_stage",stage)
        check(int(renderer.get("boss_skin_id"))==stage,"skin swapped to boss %d" % stage)
        check(int(controller.get("bot_level"))==[1,2,3,4][int(stage/3)],"fixed Realm bot tier remains unchanged")
    renderer.call("clear_boss_skin")
    check(int(renderer.get("boss_skin_id"))==-1,"normal player skin can be restored")
    controller.call("_realm_story_leave")
    check(FileAccess.get_file_as_string(SaveManager.PATH)==classic_disk,"leaving story preserves normal saves")
    # Normal 4x4 Realm bot matches, not only story bosses, must also alternate.
    controller.call("start_game",true)
    check(int(controller.get("turn"))==1,"ordinary 4x4 bot match starts with human")
    controller.call("start_game",true)
    check(int(controller.get("turn"))==2,"ordinary 4x4 bot rematch starts with bot")
    controller.call("start_game",true)
    check(int(controller.get("turn"))==1,"ordinary 4x4 third match starts with human")
    check(int(controller.get("data").ascend.get("normal_bot_start_counter",0))==3,"ordinary 4x4 starting parity saved")
    controller.queue_free()
    _restore()
    print("Realm Chronicles tests: ",errors," failure(s)")
    quit(1 if errors > 0 else 0)
