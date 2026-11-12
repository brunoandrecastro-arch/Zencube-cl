extends SceneTree
# Runtime test; does not access the real user's save file.
var failures: int = 0
func check(valid: bool, description: String) -> void:
    if not valid:
        failures += 1
        printerr("REALM AUDIO/CEREMONY FAIL: " + description)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    for realm in range(4):
        var stream: AudioStream = ZenRealmMusic.stream_for(realm)
        check(stream is AudioStreamOggVorbis,"Ogg Vorbis stream for realm %d" % realm)
        if stream is AudioStreamOggVorbis:
            check((stream as AudioStreamOggVorbis).loop,"realm %d loops" % realm)
    check(ZenRealmMusic.stream_for(-1) == null,"negative realm rejected")
    check(ZenRealmMusic.stream_for(4) == null,"out of range realm rejected")
    var data: Dictionary = SaveManager.defaults()
    ZenCollection.ensure(data)
    ZenAscendRealms.ensure(data)
    data.ascension.rank = 3
    var state: Dictionary = ZenAscendRealms.state(data)
    state.stats[2].wins = 10
    for realm in range(2):
        for i in range(6):
            state.completed[str(ZenAscendRealms.TASKS[realm][i].id)] = true
    for i in range(6):
        state.completed[str(ZenAscendRealms.TASKS[3][i].id)] = true
    check(ZenAscendRealms.unlocked(data,3),"Satori unlock remains attainable")
    var last: Dictionary = ZenAscendRealms.record_bot_match(data,3,1,2,19,[],false)
    check(last.new_tasks.has("satori_aware"),"Fully Aware achievement awarded on six Satori challenges")
    check(ZenAscendRealms.current_title(data,3) != "Fully Aware","highest title not awarded too early")
    # Completing the remaining first-seven Satori task makes all eight complete.
    state.completed[str(ZenAscendRealms.TASKS[3][6].id)] = true
    var final_award: Dictionary = ZenAscendRealms.record_bot_match(data,3,1,2,19,[],false)
    check(bool(final_award.get("realm_completed", false)),"final Satori realm bonus awarded")
    check(ZenAscendRealms.current_title(data,3) == "Fully Aware","highest title reached at 8/8")
    var repeated: Dictionary = ZenAscendRealms.record_bot_match(data,3,1,2,19,[],false)
    check(not bool(repeated.get("realm_completed", false)),"highest title and realm bonus cannot be awarded twice")
    state["fully_aware_ceremony_seen"] = true
    var loaded: Variant = JSON.parse_string(JSON.stringify(data))
    check(loaded is Dictionary,"state serializable")
    if loaded is Dictionary:
        ZenAscendRealms.ensure(loaded)
        check(bool(ZenAscendRealms.state(loaded).get("fully_aware_ceremony_seen",false)),"ceremony flag persists")
    var ceremony: ZenFullyAwareCeremony = ZenFullyAwareCeremony.new()
    root.add_child(ceremony)
    ceremony.present("de",false,[])
    await process_frame
    check(ceremony.get_node_or_null("FullyAwareCeremony") != null,"Fully Aware overlay rendered")
    ceremony.skip()
    await process_frame
    print("REALM AUDIO/CEREMONY FAILURES=",failures)
    quit(1 if failures > 0 else 0)
