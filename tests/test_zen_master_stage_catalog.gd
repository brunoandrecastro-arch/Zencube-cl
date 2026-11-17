extends SceneTree
const Catalog = preload("res://core/ZenMasterStageCatalog.gd")
var failures: int = 0
func verify(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        printerr("ZEN MASTER ARENAS FAIL: " + message)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    verify(Catalog.validate(), "16 distinct arena paths in four realms")
    verify(Catalog.STAGES.size() == 16, "16 boss stages")
    var realms: Dictionary = {}
    for entry in Catalog.STAGES:
        var name: String = entry["realm"]
        realms[name] = int(realms.get(name, 0)) + 1
        verify(entry["art"].ends_with(entry["boss"] + ".svg"), "matching boss-specific file path")
    verify(realms.size() == 4, "four different realms")
    for name in realms:
        verify(int(realms[name]) == 4, "four unique bosses in realm " + name)
    verify(Catalog.stage_for("mirror_of_kuze")["arena"] == "Hall of Two Selves", "mirror boss gets its own stage")
    verify(Catalog.stage_for("no_such_boss").is_empty(), "unknown boss has no background fallback")
    print("ZEN MASTER ARENA CATALOG FAILURES=",failures)
    quit(0 if failures == 0 else 1)
