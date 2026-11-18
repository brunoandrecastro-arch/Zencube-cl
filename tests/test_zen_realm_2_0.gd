extends SceneTree
## ZenCube 2.0 Realm acceptance tests: separate tactical achievements and safe gates.
const Campaign = preload("res://core/ZenRealmCampaign2.gd")
const Shadow = preload("res://story/ZenShadowCampaign.gd")
const Abyss = preload("res://story/ZenAbyssCampaign.gd")
const Menu = preload("res://story/ZenRealmChallengeMenu.gd")
var failed: int = 0
var snapshots: Dictionary = {}

func ok(assertion: bool, description: String) -> void:
    if not assertion:
        failed += 1
        printerr("REALM 2.0 FAILED: ",description)

func _initialize() -> void:
    call_deferred("check_all")

func _backup(path: String) -> void:
    if FileAccess.file_exists(path): snapshots[path] = FileAccess.get_file_as_bytes(path)

func _restore() -> void:
    for path in [Campaign.SAVE,Shadow.SAVE,Abyss.SAVE,SaveManager.PATH]:
        if snapshots.has(path):
            var f := FileAccess.open(path,FileAccess.WRITE)
            if f!=null:
                f.store_buffer(snapshots[path])
                f.close()
        elif FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _seed_story(chapter: int, bosses: int, completed: bool) -> void:
    var story: Dictionary = Shadow.defaults() if chapter==0 else Abyss.defaults()
    story.defeated = [bosses>=1,bosses>=2,bosses>=3]
    story.page = 30 if completed else (Shadow.GATES[mini(bosses,2)] if chapter==0 else Abyss.GATES[mini(bosses,2)])
    story.completed = completed
    if chapter==0: ok(Shadow.save_progress(story),"seed Shadow save")
    else: ok(Abyss.save_progress(story),"seed Abyss save")

