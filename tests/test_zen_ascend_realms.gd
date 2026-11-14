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
    for realm_id in range(4):
        check(Realms.fixed_bot_level(realm_id) == realm_id + 1,"fixed Realm difficulty %d" % realm_id)
    var data: Dictionary = SaveManager.defaults()
    var preexisting_classic: Dictionary = data.stats.duplicate(true)
    Realms.ensure(data)
    check(int(Realms.state(data).selected)==0,"shadow selected by default")
    check(Realms.unlocked(data,0) == ZenAscend.test_access_enabled(),"free Shadow Realm only in debug")
    check(not ZenAscend.unlocked_for_release(data),"release keeps its unlock requirement")
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
    # A high win count alone cannot skip a Realm. Every previous
    # Realm must have exactly eight challenges completed.
    var gate_data: Dictionary = SaveManager.defaults()
    gate_data.ascension.rank = 3
    Realms.ensure(gate_data)
    Realms.state(gate_data).stats[0]["wins"] = 99
    check(not Realms.unlocked(gate_data,1),"winning many Shadow matches does not unlock Ember early")
    var earned: Dictionary = Realms.state(gate_data).completed
    for i in range(7):
        earned[str(Realms.TASKS[0][i].id)] = true
    check(not Realms.unlocked(gate_data,1),"Shadow 7/8 stays locked")
    earned[str(Realms.TASKS[0][7].id)] = true
    check(Realms.unlocked(gate_data,1),"Ember unlocks at Shadow 8/8")
    check(Realms.select(gate_data,1),"select unlocked Ember Temple")
    check(int(Realms.state(gate_data).selected)==1,"Ember selection persisted")
    for i in range(7): earned[str(Realms.TASKS[1][i].id)] = true
    Realms.state(gate_data).stats[1]["wins"] = 30
    check(not Realms.unlocked(gate_data,2),"Ember 7/8 stays locked even after many wins")
    earned[str(Realms.TASKS[1][7].id)] = true
    check(Realms.unlocked(gate_data,2),"Celestial unlocks at Ember 8/8")
    for i in range(7): earned[str(Realms.TASKS[2][i].id)] = true
    Realms.state(gate_data).stats[2]["wins"] = 30
    check(not Realms.unlocked(gate_data,3),"Celestial 7/8 stays locked regardless of wins")
    earned[str(Realms.TASKS[2][7].id)] = true
    check(Realms.unlocked(gate_data,3),"Satori unlocks at Celestial 8/8")
    for task in Realms.TASKS[0]:
        Realms.state(data).completed[str(task.id)] = true
    check(Realms.select(data,1),"original save can still select completed Shadow destination")
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
