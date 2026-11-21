extends SceneTree
# Visual ceremony smoke check; no Realm progress or real user save is modified.
const Ceremony = preload("res://ui/ZenUnlockCeremony.gd")
var failures: int = 0
func check(value: bool, message: String) -> void:
    if not value:
        failures += 1
        printerr("REALM CHALLENGE CEREMONY FAIL: " + message)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var ceremony: ZenUnlockCeremony = Ceremony.new()
    root.add_child(ceremony)
    ceremony.present("challenge","res://assets/abyss_of_memories/realm.webp",
        "Across the Memories","Win with four marks across a cube edge.",false,[],"en")
    await process_frame
    var canvas: Node = ceremony.get_node_or_null("ZenUnlockCeremonyOverlay")
    check(canvas != null,"full-screen ceremony overlay is present")
    if canvas != null:
        var heading: Label = canvas.find_child("RealmChallengeCeremonyHeading",true,false) as Label
        check(heading != null,"new Challenge banner is visible")
        if heading != null: check(heading.text.contains("REALM CHALLENGE COMPLETE"),"Challenge completion wording")
        var continue_button: Button = canvas.find_child("ZenUnlockContinue",true,false) as Button
        check(continue_button != null,"player can continue to the result")
    ceremony.close()
    await process_frame
    check(not is_instance_valid(ceremony) or ceremony.is_queued_for_deletion(),"ceremony closes without leaving overlay")
    print("REALM CHALLENGE CEREMONY FAILURES=",failures)
    quit(0 if failures==0 else 1)