func check_all() -> void:
    for path in [Campaign.SAVE,Shadow.SAVE,Abyss.SAVE,SaveManager.PATH]:
        _backup(path)
        if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    ok(Campaign.SAVE != Shadow.SAVE and Campaign.SAVE != Abyss.SAVE,
        "Campaign achievements cannot overwrite 30-page Manhwa saves")
    ok(not Campaign.can_unlock(3,2,true),"all 3 challenges are required")
    ok(not Campaign.can_unlock(2,3,true),"all 3 bosses are required")
    ok(not Campaign.can_unlock(3,3,false),"entire Manhwa must be read")
    ok(Campaign.can_unlock(3,3,true),"3+3 plus story unlocks new realm")
    ok(Campaign.unlocked(0),"Shadow always accessible")
    ok(not Campaign.unlocked(1),"Abyss initially locked")
    ok(not Campaign.unlocked(2),"Ember initially locked")
    var lines: Array = ZenAscend.generate_lines()
    ok(lines.size()==204,"real native 4x4 has 204 legal winning lines")
    for chapter in range(2):
        for index in range(3):
            var puzzle: Dictionary = Campaign.puzzle(chapter,index,lines)
            ok(not puzzle.is_empty(),"unique playable 4x4 tactical situation %d,%d" % [chapter,index])
            if puzzle.is_empty(): continue
            ok(puzzle.cells.size()==96,"96 authentic cube cells")
            ok(Campaign.valid_move(puzzle,int(puzzle.target),lines),"native rule engine accepts solution")
            var answer_count: int = 0
            for i in range(96):
                if Campaign.valid_move(puzzle,i,lines): answer_count += 1
            ok(answer_count==1,"challenge has exactly one winning/defensive answer")
            ok(Campaign.task_title(chapter,index)!="","named distinct challenge")
    var baseline: Dictionary = SaveManager.defaults()
    ZenAscend.ensure(baseline)
    ZenAscendRealms.ensure(baseline)
    baseline.ascension.rank = 3
    baseline.ascension.completed = [true,true,true,false,false]
    baseline.ascend.help_seen = true
    baseline.settings.music = false
    ok(SaveManager.save_data(baseline),"save legal 4x4 test access")
    var state: Dictionary = Campaign.defaults()
    ok(Campaign.save_progress(state),"independent achievement file can save")
    _seed_story(0,3,true)
    ok(not Campaign.unlocked(1),"three story bosses alone never unlock Abyss")
    for i in range(2):
        ok(Campaign.record_challenge(0,i),"record approved Shadow tactical achievement "+str(i))
    ok(not Campaign.unlocked(1),"two of three Shadow tasks do not unlock Abyss")
    ok(Campaign.record_challenge(0,2),"third Shadow challenge triggers completion")
    ok(Campaign.unlocked(1),"Shadow 3 bosses + 3 challenges unlock Abyss")
    ok(Campaign.completed_count(Campaign.load_progress(),0)==3,"persist all three Shadow achievements")
    ok(not Campaign.record_challenge(0,2),"duplicate achievement rejected")
    ok(Campaign.enter_next_realm(0),"Shadow breakthrough recorded once")
    ok(Campaign.already_entered(0),"return visits do not replay glass")
    _seed_story(1,3,true)
    ok(not Campaign.unlocked(2),"Abyss bosses without challenges do not unlock Ember")
    for i in range(3): ok(Campaign.record_challenge(1,i),"Abyss challenge "+str(i))
    ok(Campaign.unlocked(2),"Abyss 3+3 unlocks Ember entry")
    ok(Campaign.completed_count(Campaign.load_progress(),1)==3,"persist all three Abyss achievements")
    ok(Campaign.enter_next_realm(1),"Abyss breakthrough may be marked")
    ok(Campaign.already_entered(1),"Ember visit records breakthrough")
    ok(Menu!=null,"independent, real Challenges UI imports")
    # Native match routes: challenges must not increase Classic/normal Realm wins.
    var old_normal: int = int(SaveManager.load_data().get("ascend",{}).get("played",0))
    var old_leaves: int = int(SaveManager.load_data().get("economy",{}).get("leaves",0))
    var scene: PackedScene = load("res://Ascend.tscn") as PackedScene
    ok(scene!=null,"real 3D native Ascend scene loads")
    if scene!=null:
        var original_scene: Node = current_scene
        var controller: Node = scene.instantiate()
        root.add_child(controller)
        current_scene = controller
        await process_frame
        ok(controller.has_method("start_campaign_challenge"),"native 4x4 challenge start is callable")
        # Prior chapters already solved: reset one challenge while preserving unlock.
        var partial: Dictionary = Campaign.load_progress()
        partial.completed[1][2] = false
        ok(Campaign.save_progress(partial),"prepare a real Abyss tactical encounter")
        controller.call("start_campaign_challenge",1,2)
        ok(bool(controller.get("campaign_challenge_active")),"real 3D cube enters Campaign Challenge mode")
        var puzzle: Dictionary = controller.get("campaign_puzzle")
        ok(not puzzle.is_empty(),"native controller received an unsolved tactical puzzle")
        if not puzzle.is_empty():
            var wrong: int = 0
            while wrong==int(puzzle.target) or int(puzzle.cells[wrong])!=0: wrong+=1
            controller.call("_campaign_challenge_play",wrong)
            ok(not Campaign.challenge_done(1,2),"wrong move cannot earn achievement")
            controller.call("_campaign_challenge_play",int(puzzle.target))
            ok(Campaign.challenge_done(1,2),"winning native cube move earns challenge achievement")
        controller.call("_campaign_challenge_back")
        await process_frame
        var chron: Node = root.get_node_or_null("ZenChronicles")
        ok(chron!=null and bool(chron.call("is_open")),"user returns to Challenge menu")
        if chron!=null: chron.call("close_campaign_challenges")
        await process_frame
        controller.queue_free()
        current_scene = original_scene
        await process_frame
    ok(int(SaveManager.load_data().get("ascend",{}).get("played",0))==old_normal,
       "Campaign Challenge cannot count as ranked/ordinary 4x4 match")
    ok(int(SaveManager.load_data().get("economy",{}).get("leaves",0))==old_leaves,
       "Campaign Challenge does not duplicate earned Zen Leaves")
    _restore()
    print("ZENCUBE REALM 2.0 TEST FAILURES=",failed)
    quit(0 if failed==0 else 1)
