extends SceneTree
# Full QA acceptance checks: 16 different boss stages, real 5x5 four-in-row,
# unique imported backgrounds, progressive unlocking and Satori bridge.
const Data = preload("res://core/ZenMasterCampaignData.gd")
const Catalog = preload("res://core/ZenMasterStageCatalog.gd")
const AI = preload("res://core/ZenMasterBossAI.gd")
const Mode = preload("res://core/ZenMaster.gd")
var failed: int = 0
func check(ok: bool, label: String) -> void:
    if not ok:
        failed += 1
        printerr("CAMPAIGN QA FAILURE: " + label)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    check(Data.validate(), "complete 16-boss Kuze story references unique arenas")
    check(Catalog.validate(), "16 unique stage IDs and paths")
    check(Catalog.all_arena_art_imported(), "ALL 16 unique vector boss backgrounds available")
    check(Data.BOSSES.size() == 16, "16 bosses in 4 chapters")
    check(Data.REALMS.size() == 4, "4 realms")
    check(Mode.generate_lines().size() == 348, "4 in a row on 5x5 = 348 lines")
    check(Data.is_unlocked(0,0), "first boss unlocked")
    check(not Data.is_unlocked(1,0), "second boss locked before victory")
    check(Data.is_unlocked(1,1), "second boss unlocked after first victory")
    check(not Data.is_unlocked(4,3), "second realm locked until first end boss")
    check(Data.is_unlocked(4,4), "second realm unlocked on fourth win")
    check(not Data.is_unlocked(16,16), "no seventeenth boss")
    var scene: PackedScene = load("res://ZenMasterCampaign.tscn") as PackedScene
    check(scene != null, "campaign scene loads")
    if scene == null:
        quit(1)
        return
    var game: Node = scene.instantiate()
    root.add_child(game)
    await process_frame
    check(int((game.get("tiles") as Array).size()) == 150, "150 interactive 3D cells")
    check(int((game.get("current_stage") as int)) == 0, "start on first Void boss")
    check(bool(game.get("story_layer").visible), "boss intro visible before battle")
    var distinct: Dictionary = {}
    var portraits: Dictionary = {}
    game.set("qa_preview",true)
    for i in range(16):
        game.call("_choose_stage",i,false)
        var svg: Texture2D = game.get("stage_backdrop").texture as Texture2D
        check(svg != null, "boss " + str(i) + " owns its own loaded artwork")
        if svg != null:
            distinct[svg.resource_path] = true
        var boss: Dictionary = Data.BOSSES[i]
        var art: Dictionary = Catalog.stage_for(boss["id"])
        var pic: Texture2D = load(art["portrait"]) as Texture2D
        check(pic != null, "boss " + str(i) + " has its own portrait")
        if pic != null:
            portraits[pic.resource_path] = true
        check(game.get("cells").size() == 150, "boss " + str(i) + " uses 5x5 board")
    check(distinct.size() == 16, "sixteen distinct loaded arena textures")
    check(portraits.size() == 16, "sixteen distinct loaded portrait textures")
    var empty: Array = []
    empty.resize(150)
    empty.fill(0)
    for stage in range(16):
        var move: int = AI.choose(empty,Mode.generate_lines(),stage)
        check(move >= 0 and move < 150, "boss AI makes legal move for stage "+str(stage))
        check(empty.count(0) == 150, "AI never mutates game board")
    game.call("_choose_stage",0,false)
    game.call("_restart",true)
    for c in [0,1,2]:
        game.get("cells")[c] = 1
        game.call("_paint_mark",c,1)
    game.call("_play_move",3)
    check(int(game.get("winner")) == 1, "FOUR marks win on a 5x5 face")
    check(int(game.get("cleared")) >= 1, "victory unlocks next boss")
    check(Data.is_unlocked(1,int(game.get("cleared"))), "boss 2 accessible immediately")
    check(ZenAscend.generate_lines().size() == 204, "4x4 main mode untouched")
    game.queue_free()
    await process_frame
    print("ZEN MASTER CAMPAIGN CHECK FAILURES=",failed)
    quit(0 if failed == 0 else 1)
