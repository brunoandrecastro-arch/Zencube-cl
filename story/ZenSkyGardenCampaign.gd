extends RefCounted
## Sky Garden is the final 3x3 story-world after Shattered Moon.
## Two family games; no boss grind, new rank, economy reward or changes to
## Classic/Zen Ascend saves. Kuze is gold O, Aiko/Shin violet X.
const Moon = preload("res://story/ZenShatteredMoonCampaign.gd")
const SAVE := "user://zencube_sky_garden_epilogue_v1.json"
const VERSION := 1
const ASSET_ROOT := "res://assets/sky_garden/"
const REALM_ART := ASSET_ROOT + "realm.webp"
const NAMES: Array[String] = ["Aiko Tadanobu", "Shin Tadanobu"]
const TITLES: Array[String] = ["The Seat Beside You", "The Time We Have"]
const IDS: Array[String] = ["aiko_tadanobu", "shin_tadanobu"]
const GATES: Array[int] = [8, 18]
const CONTINUE_PAGES: Array[int] = [9, 19]

static func qa_mode() -> bool:
    return OS.has_feature("zencube_realm_2_0_test")

static func unlocked() -> bool:
    return bool(Moon.load_progress().get("completed",false))

static func page_path(index: int) -> String:
    if index < 1 or index > 30: return ""
    return ASSET_ROOT + "pages/page_%02d.webp" % index

static func portrait(index: int) -> Texture2D:
    if index < 0 or index >= 2: return null
    var path: String = ASSET_ROOT + "family/" + IDS[index] + ".webp"
    return load(path) as Texture2D if ResourceLoader.exists(path) else null

static func backdrop(index: int = -1) -> Texture2D:
    var path: String = REALM_ART if index not in [0,1] else ASSET_ROOT + "arenas/" + IDS[index] + ".webp"
    return load(path) as Texture2D if ResourceLoader.exists(path) else null

static func story_stream() -> AudioStream:
    # Temporary existing game soundtrack; Sky Garden originals are not supplied.
    return Moon.story_stream()

static func defaults() -> Dictionary:
    return {"version":VERSION,"page":1,"won":[false,false],"attempts":[0,0],"game":{},"completed":false}

static func page_limit(progress: Dictionary) -> int:
    var completed: Array = progress.get("won",[false,false])
    if completed.size()!=2 or not bool(completed[0]): return 8
    if not bool(completed[1]): return 18
    return 30

static func new_board() -> BoardModel:
    var result := BoardModel.new()
    result.swap_enabled = false
    result.swap_pending = false
    result.starter_owner = 1
    result.owners = [1,0] # X is the family; O is the human / Kuze
    return result

static func restore_board(snapshot: Dictionary) -> BoardModel:
    var board: BoardModel = new_board()
    if snapshot.is_empty(): return board
    var marks: Variant = snapshot.get("cells",[])
    if not marks is Array or marks.size()!=54: return board
    for value in marks:
        if int(value) not in [0,1,2]: return board
    if snapshot.get("owners",[]) != [1,0] or bool(snapshot.get("swap_enabled",true)) or bool(snapshot.get("swap_pending",false)):
        return board
    if int(snapshot.get("starter_owner",-1)) != 1 or int(snapshot.get("turn",0)) not in [1,2]:
        return board
    board.restore(snapshot)
    board.history = snapshot.get("history",[]).duplicate(true)
    var engine := RulesEngine.new()
    var x_wins: Array = engine.victories(board.cells,1)
    var o_wins: Array = engine.victories(board.cells,2)
    if not x_wins.is_empty() and not o_wins.is_empty(): return new_board()
    board.win_lines = x_wins + o_wins
    board.winner = 1 if not x_wins.is_empty() else (2 if not o_wins.is_empty() else (3 if not board.cells.has(0) else 0))
    return board

