extends SceneTree
# Challenges appear in the match result; only actual achievements trigger a choir ceremony.
# No changes to the main save. The temporary test story progress is restored.
const Story = preload("res://story/ZenRealmChronicles.gd")
const Realms = preload("res://core/ZenAscendRealms.gd")
const Achievements = preload("res://core/ZenAscendAchievements.gd")
var failures: int = 0

func check(ok: bool, info: String) -> void:
    if not ok:
        failures += 1
        printerr("ACHIEVEMENT VS CHALLENGE FAIL: " + info)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var had_story: bool = FileAccess.file_exists(Story.SAVE)
    var old_story: PackedByteArray = FileAccess.get_file_as_bytes(Story.SAVE) if had_story else PackedByteArray()
    var data: Dictionary = SaveManager.defaults()
    data.ascension.rank = 3
    data.ascension.completed = [true,true,true,false,false]
    Realms.ensure(data)
    for task in Realms.TASKS[0]:
        Realms.state(data).completed[str(task.id)] = true
    var progress: Dictionary = Story.defaults()
    progress.stage = 3
    check(Story.save_progress(progress), "seed three defeated Shadow bosses")
    check(Realms.unlocked(data,1), "Ember unlocked for test")
    var edge_line: Array = ZenAscend.generate_lines()[60]
    var award: Dictionary = Realms.record_bot_match(data,1,1,2,19,[edge_line],true)
    var expected: Array = ["ember_first","ember_hard","ember_edge","ember_master"]
    for id in expected:
        check(award.new_tasks.has(id), "Ember Challenge won: " + id)
    check(award.new_tasks.size() == 4, "four independent Ember challenges for one match")
    check(Achievements.claim_after_match(data,1).is_empty(), "first Ember win creates NO secret achievement")
    check(not bool(award.realm_completed), "first Ember win creates NO realm title")
    check(int(award.leaves) == 310, "four challenge leaves awarded exactly once")
    var repeat: Dictionary = Realms.record_bot_match(data,1,1,2,19,[edge_line],true)
    for id in expected:
        check(not repeat.new_tasks.has(id), "Ember Challenge not awarded twice: " + id)

    # Verify controller does not enqueue the challenges as achievement ceremonies.
    var controller_source: String = FileAccess.get_file_as_string("res://ui/AscendController.gd")
    check(not controller_source.contains('queued_unlocks.append({"kind":"challenge"'),
        "only achievements and realm travel enter ceremony queue")
    check(controller_source.contains('queued_unlocks.append({"kind":"achievement"'),
        "secret achievements retain independent ceremony")
    check(controller_source.contains('last_realm_awards.get("new_tasks",[])'),
        "new challenges remain in match results")

    # Exact unlock conditions on DE/EN/PT ceremony only, not on locked secrets.
    var secret: Dictionary = Achievements.SECRETS[4] # Ember Initiate
    for language in ["de","en","pt"]:
        var reason: String = Achievements.unlock_reason(secret,1,language)
        check(reason.length() > 10, "localized secret achievement reason " + language)
        var ceremony: ZenUnlockCeremony = ZenUnlockCeremony.new()
        root.add_child(ceremony)
        ceremony.present("achievement",Realms.REALM_ART[1],str(secret.name),
            str(secret.quote),false,[],reason,language)
        await process_frame
        var label: Label = ceremony.find_child("UnlockedReason",true,false) as Label
        check(label != null and label.text == reason, "true reason shown in ceremony " + language)
        ceremony.close()
        await process_frame
        var main_reason: String = Achievements.unlock_reason({"id":"main"},1,language)
        check(main_reason.length() > 10 and main_reason.contains("8"),
            "Realm title requires all eight challenges in " + language)

    if had_story:
        var restored: FileAccess = FileAccess.open(Story.SAVE,FileAccess.WRITE)
        if restored != null:
            restored.store_buffer(old_story)
            restored.close()
    elif FileAccess.file_exists(Story.SAVE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(Story.SAVE))
    print("ACHIEVEMENT VS CHALLENGE FAILURES=",failures)
    quit(0 if failures == 0 else 1)
