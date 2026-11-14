extends SceneTree
# Runtime animation smoke check, no data or game states changed.
var failures: int = 0
func check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        printerr("REALM PORTAL FAIL: " + reason)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var data: Dictionary = SaveManager.defaults()
    data.ascension.rank = 3
    ZenAscendRealms.ensure(data)
    check(not ZenAscendRealms.unlocked(data,1), "Ember locked at 0/8")
    var earned: Dictionary = ZenAscendRealms.state(data).completed
    for i in range(7): earned[str(ZenAscendRealms.TASKS[0][i].id)] = true
    check(not ZenAscendRealms.unlocked(data,1), "Ember locked at 7/8")
    earned[str(ZenAscendRealms.TASKS[0][7].id)] = true
    check(ZenAscendRealms.unlocked(data,1), "Ember unlocked at 8/8")
    var fx: ZenRealmTravelCeremony = ZenRealmTravelCeremony.new()
    root.add_child(fx)
    fx.present(ZenAscendRealms.REALM_ART[0],ZenAscendRealms.REALM_ART[1],"Ember Temple",true,false,[],"en")
    await process_frame
    check(fx.is_inside_tree(), "portal created")
    fx.close()
    await process_frame
    check(not is_instance_valid(fx) or fx.is_queued_for_deletion(), "portal skippable")
    print("ZEN REALM PORTAL FAILURES=", failures)
    quit(0 if failures == 0 else 1)
