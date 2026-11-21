extends SceneTree
# Runtime verification: only earned Zen-Meister rank or shop ownership opens 4x4.
const Mode = preload("res://core/ZenAscend.gd")

func check(condition: bool, message: String) -> bool:
    if not condition:
        push_error("Zen Ascend 4.0.1 release gate: " + message)
        quit(1)
        return false
    return true

func _initialize() -> void:
    if not check(not Mode.test_access_enabled(), "QA unlock must be OFF in the normal build"): return
    var fresh: Dictionary = {"economy":{"leaves":849,"ascend_owned":false},"ascension":{"rank":0}}
    if not check(not Mode.unlocked(fresh), "new player must be locked"): return
    for rank in [1,2]:
        var midway: Dictionary = {"economy":{"leaves":900,"ascend_owned":false},"ascension":{"rank":rank}}
        if not check(not Mode.unlocked(midway), "rank %d must remain locked" % rank): return
    var poor: Dictionary = fresh.duplicate(true)
    if not check(not Mode.buy(poor), "insufficient leaves must not unlock"): return
    if not check(int(poor.economy.leaves)==849, "failed purchase must not deduct leaves"): return
    var earned: Dictionary = {"economy":{"leaves":0,"ascend_owned":false},"ascension":{"rank":3}}
    if not check(Mode.unlocked(earned), "Zen-Meister must unlock"): return
    if not check(not Mode.buy(earned), "earned unlock cannot charge again"): return
    var shopper: Dictionary = {"economy":{"leaves":850,"ascend_owned":false},"ascension":{"rank":0}}
    if not check(Mode.buy(shopper), "850 Zen Leaves must buy permanent unlock"): return
    if not check(Mode.unlocked(shopper) and int(shopper.economy.leaves)==0, "purchase must unlock and deduct 850"): return
    if not check(not Mode.buy(shopper), "purchased unlock cannot be charged twice"): return
    var returned: Dictionary = {"economy":{"leaves":0,"ascend_owned":true},"ascension":{"rank":0}}
    if not check(Mode.unlocked(returned), "old purchased ownership must remain valid"): return
    print("PASS: Zen Ascend 4.0.1 normal gate, ranks 0–2 locked, Zen-Meister and one-time purchase unlocked")
    quit(0)
