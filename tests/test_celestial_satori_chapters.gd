extends SceneTree
# Complete 4x4 Celestial + Satori story, 6 sequential real four-in-a-row
# victories, 6 distinct 3D tile skins, image decoding, saves and exact
# Master/Grandmaster AI stages. Never writes ordinary player rewards.
const Story = preload("res://story/ZenRealmChronicles.gd")
const Realms = preload("res://core/ZenAscendRealms.gd")
const CubeRules = preload("res://core/ZenAscend.gd")
const BossSkins = preload("res://core/ZenRealmBossSkins.gd")
const Extra = preload("res://story/ZenRealmChroniclesExtra.gd")
var failures: int = 0
var backed_up: Dictionary = {}

func assert_ok(condition: bool, label: String) -> void:
    if not condition:
        failures += 1
        printerr("CELESTIAL SATORI FAIL: ",label)

func _initialize() -> void:
    call_deferred("run")

func _backup(path: String) -> void:
    if FileAccess.file_exists(path):
        backed_up[path] = FileAccess.get_file_as_bytes(path)

func _restore() -> void:
    for path in [SaveManager.PATH,Story.SAVE]:
        if backed_up.has(path):
            var fp := FileAccess.open(path,FileAccess.WRITE)
            if fp != null:
                fp.store_buffer(backed_up[path])
                fp.close()
        elif FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func run() -> void:
    _backup(SaveManager.PATH)
    _backup(Story.SAVE)
    var qa_key: String = "application/config/realm_chronicles_qa"
    var previous_qa: bool = bool(ProjectSettings.get_setting(qa_key,false))
    ProjectSettings.set_setting(qa_key,false)
    assert_ok(Story.save_progress(Story.defaults()),"seed empty Realm Chronicles to test combined gates")
    var data: Dictionary = SaveManager.defaults()
    data.ascension.rank = 3
    Realms.ensure(data)
    data.ascend.help_seen = true
    for realm in range(3):
        assert_ok(not Story.can_enter(data,(realm+1)*3),"story chapter %d truly gated before previous challenges" % (realm+2))
        for task in Realms.TASKS[realm]:
            Realms.state(data).completed[str(task.id)] = true
        assert_ok(not Story.can_enter(data,(realm+1)*3),"8/8 alone cannot open story realm %d" % (realm+2))
        var past: Dictionary = Story.load_progress()
        past.stage = (realm+1)*3
        assert_ok(Story.save_progress(past),"record three boss wins before next realm")
        assert_ok(Story.can_enter(data,(realm+1)*3),"chapter %d unlocks after challenges plus bosses" % (realm+2))
    assert_ok(Story.LAST_STAGE==12 and Story.BOSS_IDS.size()==12,"all four chapters have 12 bosses")
    assert_ok(BossSkins.PROFILES.size()==12,"twelve boss-specific 3D material profiles")
    assert_ok(Extra.TEXT["de"].size()==Extra.TEXT["en"].size() and Extra.TEXT["en"].size()==Extra.TEXT["pt"].size(),"complete chapter 3+4 localization")
    # v1 is reused to avoid wiping someone who completed Ember already.
    var progress: Dictionary = Story.defaults()
    progress.stage = 6
    progress.introduced = {"0":true,"5":true}
    assert_ok(Story.save_progress(progress),"store legacy Ember-complete progress at stage 6")
    var migrated: Dictionary = Story.load_progress()
    assert_ok(int(migrated.stage)==6 and bool(migrated.introduced.get("5",false)),"existing Chapter 2 progress is preserved")
    # Do not launch the cinematic transition during the deterministic
    # six-boss engine test; transitions have their own dedicated tests.
    Realms.state(data)["auto_transitions"] = {"0":true,"1":true,"2":true}
    assert_ok(SaveManager.save_data(data),"seed ordinary stats for no-reward regression")
    var scene: PackedScene = load("res://Ascend.tscn") as PackedScene
    assert_ok(scene!=null,"existing 4x4 game scene loads")
    if scene==null:
        ProjectSettings.set_setting(qa_key,previous_qa)
        _restore()
        quit(1)
        return
    var game: Node = scene.instantiate()
    root.add_child(game)
    await process_frame
    var ordinary_save: String = FileAccess.get_file_as_string(SaveManager.PATH)
    game.call("start_realm_story")
    assert_ok(bool(game.get("realm_story_active")),"Celestial Story starts on actual 4x4 cube")
    var renderer: Node = game.get("cube")
    var lines: Array = CubeRules.generate_lines()
    assert_ok(lines.size()==204,"all original 4x4 winning lines are unchanged")
    var last_skin: Color = Color.TRANSPARENT
    for stage in range(6,12):
        assert_ok(int(game.get("realm_story_stage"))==stage,"next boss in correct chronological order "+str(stage))
        assert_ok(int(game.get("match_realm"))==int(stage/3),"story controls correct matching realm "+str(stage))
        assert_ok(int(game.get("bot_level"))==[1,2,3,4][int(stage/3)],"real Master/Grandmaster bot level "+str(stage))
        assert_ok(int(renderer.get("boss_skin_id"))==stage,"real 3D mesh changes to boss-specific skin "+str(stage))
        var hd_path: String = Story.BOSS_HD_ART[stage]
        assert_ok(FileAccess.file_exists(hd_path),"approved cinematic boss art included "+str(stage))
        var image: Texture2D = Story.boss_texture(stage)
        assert_ok(image is ImageTexture and image.get_width()>=400,"genuine readable boss picture "+str(stage))
        var tiles: Array = renderer.get("tiles")
        var tile: MeshInstance3D = tiles[0] as MeshInstance3D
        var material: StandardMaterial3D = tile.material_override as StandardMaterial3D
        assert_ok(material != null and material.albedo_texture != null,"real BoxMesh textured on stage "+str(stage))
        if material != null and material.albedo_texture != null:
            var pixel: Color = material.albedo_texture.get_image().get_pixel(80,75)
            assert_ok(stage==6 or pixel!=last_skin,"each boss gets a different visible 3D texture "+str(stage))
            last_skin = pixel
        for language in ["de","en","pt"]:
            for key in ["boss_","intro_","win_","loss_","react_"]:
                assert_ok(not Story.text_for(language,key+str(stage)).is_empty(),"translated "+language+" "+key+str(stage))
        # Simulate a real game: enter the battle, place 3 symbols on a legal
        # winning line, and tap the fourth cell via the gameplay method.
        game.call("_realm_story_begin")
        var board: Array = []
        board.resize(96)
        board.fill(0)
        var winning: Array = lines[stage+3]
        for i in range(3): board[int(winning[i])] = 1
        game.set("cells",board)
        game.set("turn",1)
        game.set("result",0)
        game.set("recorded",false)
        game.set("busy",false)
        game.call("play",int(winning[3]))
        assert_ok(int(game.get("result"))==1,"real four-in-a-row wins against boss "+str(stage))
        var checkpoint: Dictionary = Story.load_progress()
        assert_ok(int(checkpoint.stage)==stage and int(checkpoint.game.result)==1,"battle wins saved before player continues "+str(stage))
        assert_ok(FileAccess.get_file_as_string(SaveManager.PATH)==ordinary_save,"ordinary achievements and Zen currency unchanged "+str(stage))
        game.call("_realm_story_advance")
        assert_ok(int(Story.load_progress().stage)==stage+1,"story advances only after actual boss win "+str(stage))
        if stage in [8]:
            assert_ok(int(renderer.get("boss_skin_id"))==-1,"Celestial chapter outro clears equipped boss skin")
            assert_ok(Story.load_progress().game.is_empty(),"Celestial chapter boundary has no ghost match")
            game.call("_realm_story_start_chapter",stage+1)
    assert_ok(int(Story.load_progress().stage)==12,"final boss completes all four realms")
    assert_ok(Story.load_progress().game.is_empty(),"complete campaign save has no phantom final match")
    assert_ok(int(renderer.get("boss_skin_id"))==-1,"final Satori boss skin is released after ending")
    assert_ok(not Story.text_for("de","chapter4_end").is_empty(),"Satori finale text exists")
    game.call("_realm_story_leave")
    assert_ok(int(Story.load_progress().stage)==12 and Story.load_progress().game.is_empty(),"completed progress survives leaving and relaunching")
    assert_ok(FileAccess.get_file_as_string(SaveManager.PATH)==ordinary_save,"normal game entirely unchanged after six battles")
    game.queue_free()
    ProjectSettings.set_setting(qa_key,previous_qa)
    _restore()
    print("Celestial and Satori 6-boss end-to-end tests: ",failures," failure(s)")
    quit(1 if failures>0 else 0)
