extends SceneTree
var failures: int = 0
func check(ok: bool, label: String) -> void:
    if not ok:
        failures += 1
        printerr("ZEN ASCENSION FAIL: " + label)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var progress = ZenAscension.new()
    var data: Dictionary = SaveManager.defaults()
    ZenAscension.ensure(data)
    check(int(data.ascension.rank) == 0, "new account starts at rank zero")
    check(ZenAscension.level_unlocked(data,0),"first level unlocked")
    check(not ZenAscension.level_unlocked(data,1),"second level initially locked")
    var original: Dictionary = data.duplicate(true)
    for i in range(5):
        var delta: Dictionary = ZenAscension.clear_level(data,i)
        check(bool(delta.rank_up), "rank advances after consecutive victory " + str(i))
        check(int(data.ascension.rank) == i+1,"exactly one rank per victory")
        check(ZenAscension.level_unlocked(data,i),"completed level remains unlocked")
        check(ZenAscension.world_unlocked(data,mini(i+1,4)),"world unlocked by victory")
        var before: Array = BoardModel.new().cells
        var move: int = AIEngine.new(128+i).choose(before,2,i,30)
        check(move >= 0 and move < 54 and before[move] == 0,"five difficulty engines return legal moves")
    check(not bool(ZenAscension.clear_level(data,4).rank_up),"repeating win does not re-award rank")
    var old_data: Dictionary = SaveManager.defaults()
    old_data.stats.ai_wins = [1,1,0]
    ZenAscension.ensure(old_data)
    check(int(old_data.ascension.rank)==2,"previous victories migrated")
    var packed := load("res://Main.tscn") as PackedScene
    check(packed != null,"main scene")
    if packed == null:
        quit(1)
        return
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame
    game.data = data.duplicate(true)
    game.refresh()
    check(game.renderer.tiles.size()==54,"54 3D tiles remain")
    check(game.rank_label != null,"rank label available")
    check(game.world_background != null,"world background available")
    check(game.world_background.texture == ZenAscension.WORLD_TEXTURES[4], "highest world art displayed")
    game.open_play_menu()
    check(game.popup != null, "five-level play menu opens")
    game.open_ascension()
    check(game.popup != null,"rank detail opens")
    game.open_worlds()
    check(game.popup != null,"world selection opens")
    game.queue_free()
    await process_frame
    print("ZEN 9.4 ASCENSION FAILURES=",failures)
    quit(0 if failures==0 else 1)
