extends SceneTree
const Sky = preload("res://story/ZenSkyGardenCampaign.gd")
var errors: int = 0

func check(value: bool, reason: String) -> void:
    if not value:
        errors += 1
        printerr("SKY GARDEN FAIL: ",reason)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var existed: bool = FileAccess.file_exists(Sky.SAVE)
    var prior: PackedByteArray = FileAccess.get_file_as_bytes(Sky.SAVE) if existed else PackedByteArray()
    var old_moon_save: String = FileAccess.get_file_as_string("user://zencube_shattered_moon_v1.json") if FileAccess.file_exists("user://zencube_shattered_moon_v1.json") else ""
    var progress: Dictionary = Sky.defaults()
    check(Sky.page_limit(progress)==8, "Aiko story gate at page 08")
    check(Sky.next_action(progress).get("type")=="page","Page 01 starts as a reader")
    progress.page = 8
    check(int(Sky.next_action(progress).get("family",-1))==0,"First encounter is Aiko")
    check(Sky.begin_game(progress,0),"Save the first family game")
    var board: BoardModel = Sky.new_board()
    check(board.cells.size()==54 and not board.swap_enabled,"Real rigid 54-cell 3x3 board, no swap")
    check(board.owners==[1,0] and board.starter_owner==1,"Kuze is O / family X")
    check(Sky.restore_board(progress.game).owners==[1,0],"Persisted ownership")
    var rules := RulesEngine.new()
    var victory_line: Array = rules.lines[0]
    check(victory_line.size()==4,"Use existing four-in-a-line rules, no three-in-a-row shortcut")
    for cell in victory_line: board.cells[cell] = 2
    board.winner = 2
    check(Sky.record_victory(progress,0,board),"Aiko unlocks page 09")
    check(int(progress.page)==9 and bool(progress.won[0]),"Aiko continuation")
    check(not bool(progress.won[1]) and Sky.page_limit(progress)==18,"Shin remains locked until page 18")
    progress.page = 18
    check(int(Sky.next_action(progress).get("family",-1))==1,"Second encounter is Shin")
    check(Sky.begin_game(progress,1),"Save Shin encounter")
    var son: BoardModel = Sky.new_board()
    son.winner = 2
    check(not Sky.record_victory(progress,1,son),"No wins without a real RulesEngine line")
    for cell in victory_line: son.cells[cell] = 2
    check(Sky.record_victory(progress,1,son),"Shin unlocks page 19")
    check(Sky.page_limit(progress)==30 and int(progress.page)==19,"Final pages unlocked after two games")
    check(not Sky.finish(progress),"No premature ending")
    progress.page = 30
    check(Sky.finish(progress),"Complete exactly at page 30")
    check(bool(Sky.load_progress().get("completed",false)),"Save and reload separate completion")
    check(not FileAccess.file_exists("user://zen_garden_sky_unused.json"),"No invented Classic save")
    check((FileAccess.get_file_as_string("user://zencube_shattered_moon_v1.json") if FileAccess.file_exists("user://zencube_shattered_moon_v1.json") else "")==old_moon_save,"Existing Moon progress untouched")
    if existed:
        var stream: FileAccess = FileAccess.open(Sky.SAVE,FileAccess.WRITE)
        stream.store_buffer(prior)
        stream.close()
    elif FileAccess.file_exists(Sky.SAVE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(Sky.SAVE))
    print("Sky Garden 3x3 model tests: ",errors," failure(s)")
    quit(1 if errors>0 else 0)
