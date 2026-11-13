extends SceneTree
# New progression and audio ceremony regression, no real save file writes.
var failures: int = 0
func check(ok: bool, info: String) -> void:
    if not ok:
        failures += 1
        printerr("ZEN ACHIEVEMENTS FAIL: " + info)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var data: Dictionary = SaveManager.defaults()
    ZenAscendRealms.ensure(data)
    ZenAscendAchievements.ensure(data)
    check(ZenAscendAchievements.SECRETS.size() == 16,"16 independently earned badges")
    check(ZenAscendAchievements.main_title(data,0) == "—","no main title on new game")
    check(ZenAscendAchievements.claim_after_match(data,0).is_empty(),"no badges earned at zero")
    var state: Dictionary = ZenAscendRealms.state(data)
    state.stats[0]["wins"] = 2
    var first: Array = ZenAscendAchievements.claim_after_match(data,0)
    check(first.size() == 1 and str(first[0].id) == "shadow_walker","first secret from own statistic")
    check(ZenAscendAchievements.claim_after_match(data,0).is_empty(),"achievement cannot be awarded twice")
    check(ZenAscendAchievements.secret_count(data) == 1,"secret progress persisted")
    for item in ZenAscendRealms.TASKS[0]:
        state.completed[str(item.id)] = true
    check(ZenAscendAchievements.main_title(data,0) == "Master of Shadows","one title at full Realm mastery")
    check(ZenAscendAchievements.main_title(data,1) == "—","no unrelated Realm title")
    var encoded: Variant = JSON.parse_string(JSON.stringify(data))
    check(encoded is Dictionary,"new secret save serializable")
    if encoded is Dictionary:
        ZenAscendAchievements.ensure(encoded)
        check(ZenAscendAchievements.earned(encoded,"shadow_walker"),"secret survives reload")
    var effect: ZenUnlockCeremony = ZenUnlockCeremony.new()
    root.add_child(effect)
    effect.present("achievement",ZenAscendRealms.REALM_ART[0],"Shadow Walker","The journey begins.",false,[])
    await process_frame
    check(effect.is_inside_tree(),"choir ceremony created without external audio")
    effect.close()
    await process_frame
    check(not is_instance_valid(effect) or effect.is_queued_for_deletion(),"ceremony is skippable and released")
    print("ZEN PREMIUM ACHIEVEMENTS FAILURES=",failures)
    quit(0 if failures == 0 else 1)
