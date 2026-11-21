extends SceneTree
const DarkKuzeFixture = preload("res://tests/ActFourGateFixture.gd")
const Story = preload("res://story/ZenRealmChronicles.gd")
# Runtime test; does not access the real user's save file.
var failures: int = 0
func check(valid: bool, description: String) -> void:
    if not valid:
        failures += 1
        printerr("REALM AUDIO/CEREMONY FAIL: " + description)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var exists: bool = FileAccess.file_exists(Story.SAVE)
    var original: PackedByteArray = FileAccess.get_file_as_bytes(Story.SAVE) if exists else PackedByteArray()
    check(Story.save_progress(Story.defaults()),"start without story boss achievements")
    for realm in range(4):
        var stream: AudioStream = ZenRealmMusic.stream_for(realm)
        check(stream is AudioStreamOggVorbis,"Ogg Vorbis stream for realm %d" % realm)
        if stream is AudioStreamOggVorbis:
            check((stream as AudioStreamOggVorbis).loop,"realm %d loops" % realm)
    check(ZenRealmMusic.stream_for(-1) == null,"negative realm rejected")
    check(ZenRealmMusic.stream_for(4) == null,"out of range realm rejected")
    var dark_kuze_gate = DarkKuzeFixture.new()
    check(dark_kuze_gate.grant(),"valid Dark Kuze Act IV checkpoint")
    var data: Dictionary = SaveManager.defaults()
    ZenCollection.ensure(data)
    ZenAscendRealms.ensure(data)
    data.ascension.rank = 3
    var state: Dictionary = ZenAscendRealms.state(data)
    # Complete all previous Realms before testing Satori.
    check(not ZenAscendRealms.unlocked(data,3),
          "Satori locked before Realm completion")
    for realm in range(3):
        for task in ZenAscendRealms.TASKS[realm]:
            state.completed[str(task.id)] = true
    check(not ZenAscendRealms.unlocked(data,3),"Satori requires 3x3 story boss victories too")
    var beaten: Dictionary = Story.defaults()
    beaten.stage = 9
    check(Story.save_progress(beaten),"record completed story bosses in earlier three Realms")
    check(ZenAscendRealms.unlocked(data,3),
          "Satori unlocked after three completed challenges AND stories")
    for i in range(6):
        state.completed[str(ZenAscendRealms.TASKS[3][i].id)] = true
    check(ZenAscendRealms.unlocked(data,3),"Satori unlock remains attainable")
    var last: Dictionary = ZenAscendRealms.record_bot_match(data,3,1,ZenAscendRealms.fixed_bot_level(3),19,[],false)
    check(last.new_tasks.has("satori_aware"),"Fully Aware achievement awarded on six Satori challenges")
    check(ZenAscendRealms.current_title(data,3) != "Fully Aware","highest title not awarded too early")
    # Completing the remaining first-seven Satori task makes all eight complete.
    state.completed[str(ZenAscendRealms.TASKS[3][6].id)] = true
    var final_award: Dictionary = ZenAscendRealms.record_bot_match(data,3,1,ZenAscendRealms.fixed_bot_level(3),19,[],false)
    check(bool(final_award.get("realm_completed", false)),"final Satori realm bonus awarded")
    check(ZenAscendRealms.current_title(data,3) == "Fully Aware","highest title reached at 8/8")
    var repeated: Dictionary = ZenAscendRealms.record_bot_match(data,3,1,ZenAscendRealms.fixed_bot_level(3),19,[],false)
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
    if exists:
        var file := FileAccess.open(Story.SAVE,FileAccess.WRITE)
        file.store_buffer(original)
        file.close()
    elif FileAccess.file_exists(Story.SAVE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(Story.SAVE))
    dark_kuze_gate.restore()
    print("REALM AUDIO/CEREMONY FAILURES=",failures)
    quit(1 if failures > 0 else 0)
