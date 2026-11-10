extends SceneTree
# Headless regression: five tiers, cumulative wins, streak resets, legacy saves, real menus.
var failures: int = 0
func check(ok: bool, description: String) -> void:
    if not ok:
        failures += 1
        printerr("ZEN STREAK FAIL: " + description)
func match_result(data: Dictionary, level: int, result: int) -> Dictionary:
    var delta: Dictionary = ZenAscension.record_match(data,level,result)
    if result == 1:
        data.stats.ai_wins[level] += 1
    elif result == -1:
        data.stats.ai_losses[level] += 1
    return delta
func count_bars(node: Node) -> int:
    var number: int = 1 if node is ProgressBar else 0
    for child in node.get_children():
        number += count_bars(child)
    return number
func has_label(node: Node, substring: String) -> bool:
    if node is Label and node.text.contains(substring):
        return true
    for child in node.get_children():
        if has_label(child,substring):
            return true
    return false
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var data: Dictionary = SaveManager.defaults()
    ZenAscension.ensure(data)
    check(int(data.ascension.rank)==0,"new player rank 0")
    check(ZenAscension.level_unlocked(data,0),"easy bot unlocked")
    check(not ZenAscension.level_unlocked(data,1),"medium initially locked")
    check(ZenAscension.TARGETS == [3,5,7,3,5], "correct targets")
    for level in range(3):
        var goal: int = ZenAscension.target(level)
        for n in range(goal-1):
            var delta: Dictionary = match_result(data,level,1)
            check(not bool(delta.rank_up),"no early cumulative rank up %d %d" % [level,n])
            check(ZenAscension.progress(data,level)==n+1,"cumulative progress %d %d" % [level,n])
        # Draws/defeats must not wipe cumulative wins.
        match_result(data,level,0)
        match_result(data,level,-1)
        check(ZenAscension.progress(data,level)==goal-1,"cumulative wins survive losses %d" % level)
        var reached: Dictionary = match_result(data,level,1)
        check(bool(reached.rank_up),"rank after required cumulative wins %d" % level)
        check(int(data.ascension.rank)==level+1,"rank unlocked in order %d" % level)
    check(ZenAscension.level_unlocked(data,3),"master bot unlocked")
    # Master: 3 consecutive victories (no draw or loss).
    match_result(data,3,1)
    match_result(data,3,1)
    check(ZenAscension.progress(data,3)==2,"master streak reaches 2/3")
    match_result(data,3,0)
    check(ZenAscension.progress(data,3)==0,"draw resets master streak")
    match_result(data,3,1)
    match_result(data,3,-1)
    check(ZenAscension.progress(data,3)==0,"loss resets master streak")
    for n in range(3):
        var delta: Dictionary = match_result(data,3,1)
        check(bool(delta.rank_up)==(n==2),"master rank only on 3rd uninterrupted win")
    check(int(data.ascension.rank)==4,"sage achieved")
    check(ZenAscension.world_unlocked(data,4),"last world unlocked at sage tier")
    # Grandmaster: 5 consecutive victories. Other difficulties don't advance it.
    for n in range(4): match_result(data,4,1)
    check(ZenAscension.progress(data,4)==4,"grandmaster reaches 4/5")
    match_result(data,1,1)
    check(ZenAscension.progress(data,4)==4,"other bot match does not touch streak")
    match_result(data,4,-1)
    check(ZenAscension.progress(data,4)==0,"grandmaster loss resets 4/5")
    var last_delta: Dictionary = {}
    for n in range(5): last_delta=match_result(data,4,1)
    check(bool(last_delta.rank_up) and int(data.ascension.rank)==5,"guardian awarded on 5 wins in a row")
    check(not bool(match_result(data,4,1).rank_up),"repeat win cannot re-award finished rank")
    # 9.4 migration: old earned ranks must remain, but unfinished streak starts at zero.
    var legacy: Dictionary = SaveManager.defaults()
    legacy.ascension = {"completed":[true,true,true,false,false],"rank":3,"world":3}
    legacy.stats.ai_wins = [1,1,1,2,0]
    ZenAscension.ensure(legacy)
    check(int(legacy.ascension.rank)==3,"previously earned rank is grandfathered")
    check(ZenAscension.progress(legacy,0)==3,"grandfathered stage shown completed")
    check(ZenAscension.progress(legacy,3)==0,"unfinished legacy master streak starts at zero")
    check(int(legacy.ascension.world)==3,"previously selected world preserved")
    match_result(legacy,3,1)
    check(ZenAscension.progress(legacy,3)==1,"new legacy master streak works")
    # Existing completed last tiers remain completed; don't revoke rewards.
    var historic: Dictionary = SaveManager.defaults()
    historic.ascension.completed = [true,true,true,true,true]
    historic.ascension.world = 4
    ZenAscension.ensure(historic)
    check(int(historic.ascension.rank)==5,"legacy zen guardian not revoked")
    # Historical wins count toward the first three newly gated exams.
    var historical: Dictionary = SaveManager.defaults()
    historical.stats.ai_wins = [3,5,6,0,0]
    ZenAscension.ensure(historical)
    check(int(historical.ascension.rank)==2,"existing cumulative wins credited")
    check(ZenAscension.progress(historical,2)==6,"existing hard progress 6/7")
    # UI and game rules still run on the original 54-cell renderer.
    var packed: PackedScene = load("res://Main.tscn") as PackedScene
    check(packed != null,"game main scene present")
    if packed == null:
        quit(1)
        return
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame
    game.data = data.duplicate(true)
    game.refresh()
    check(game.renderer.tiles.size()==54,"unchanged 54 cube cells")
    game.open_ascension()
    check(game.popup != null,"ascension menu opens")
    if game.popup != null:
        check(count_bars(game.popup)==5,"five tier progress bars")
        check(has_label(game.popup,"Geschafft"),"completed German stage label")
    game.data.settings.language = "en"
    game.open_ascension()
    check(has_label(game.popup,"Completed"),"completed English stage label")
    game.data.settings.language = "pt"
    game.open_ascension()
    check(has_label(game.popup,"Concluído"),"completed Portuguese stage label")
    game.close_modal()
    game.queue_free()
    await process_frame
    print("ZEN 9.4.1 STREAK EXAMS FAILURES=",failures)
    quit(0 if failures==0 else 1)
