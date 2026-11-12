extends SceneTree
# Test new 4x4 realm progression on headless Godot without changing user save data.
const Realms = preload("res://core/ZenAscendRealms.gd")
const Bot = preload("res://core/ZenAscendRealmBot.gd")
var fail: int = 0
func check(value: bool, reason: String) -> void:
    if not value:
        fail += 1
        printerr("REALMS FAIL: "+reason)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var count_all: int = 0
    var keys: Dictionary = {}
    for realm in range(4):
        check(Realms.TASKS[realm].size()==8,"eight tasks per realm %d" % realm)
        for task in Realms.TASKS[realm]:
            count_all += 1
            check(not keys.has(str(task.id)),"unique challenge id")
            keys[str(task.id)] = true
            check(str(task.de).length()>5 and str(task.en).length()>5 and str(task.pt).length()>5,"DE/EN/PT task copy")
    check(count_all==32,"32 challenges")
    var data: Dictionary = SaveManager.defaults()
    var preexisting_classic: Dictionary = data.stats.duplicate(true)
    Realms.ensure(data)
    check(int(Realms.state(data).selected)==0,"shadow selected by default")
    check(not Realms.unlocked(data,0),"4x4 is gated")
    data.ascension.rank = 3
    check(Realms.unlocked(data,0),"shadow entry after Zen Master")
    check(not Realms.unlocked(data,1),"ember initially locked")
    var geometry: Array = ZenAscend.generate_lines()
    check(geometry.size()==204,"untouched winning line geometry")
    var grid: Array = []
    grid.resize(96)
    grid.fill(0)
    var edge_line: Array = geometry[60]
    check(Realms.is_edge_line(edge_line),"edge line detected")
    check(not Realms.is_edge_line(geometry[0]),"face line detected")
    var defensive_line: Array = geometry[0]
    for i in range(3): grid[int(defensive_line[i])] = 2
    check(Realms.prevents_immediate_win(grid,geometry,1,int(defensive_line[3])),"real threat blocked")
    check(not Realms.prevents_immediate_win(grid,geometry,1,95),"unrelated cell is not a block")
    check(Bot.next_move(grid,geometry,2,4)==int(defensive_line[3]),"grandmaster chooses immediate victory")
    check(Bot.next_move(grid,geometry,1,4)==int(defensive_line[3]),"grandmaster blocks immediate loss")
    grid.fill(0)
    var leaves_before: int = int(data.economy.leaves)
    var first: Dictionary = Realms.record_bot_match(data,0,1,2,16,[edge_line],true)
    check(first.new_tasks.size()>0,"genuine win awards challenges")
    check(int(data.economy.leaves)>leaves_before,"earned Zen Leaves")
    check(Realms.count(data,0)>=4,"shadow basic challenge progress")
    # Previous rewards don't repeat on another real match.
    var finished_ids: Array = first.new_tasks.duplicate()
    var first_reward: int = int(first.leaves)
    var second: Dictionary = Realms.record_bot_match(data,0,1,2,20,[edge_line],false)
    check(int(second.leaves)<first_reward,"no re-award of already claimed tasks")
    for id in finished_ids:
        check(not second.new_tasks.has(id),"individual task never paid twice")
    for i in range(3): Realms.record_bot_match(data,0,1,0,20,[geometry[0]],false)
    check(Realms.unlocked(data,1),"ember unlocks after 5 Shadow wins")
    check(not Realms.unlocked(data,2),"celestial remains locked")
    check(Realms.select(data,1),"select unlocked Ember Temple")
    check(int(Realms.state(data).selected)==1,"selected realm saved in data")
    for i in range(7): Realms.record_bot_match(data,1,1,0,23,[geometry[0]],false)
    check(Realms.unlocked(data,2),"Celestial opens after 7 Ember wins")
    check(not Realms.unlocked(data,3),"Satori requires both gates")
    # One prerequisite alone is insufficient for Satori.
    var realm_data: Dictionary = Realms.state(data)
    realm_data.stats[2]["wins"] = 10
    check(not Realms.unlocked(data,3) or Realms.total_count(data)>=12,"Satori AND condition")
    # Grant 12 legitimate completed challenges to satisfy the second condition.
    var earned: Dictionary = Realms.state(data).completed
    var needed: int = maxi(0,12-Realms.total_count(data))
    for task in Realms.TASKS[2]:
        if needed <= 0: break
        if not bool(earned.get(str(task.id),false)):
            earned[str(task.id)] = true
            needed -= 1
    check(Realms.unlocked(data,3),"Satori unlock requires 10 Celestial wins and 12 challenges")
    check(Realms.total_count(data)>=12,"overall completion count")
    check(data.stats==preexisting_classic,"Classic stats untouched")
    var json: String = JSON.stringify(data)
    var loaded: Variant = JSON.parse_string(json)
    check(loaded is Dictionary,"progression serializable")
    if loaded is Dictionary:
        Realms.ensure(loaded)
        check(int(Realms.state(loaded).selected)==1,"realm choice survives JSON restoration")
        check(Realms.count(loaded,0)==Realms.count(data,0),"challenge flags survive JSON restoration")
        check(int(loaded.economy.leaves)==int(data.economy.leaves),"leaves survive JSON restoration")
    var scene: PackedScene = load("res://Ascend.tscn") as PackedScene
    check(scene!=null,"4x4 scene retained")
    print("ZEN ASCEND REALMS FAILURES=",fail)
    quit(1 if fail>0 else 0)
