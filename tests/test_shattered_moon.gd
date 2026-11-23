extends SceneTree
const Moon = preload("res://story/ZenShatteredMoonCampaign.gd")
var errors := 0
func check(condition: bool, msg: String) -> void:
    if not condition:
        errors += 1
        printerr("SHATTERED MOON FAIL: ",msg)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    check(Moon.BOSS_IDS == ["echo_keeper","silent_ferryman","moon_warden"],"boss identities")
    check(Moon.BOSS_NAMES.size() == 3,"three bosses")
    check(Moon.GATES == [9,18,24],"story battle gates")
    for page in range(1,31):
        check(ResourceLoader.exists(Moon.page_path(page)),"missing page %d" % page)
    for i in range(3):
        check(Moon.boss_art(i) != null,"boss portrait %d" % i)
        check(Moon.battle_backdrop(i) != null,"boss arena %d" % i)
    var state: Dictionary = Moon.defaults()
    check(Moon.page_limit(state)==9,"first gate")
    state.page = 9
    check(Moon.next_action(state).get("type")=="battle","first boss gate")
    state.defeated = [true,false,false]
    check(Moon.page_limit(state)==18,"second gate")
    state.page = 18
    check(int(Moon.next_action(state).get("boss",-1))==1,"second boss")
    state.defeated = [true,true,false]
    check(Moon.page_limit(state)==24,"third gate")
    state.page = 24
    check(int(Moon.next_action(state).get("boss",-1))==2,"third boss")
    state.defeated = [true,true,true]
    check(Moon.page_limit(state)==30,"complete gate")
    print("SHATTERED MOON TEST FAILURES=",errors)
    quit(0 if errors==0 else 1)
