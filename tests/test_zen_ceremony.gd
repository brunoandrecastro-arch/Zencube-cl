extends SceneTree
## Headless scene smoke test. Does not modify the player's save.
var failures: int = 0
var emitted: int = 0

func check(condition: bool, text_value: String) -> void:
    if not condition:
        failures += 1
        printerr("CEREMONY FAIL: " + text_value)

func contains_label(node: Node, text_value: String) -> bool:
    if node is Label and (node as Label).text.contains(text_value):
        return true
    for child in node.get_children():
        if contains_label(child, text_value):
            return true
    return false

func _mark_finished() -> void:
    emitted += 1

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var ceremony_script: Script = load("res://ui/ZenRankCeremony.gd") as Script
    check(ceremony_script != null, "ceremony script imported")
    if ceremony_script == null:
        quit(1)
        return
    var first: ZenRankCeremony = ZenRankCeremony.new()
    root.add_child(first)
    first.finished.connect(_mark_finished)
    first.present(3, "de", false, [])
    await process_frame
    var overlay: Node = first.get_node_or_null("ZenAscensionCeremony")
    check(overlay != null, "overlay present")
    if overlay != null:
        check(contains_label(overlay, "Zen-Meister"), "correct rank title")
        check(contains_label(overlay, "ZEN ASCEND 4×4"), "rank three bonus unlocked")
        check(contains_label(overlay, "Mondgarten"), "world three unlocked")
        check(overlay.find_child("SkipCeremony", true, false) != null, "skip button accessible")
    first.skip()
    first.skip()
    await process_frame
    check(emitted == 1, "completion emitted only once")

    var last: ZenRankCeremony = ZenRankCeremony.new()
    root.add_child(last)
    last.finished.connect(_mark_finished)
    last.present(5, "en", false, [])
    await process_frame
    var second_overlay: Node = last.get_node_or_null("ZenAscensionCeremony")
    check(second_overlay != null, "highest rank overlay present")
    if second_overlay != null:
        check(contains_label(second_overlay, "Zen"), "final title visible")
        check(contains_label(second_overlay, "Highest"), "highest rank message")
        check(not contains_label(second_overlay, "ZEN ASCEND 4×4"), "no replay of rank 3 reward")
    last.skip()
    await process_frame
    check(emitted == 2, "highest-rank completion fired")
    print("ZEN RANK CEREMONY FAILURES=",failures)
    quit(0 if failures == 0 else 1)
