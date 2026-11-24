extends SceneTree
const Realm2 = preload("res://core/ZenRealmCampaign2.gd")
# New progression and audio ceremony regression, no real save file writes.
var failures: int = 0
func check(ok: bool, info: String) -> void:
    if not ok:
        failures += 1
        printerr("ZEN ACHIEVEMENTS FAIL: " + info)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var abyss_existed: bool = FileAccess.file_exists(Realm2.SAVE)
    var abyss_backup: PackedByteArray = FileAccess.get_file_as_bytes(Realm2.SAVE) if abyss_existed else PackedByteArray()
    var abyss_progress: Dictionary = Realm2.defaults()
    check(Realm2.save_progress(abyss_progress),"isolated Abyss achievement fixture")
    var data: Dictionary = SaveManager.defaults()
    ZenAscendRealms.ensure(data)
    ZenAscendAchievements.ensure(data)
    check(ZenAscendAchievements.SECRETS.size() == 20,"20 independently earned badges, including four Abyss badges")
    check(ZenAscendAchievements.main_title(data,0) == "—","no main title on new game")
    check(ZenAscendAchievements.claim_after_match(data,0).is_empty(),"no badges earned at zero")
    var state: Dictionary = ZenAscendRealms.state(data)
    state.stats[0]["wins"] = 2
    var first: Array = ZenAscendAchievements.claim_after_match(data,0)
    check(first.size() == 1 and str(first[0].id) == "shadow_walker","first secret from own statistic")
    check(ZenAscendAchievements.claim_after_match(data,0).is_empty(),"achievement cannot be awarded twice")
    check(ZenAscendAchievements.secret_count(data) == 1,"secret progress persisted")
    check(not ZenAscendAchievements.earned(data,"abyss_memory_walker"),"Abyss achievement locked at zero wins")
    abyss_progress.abyss_stats.played = 5
    abyss_progress.abyss_stats.wins = 5
    abyss_progress.abyss_stats.edge_wins = 2
    abyss_progress.abyss_stats.fast_wins = 2
    check(Realm2.save_progress(abyss_progress),"record independent Abyss statistics")
    for id in ["abyss_memory_walker","abyss_echo_keeper","abyss_swift_echo","abyss_deep_remembrance"]:
        check(ZenAscendAchievements.earned(data,id),"Abyss earned badge follows saved match statistics: "+id)
    check(ZenAscendAchievements.secret_count(data)==5,"four Abyss badges plus original Shadow badge")
    check(not ZenAscendAchievements.earned(data,"ember_initiate"),"Abyss stats never award Ember badges")

    var hint_data: Dictionary = SaveManager.defaults()
    ZenCollection.ensure(hint_data)
    hint_data.economy.leaves = 100
    check(ZenAscendAchievements.buy_hint(hint_data,"moon_disciple"),"valid hint purchase")
    check(ZenAscendAchievements.hint_owned(hint_data,"moon_disciple"),"hint unlocked, not achievement")
    check(not ZenAscendAchievements.earned(hint_data,"moon_disciple"),"hint must not award achievement")
    check(int(hint_data.economy.leaves) == 50,"exactly 50 leaves deducted")
    check(not ZenAscendAchievements.buy_hint(hint_data,"moon_disciple"),"hint cannot be paid twice")
    var hint_loaded: Variant = JSON.parse_string(JSON.stringify(hint_data))
    if hint_loaded is Dictionary:
        check(ZenAscendAchievements.hint_owned(hint_loaded,"moon_disciple"),"hint survives reload")
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
    if abyss_existed:
        var backup_file := FileAccess.open(Realm2.SAVE,FileAccess.WRITE)
        backup_file.store_buffer(abyss_backup)
        backup_file.close()
    elif FileAccess.file_exists(Realm2.SAVE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(Realm2.SAVE))
    print("ZEN PREMIUM ACHIEVEMENTS FAILURES=",failures)
    quit(0 if failures == 0 else 1)