static func load_progress() -> Dictionary:
    var progress: Dictionary = defaults()
    if not FileAccess.file_exists(SAVE): return progress
    var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
    if not loaded is Dictionary or int(loaded.get("version",-1)) != VERSION: return progress
    var wins: Variant = loaded.get("won",[])
    if not wins is Array or wins.size()!=2: return progress
    progress.won = [bool(wins[0]), bool(wins[1]) and bool(wins[0])]
    var attempts: Variant = loaded.get("attempts",[])
    if attempts is Array and attempts.size()==2:
        progress.attempts = [maxi(0,int(attempts[0])),maxi(0,int(attempts[1]))]
    progress.page = clampi(int(loaded.get("page",1)),1,page_limit(progress))
    var snapshot: Variant = loaded.get("game",{})
    if snapshot is Dictionary and not snapshot.is_empty() and next_action(progress).get("type")=="game":
        var board: BoardModel = restore_board(snapshot)
        progress.game = board.snapshot()
        progress.game["history"] = board.history.duplicate(true)
    progress.completed = bool(loaded.get("completed",false)) and bool(progress.won[0]) and bool(progress.won[1]) and int(progress.page)==30
    return progress

static func save_progress(progress: Dictionary) -> bool:
    var output: Dictionary = {
        "version":VERSION, "page":clampi(int(progress.get("page",1)),1,page_limit(progress)),
        "won":progress.get("won",[false,false]),"attempts":progress.get("attempts",[0,0]),
        "game":progress.get("game",{}),"completed":bool(progress.get("completed",false))
    }
    var tmp := SAVE + ".tmp"
    var stream: FileAccess = FileAccess.open(tmp,FileAccess.WRITE)
    if stream==null: return false
    stream.store_string(JSON.stringify(output))
    stream.flush()
    var error: Error = stream.get_error()
    stream.close()
    if error!=OK: return false
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp),ProjectSettings.globalize_path(SAVE)) == OK

static func next_action(progress: Dictionary) -> Dictionary:
    var page: int = clampi(int(progress.get("page",1)),1,30)
    var won: Array = progress.get("won",[false,false])
    if won.size()!=2: return {"type":"invalid"}
    for i in range(2):
        if page==GATES[i] and not bool(won[i]): return {"type":"game","family":i}
    if page==30: return {"type":"complete"}
    return {"type":"page","page":mini(page+1,page_limit(progress))}

static func begin_game(progress: Dictionary, family: int) -> bool:
    var action: Dictionary = next_action(progress)
    if action.get("type")!="game" or int(action.get("family",-1))!=family: return false
    if progress.get("game",{}).is_empty():
        var attempts: Array = progress.get("attempts",[0,0])
        attempts[family] = int(attempts[family])+1
        progress.attempts = attempts
        progress.game = new_board().snapshot()
        progress.game["history"] = []
    return save_progress(progress)

static func capture(progress: Dictionary, board: BoardModel) -> void:
    progress.game = board.snapshot()
    progress.game["history"] = board.history.duplicate(true)

static func record_victory(progress: Dictionary, family: int, board: BoardModel) -> bool:
    var action: Dictionary = next_action(progress)
    if action.get("type")!="game" or int(action.get("family",-1))!=family: return false
    if board.owners != [1,0] or board.winner != 2: return false
    if RulesEngine.new().victories(board.cells,2).is_empty(): return false
    var before: Dictionary = progress.duplicate(true)
    progress.won[family] = true
    progress.page = CONTINUE_PAGES[family]
    progress.game = {}
    if save_progress(progress): return true
    progress.clear()
    progress.merge(before,true)
    return false

static func retry_game(progress: Dictionary, family: int) -> bool:
    var action: Dictionary = next_action(progress)
    if action.get("type")!="game" or int(action.get("family",-1))!=family: return false
    var before: Dictionary = progress.duplicate(true)
    progress.game = {}
    if begin_game(progress,family): return true
    progress.clear()
    progress.merge(before,true)
    return false

static func finish(progress: Dictionary) -> bool:
    if int(progress.get("page",0)) != 30 or not (bool(progress.won[0]) and bool(progress.won[1])): return false
    progress.completed = true
    return save_progress(progress)
