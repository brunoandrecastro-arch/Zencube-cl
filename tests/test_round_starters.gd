extends SceneTree
## Verify the intended alternating starter is not lost between rounds.
## Does not modify actual player saves or stage unlocks.
const Celestial = preload("res://story/ZenCelestialCampaign.gd")
const Satori = preload("res://story/ZenSatoriCampaign.gd")
const Shadow = preload("res://story/ZenShadowCampaign.gd")
const Abyss = preload("res://story/ZenAbyssCampaign.gd")
const Ember = preload("res://story/ZenEmberCampaign.gd")
const Moon = preload("res://story/ZenShatteredMoonCampaign.gd")
const Series = preload("res://core/ZenFinalGuardianSeries.gd")
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
    for model in [Shadow,Abyss,Ember,Celestial,Satori,Moon]:
        var existed: bool = FileAccess.file_exists(model.SAVE)
        var backup: PackedByteArray = FileAccess.get_file_as_bytes(model.SAVE) if existed else PackedByteArray()
        var data: Dictionary = model.defaults()
        data.defeated = [true,true,false]
        data.page = int(model.GATES[2])
        var first: Dictionary = model.begin_battle(data,2)
        check(not first.is_empty(),"final boss starts")
        if not first.is_empty():
            check(int(first.turn)==1 and Series.round_starter(first)==1,"round 1 starts X")
            first.cells[0] = 1
            first.turn = 2
            check(Series.round_starter(first)==1,"next turn does not change starter")
            check(model.save_progress(data),"save unfinished first round")
            data = model.load_progress()
            var resumed: Dictionary = model.begin_battle(data,2)
            check(int(resumed.get("turn",0))==2 and Series.round_starter(resumed)==1,"reentry preserves starter and actual turn")
            data.game.result = 1
            var advanced: bool = Series.start_next(data) if model in [Shadow,Abyss] else model.start_next(data)
            check(advanced,"advance to round 2")
            var second: Dictionary = model.begin_battle(data,2)
            check(int(second.get("turn",0))==2 and Series.round_starter(second)==2,"round 2 starts O")
            data.game.result = 2
            advanced = Series.start_next(data) if model in [Shadow,Abyss] else model.start_next(data)
            check(advanced,"advance to round 3")
            var third: Dictionary = model.begin_battle(data,2)
            check(int(third.get("turn",0))==1 and Series.round_starter(third)==1,"round 3 starts X")
            check(model.save_progress(data),"save empty third round")
            data = model.load_progress()
            third = model.begin_battle(data,2)
            check(int(third.get("turn",0))==1 and Series.round_starter(third)==1,"reopening empty round 3 cannot change first mover")
            check(int(Series.score(data).player)==1 and int(Series.score(data).guardian)==1,"series score preserved")
        if existed:
            var stream := FileAccess.open(model.SAVE,FileAccess.WRITE)
            stream.store_buffer(backup)
            stream.close()
        elif FileAccess.file_exists(model.SAVE):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(model.SAVE))
    check(Series.round_starter({"cells":[1,0,0],"turn":2,"result":0})==1,"legacy X starter migration")
    check(Series.round_starter({"cells":[2,1,0],"turn":2,"result":0})==2,"legacy O starter migration")
    print("All six Realm starter tests: ",failures," failure(s)")
    quit(1 if failures>0 else 0)
