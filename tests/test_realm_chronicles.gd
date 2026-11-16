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
    check(Story.BOSS_IDS.size()==6,"six unique bosses")
    check(BossSkins.PROFILES.size()==6,"six 3D material profiles")
    check(Story.CHAPTER_ART.size()==4,"four realm overview previews")
    check(Story.LOCALE["en"].size()==Story.LOCALE["de"].size() and Story.LOCALE["en"].size()==Story.LOCALE["pt"].size(),"complete DE EN PT keys")
    for stage in range(6):
        check(Story.boss_level(stage) == (1 if stage < 3 else 2),"fixed Medium/Hard chapter bot tier")
        check(Story.BOSS_IDS.count(Story.BOSS_IDS[stage])==1,"unique boss skin identifier")
        var art_path: String = Story.BOSS_ART[stage]
        check(ResourceLoader.exists(art_path),"Boss illustration included: "+art_path)
        var tex: Texture2D = load(art_path) as Texture2D
        check(tex != null and tex.get_width() >= 600 and tex.get_height() >= 600,
            "full portrait artwork is imported: "+art_path)
        var procedural: Texture2D = BossSkins.make_surface(stage)
        check(procedural != null and procedural.get_width()==160,"Boss tile surface %d" % stage)
    var lines: Array = ZenAscend.generate_lines()
    check(lines.size()==204,"real 4x4 cube still uses exactly 204 win lines")
    var empty: Array = []
    empty.resize(96)
    empty.fill(0)
    for stage in range(6):
        var choice: int = Story.choose_move(empty,lines,stage)
        check(choice >= 0 and choice < 96,"legal opening for boss %d" % stage)
    var data: Dictionary = SaveManager.defaults()
    data.ascension.rank = 3
    Realms.ensure(data)
    data.ascend.help_seen = true
    check(Story.can_enter(data,0),"Shadow opens with Zen Master entitlement")
    check(not Story.can_enter(data,3),"Ember must not skip 8/8 existing Shadow challenges")
    for task in Realms.TASKS[0]:
        Realms.state(data).completed[str(task.id)] = true
    check(Story.can_enter(data,3),"Ember unlocks after existing 8/8 Shadow requirements")
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
    var renderer: Node = controller.get("cube")
    check(int(renderer.get("boss_skin_id"))==0,"Mist Guardian material is automatic")
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
    check(int(renderer.get("boss_skin_id"))==1,"Mirror Novice automatically gets new skin")
    for stage in range(6):
        controller.call("_realm_story_set_stage",stage)
        check(int(renderer.get("boss_skin_id"))==stage,"skin swapped to boss %d" % stage)
        check(int(controller.get("bot_level"))==(1 if stage < 3 else 2),"fixed Realm bot tier remains unchanged")
    renderer.call("clear_boss_skin")
    check(int(renderer.get("boss_skin_id"))==-1,"normal player skin can be restored")
    controller.call("_realm_story_leave")
    check(FileAccess.get_file_as_string(SaveManager.PATH)==classic_disk,"leaving story preserves normal saves")
    controller.queue_free()
    _restore()
    print("Realm Chronicles tests: ",errors," failure(s)")
    quit(1 if errors > 0 else 0)
