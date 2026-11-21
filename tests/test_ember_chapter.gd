extends SceneTree
const DarkKuzeFixture = preload("res://tests/ActFourGateFixture.gd")
# Real Godot end-to-end QA for the entire Ember Temple chapter.
# Covers chapter entry, 3 authentic 4x4 victories, six-boss independent
# save, 3 real boss materials, high-resolution portrait assets, translations,
# the locked public gate and the isolated debug-only preview.
const Story = preload("res://story/ZenRealmChronicles.gd")
const Realms = preload("res://core/ZenAscendRealms.gd")
const Lines = preload("res://core/ZenAscend.gd")
var failed: int = 0
var backups: Dictionary = {}

func check(condition: bool, label: String) -> void:
    if not condition:
        failed += 1
        printerr("EMBER CHAPTER FAIL: ",label)

func _initialize() -> void:
    call_deferred("run")

func _backup(path: String) -> void:
    if FileAccess.file_exists(path):
        backups[path] = FileAccess.get_file_as_bytes(path)

func _restore() -> void:
    for path in [SaveManager.PATH,Story.SAVE]:
        if backups.has(path):
            var fp := FileAccess.open(path,FileAccess.WRITE)
            fp.store_buffer(backups[path])
            fp.close()
        elif FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func run() -> void:
    _backup(SaveManager.PATH)
    _backup(Story.SAVE)
    # Stable test data has real Zen Ascend entitlement, but starts with
    # *no* completed Shadow challenges. The release gate must stay locked.
    var dark_kuze_gate = DarkKuzeFixture.new()
    check(dark_kuze_gate.grant(),"genuine finished Dark Kuze boss fight checkpoint")
    var data: Dictionary = SaveManager.defaults()
    data.ascension.rank = 3
    data.ascension.completed = [true, true, true, false, false] # Real Zen Master entitlement survives ZenAscension.ensure()
    Realms.ensure(data)
    data.ascend.help_seen = true
    var qa_key: String = "application/config/realm_chronicles_qa"
    var prior_qa: bool = bool(ProjectSettings.get_setting(qa_key,false))
    ProjectSettings.set_setting(qa_key,false)
    check(not Story.can_enter(data,3),"public Ember chapter remains gated by 8 Shadow challenges")
    ProjectSettings.set_setting(qa_key,true)
    check(Story.qa_mode(),"separate QA preview flag recognized")
    check(Story.can_enter(data,3),"QA preview can enter Ember only when explicitly enabled")
    ProjectSettings.set_setting(qa_key,false)
    check(not Story.can_enter(data,3),"QA preview cannot leak into normal release")
    for task in Realms.TASKS[0]:
        Realms.state(data).completed[str(task.id)] = true
    check(not Story.can_enter(data,3),"8/8 Shadow challenges alone do not unlock Ember")
    var story_start: Dictionary = Story.defaults()
    story_start.stage = 3
    check(Story.save_progress(story_start),"seed three Shadow victories for legitimate Ember gate")
    check(Story.can_enter(data,3),"eight challenges plus three bosses grant Ember access")
    check(SaveManager.save_data(data),"seed normal game safely")
    var progress: Dictionary = Story.defaults()
    progress.stage = 3
    check(Story.save_progress(progress),"seed only isolated campaign save")
    var packed: PackedScene = load("res://Ascend.tscn") as PackedScene
    check(packed!=null,"real 4x4 scene loads")
    if packed == null:
        ProjectSettings.set_setting(qa_key,prior_qa)
        _restore()
        quit(1)
        return
    var game: Node = packed.instantiate()
    root.add_child(game)
    await process_frame
    var normal_save: String = FileAccess.get_file_as_string(SaveManager.PATH)
    game.call("start_realm_story")
    check(bool(game.get("realm_story_active")),"Chapter 2 launches in 4x4 story mode")
    var cube: Node = game.get("cube")
    var winning_lines: Array = Lines.generate_lines()
    check(winning_lines.size()==204,"existing 204 4x4 winning lines unchanged")
    var profile_names: Array = []
    var first_pixel: Array = []
    for stage in range(3,6):
        check(int(game.get("realm_story_stage"))==stage,"Ember boss order: "+str(stage))
        check(int(game.get("bot_level"))==2,"every Ember boss uses fixed Hard difficulty")
        check(int(cube.get("boss_skin_id"))==stage,"each Ember boss uses its own 3D cube skin")
        check(Story.boss_texture(stage) is ImageTexture,"actual cinematic portrait, not SVG fallback: "+str(stage))
        var texture: Texture2D = Story.boss_texture(stage)
        check(texture.get_width()>=400,"high quality boss image usable on Android "+str(stage))
        profile_names.append(str(Story.BOSS_IDS[stage]))
        var tiles: Array = cube.get("tiles")
        var tile: MeshInstance3D = tiles[0] as MeshInstance3D
        var material: StandardMaterial3D = tile.material_override as StandardMaterial3D
        check(material!=null and material.albedo_texture!=null,"boss skin applied to actual 3D mesh "+str(stage))
        if material!=null and material.albedo_texture!=null:
            first_pixel.append(material.albedo_texture.get_image().get_pixel(60,60))
        for language in ["de","en","pt"]:
            check(not Story.text_for(language,"intro_%d" % stage).is_empty(),"intro localized "+language+" "+str(stage))
            check(not Story.text_for(language,"win_%d" % stage).is_empty(),"win localized "+language+" "+str(stage))
            check(not Story.text_for(language,"loss_%d" % stage).is_empty(),"loss localized "+language+" "+str(stage))
        # The user enters a real match and wins a real 4-mark line.
        game.call("_realm_story_begin")
        var grid: Array = []
        grid.resize(96)
        grid.fill(0)
        var line: Array = winning_lines[3]
        for n in range(3):
            grid[int(line[n])] = 1
        game.set("cells",grid)
        game.set("turn",1)
        game.set("busy",false)
        game.set("result",0)
        game.set("recorded",false)
        game.call("play",int(line[3]))
        check(int(game.get("result"))==1,"actual win recognized for boss "+str(stage))
        var saved: Dictionary = Story.load_progress()
        check(int(saved.stage)==stage and int(saved.game.result)==1,"completed boss fight saved before proceeding "+str(stage))
        check(FileAccess.get_file_as_string(SaveManager.PATH)==normal_save,"boss win does not change main stats/Zen leaves "+str(stage))
        game.call("_realm_story_advance")
        check(int(Story.load_progress().stage)==stage+1,"correct next boss after victory "+str(stage))
    check(profile_names==["ash_runner","banner_guardian","ember_high_priest"],"correct three Ember bosses")
    check(first_pixel.size()==3 and first_pixel[0]!=first_pixel[1] and first_pixel[1]!=first_pixel[2],
        "three unique textures; not the same cube skin reused for every fight")
    var final_progress: Dictionary = Story.load_progress()
    check(int(final_progress.stage)==6,"Ember finale properly completed")
    check(final_progress.game.is_empty(),"completed Chapter 2 has no ghost match to resume")
    check(int(cube.get("boss_skin_id"))==-1,"chapter finale releases boss material")
    game.call("_realm_story_leave")
    final_progress = Story.load_progress()
    check(int(final_progress.stage)==6 and final_progress.game.is_empty(),"leaving final scene retains clean completed progress")
    check(FileAccess.get_file_as_string(SaveManager.PATH)==normal_save,"main saves unchanged after all three Ember bosses")
    game.queue_free()
    ProjectSettings.set_setting(qa_key,prior_qa)
    dark_kuze_gate.restore()
    _restore()
    print("Ember Temple end-to-end test: ",failed," failure(s)")
    quit(1 if failed>0 else 0)
