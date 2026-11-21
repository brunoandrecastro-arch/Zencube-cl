extends SceneTree
# All build variants require the canonical Dark Kuze victory and completed Act IV.
const Mode = preload("res://core/ZenAscend.gd")
const DarkKuzeFixture = preload("res://tests/ActFourGateFixture.gd")
var failures: int = 0

func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error("4.0.3 Dark Kuze gate: " + message)

func _initialize() -> void:
    var fresh: Dictionary = {"economy":{"leaves":900,"ascend_owned":false},"ascension":{"rank":0}}
    check(not Mode.test_access_enabled(), "no QA skip")
    check(not Mode.unlocked(fresh), "new player is locked")
    for rank in [1,2,3,4]:
        var rank_only: Dictionary = {"economy":{"leaves":900,"ascend_owned":false},"ascension":{"rank":rank}}
        check(not Mode.unlocked(rank_only), "rank %d cannot bypass the story" % rank)
    var bought: Dictionary = {"economy":{"leaves":900,"ascend_owned":true},"ascension":{"rank":3}}
    check(not Mode.unlocked(bought), "old shop flag cannot bypass Dark Kuze")
    check(not Mode.buy(fresh), "purchase must fail before Act IV")
    check(int(fresh.economy.leaves)==900, "rejected purchase leaves currency intact")
    var fixture = DarkKuzeFixture.new()
    check(fixture.grant(), "valid legal Dark Kuze board win recorded and Act IV completed")
    check(Mode.unlocked(fresh), "Act IV ending grants access")
    check(Mode.unlocked(bought), "old purchases and stats preserved after story unlock")
    check(not Mode.buy(fresh) and int(fresh.economy.leaves)==900, "no charge for earned access")
    fixture.restore()
    check(not Mode.unlocked(fresh), "restored unfinished story is locked again")
    print("DARK KUZE GATE FAILURES=", failures)
    quit(1 if failures>0 else 0)
