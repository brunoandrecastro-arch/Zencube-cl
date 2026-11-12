extends SceneTree
# Pure rank-to-bot mapping: no real save writes and no scene state mutations.
var failed: int = 0
func check(condition: bool, message: String) -> void:
    if not condition:
        failed += 1
        printerr("ZEN BOT AUTO FAIL: " + message)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    for rank in range(6):
        check(ZenBotAutoLevel.level_for_rank(rank) == mini(rank,4), "rank %d -> bot" % rank)
    check(ZenBotAutoLevel.level_for_rank(-5) == 0, "clamp below zero")
    check(ZenBotAutoLevel.level_for_rank(99) == 4, "clamp above grandmaster")
    var data: Dictionary = SaveManager.defaults()
    data.settings.level = 0
    check(not ZenBotAutoLevel.apply_after_rank_up(data,{"rank_up":false,"new_rank":4}),"ignore ordinary win")
    check(int(data.settings.level)==0, "manual level stays when no promotion")
    check(ZenBotAutoLevel.apply_after_rank_up(data,{"rank_up":true,"new_rank":1}),"apply new student rank")
    check(int(data.settings.level)==1,"first promotion selects medium")
    data.settings.level=0
    check(not ZenBotAutoLevel.apply_after_rank_up(data,{"rank_up":false,"new_rank":1}),"respect manual override")
    check(int(data.settings.level)==0,"manual lower difficulty survives normal match")
    for rank in range(2,6):
        check(ZenBotAutoLevel.apply_after_rank_up(data,{"rank_up":true,"new_rank":rank}),"rank promotion")
        check(int(data.settings.level)==mini(rank,4),"expected rank default %d" % rank)
    check(SaveManager.VERSION == 3,"save format unchanged")
    check(ZenAscend.CELLS == 96 and ZenAscend.PRICE == 750,"4x4 mechanics unchanged")
    print("ZEN BOT AUTO FAILURES=",failed)
    quit(0 if failed==0 else 1)
