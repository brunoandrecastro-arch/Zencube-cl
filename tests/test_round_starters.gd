extends SceneTree
## Verify the intended alternating starter is not lost between rounds.
## Does not modify actual player saves or stage unlocks.
const Celestial = preload("res://story/ZenCelestialCampaign.gd")
const Satori = preload("res://story/ZenSatoriCampaign.gd")
var failures: int = 0

func check(cond: bool, message: String) -> void:
    if not cond:
        failures += 1
        printerr("ROUND STARTERS FAIL: ",message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    for model in [Celestial,Satori]:
        var chapter: String = "Celestial" if model == Celestial else "Satori"
        var data: Dictionary = model.defaults()
        data.defeated = [true,false,false]
        data.page = int(model.GATES[1])
        var initial: Dictionary = model.begin_battle(data,1)
        check(not initial.is_empty(),chapter + " can start second boss")
        if initial.is_empty(): continue
        var first_turn: int = int(initial.get("turn",-1))
        data.game.result = 1
        check(model.start_next(data),chapter + " can continue from result")
        var next: Dictionary = model.begin_battle(data,1)
        check(not next.is_empty(),chapter + " second round exists")
        if next.is_empty(): continue
        var second_turn: int = int(next.get("turn",-1))
        check(first_turn in [1,2] and second_turn == 3-first_turn,chapter + " alternates X/O between rounds")
    print("Celestial / Satori starter tests: ",failures," failure(s)")
    quit(1 if failures>0 else 0)
