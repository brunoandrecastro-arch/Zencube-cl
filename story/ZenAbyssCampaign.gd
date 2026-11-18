extends RefCounted
## Campaign 2.0: isolated Abyss page/boss progression.
## Native 4x4 story gates; imported media lives under assets/abyss_of_memories.
## Does not replace the existing Realm Chronicles save or unlock anything.
const SAVE := "user://zencube_abyss_campaign_v1.json"
const VERSION := 1
const BOSS_IDS: Array[String] = ["memory_thief", "weeping_blade", "forgotten_shogun"]
const BOSS_NAMES: Array[String] = ["The Memory Thief", "The Weeping Blade", "The Forgotten Shogun"]
const GATES: Array[int] = [6, 15, 25]
const CONTINUE_PAGES: Array[int] = [7, 16, 26]
const BOT_LEVELS: Array[int] = [1, 2, 3] # Medium, Hard, Master
const ASSET_ROOT := "res://assets/abyss_of_memories/"

static func page_path(page: int) -> String:
    if page < 1 or page > 30: return ""
    return ASSET_ROOT + "pages/page_%02d.webp" % page

static func boss_art(index: int) -> String:
    if index < 0 or index >= 3: return ""
    return ASSET_ROOT + "bosses/%s.webp" % BOSS_IDS[index]

static func boss_music(index: int) -> String:
    if index < 0 or index >= 3: return ""
    return ASSET_ROOT + "audio/%s.mp3" % BOSS_IDS[index]

static func defaults() -> Dictionary:
    return {"version":VERSION,"page":1,"defeated":[false,false,false],"attempts":[0,0,0],"game":{},"completed":false}

static func page_limit(data: Dictionary) -> int:
    var won: Array = data.get("defeated",[false,false,false])
    if won.size() != 3: return 6
    for i in range(3):
        if not bool(won[i]): return GATES[i]
    return 30

static func load_progress() -> Dictionary:
    var data: Dictionary = defaults()
    if not FileAccess.file_exists(SAVE): return data
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
    if not parsed is Dictionary or int(parsed.get("version",-1)) != VERSION: return data
    var won: Variant = parsed.get("defeated",[])
    if not won is Array or won.size() != 3: return data
    data.defeated = [bool(won[0]),bool(won[1]),bool(won[2])]
    for i in range(1,3):
        if not bool(data.defeated[i-1]): data.defeated[i] = false
    var attempts: Variant = parsed.get("attempts",[])
    if attempts is Array and attempts.size() == 3:
        data.attempts = [maxi(0,int(attempts[0])),maxi(0,int(attempts[1])),maxi(0,int(attempts[2]))]
    data.page = clampi(int(parsed.get("page",1)),1,page_limit(data))
    var game: Variant = parsed.get("game",{})
    if game is Dictionary and not game.is_empty():
        var b: int = int(game.get("boss",-1))
        var cells: Variant = game.get("cells",[])
        if b >= 0 and b < 3 and not bool(data.defeated[b]) and cells is Array and cells.size() == 96:
            var valid: bool = int(game.get("turn",0)) in [1,2]
            for mark in cells:
                if int(mark) not in [0,1,2]: valid = false
            if valid: data.game = game.duplicate(true)
    data.completed = bool(parsed.get("completed",false)) and bool(data.defeated[0]) and bool(data.defeated[1]) and bool(data.defeated[2])
    return data

static func save_progress(data: Dictionary) -> bool:
    var payload: Dictionary = {
        "version":VERSION,"page":clampi(int(data.get("page",1)),1,page_limit(data)),
        "defeated":data.get("defeated",[false,false,false]),
        "attempts":data.get("attempts",[0,0,0]),"game":data.get("game",{}),
        "completed":bool(data.get("completed",false))
    }
    var temp: String = SAVE + ".tmp"
    var f := FileAccess.open(temp,FileAccess.WRITE)
    if f == null: return false
    f.store_string(JSON.stringify(payload))
    f.close()
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp),ProjectSettings.globalize_path(SAVE)) == OK

static func next_action(data: Dictionary) -> Dictionary:
    var page: int = clampi(int(data.get("page",1)),1,30)
    var won: Array = data.get("defeated",[false,false,false])
    if won.size() != 3: return {"type":"invalid"}
    for i in range(3):
        if page == GATES[i] and not bool(won[i]): return {"type":"battle","boss":i}
    if page >= 30: return {"type":"complete"}
    return {"type":"page","page":mini(page+1,page_limit(data))}

static func begin_battle(data: Dictionary, index: int) -> Dictionary:
    var action: Dictionary = next_action(data)
    if action.get("type") != "battle" or int(action.get("boss",-1)) != index: return {}
    var current: Dictionary = data.get("game",{})
    if not current.is_empty() and int(current.get("boss",-1)) == index: return current
    var attempts: Array = data.get("attempts",[0,0,0])
    var attempt: int = int(attempts[index])
    attempts[index] = attempt+1
    data.attempts = attempts
    var cells: Array = []
    cells.resize(96)
    cells.fill(0)
    var game: Dictionary = {"boss":index,"cells":cells,"turn":(1 if (index+attempt)%2==0 else 2),"result":0,"last_human":-1}
    data.game = game
    return game

static func record_victory(data: Dictionary, index: int) -> bool:
    ## Call ONLY after a validated victory in the existing native 4x4 engine.
    var action: Dictionary = next_action(data)
    if action.get("type") != "battle" or int(action.get("boss",-1)) != index: return false
    var won: Array = data.get("defeated",[false,false,false])
    won[index] = true
    data.defeated = won
    data.page = CONTINUE_PAGES[index]
    data.game = {}
    return save_progress(data)

static func qa_mode() -> bool:
    # Only the separately signed Abyss debug APK sets this during export.
    # It does not change rank, shop purchases or regular 4x4 gates.
    return bool(ProjectSettings.get_setting("application/config/abyss_qa",false))

static func realm_art() -> String:
    return ASSET_ROOT + "realm.webp"

static func story_music() -> String:
    return ASSET_ROOT + "audio/story.mp3"

static func _load_loop(path: String) -> AudioStream:
    if not ResourceLoader.exists(path): return null
    var stream: AudioStream = load(path) as AudioStream
    if stream is AudioStreamMP3:
        (stream as AudioStreamMP3).loop = true
    return stream

static func story_stream() -> AudioStream:
    return _load_loop(story_music())

static func boss_stream(index: int) -> AudioStream:
    if index < 0 or index >= 3: return null
    return _load_loop(boss_music(index))

static func _threats(cells: Array, lines: Array, player: int) -> Array:
    var result: Array = []
    for line in lines:
        var owned: int = 0
        var free: int = -1
        var blanks: int = 0
        var blocked: bool = false
        for c in line:
            if int(cells[c]) == player: owned += 1
            elif int(cells[c]) == 0:
                free = int(c)
                blanks += 1
            else:
                blocked = true
                break
        if not blocked and owned == 3 and blanks == 1 and not result.has(free):
            result.append(free)
    return result

static func choose_move(cells: Array, lines: Array, index: int, last_human: int = -1) -> int:
    # Use the game's tested native bot/204 win-line logic. Only tactical
    # preference differs by boss; immediate wins and blocks always take priority.
    var wins: Array = _threats(cells,lines,2)
    if not wins.is_empty(): return int(wins[0])
    var blocks: Array = _threats(cells,lines,1)
    if not blocks.is_empty(): return int(blocks[0])
    var boss: int = clampi(index,0,2)
    if boss == 0 and last_human >= 0 and last_human < cells.size():
        var face: int = int(last_human / 16)
        var row: int = int(last_human % 16 / 4)
        var col: int = last_human % 4
        var mirror: int = face * 16 + (3-row)*4 + (3-col)
        if int(cells[mirror]) == 0 and randf() < 0.35: return mirror
    var baseline: int = ZenAscendRealmBot.next_move(cells,lines,2,BOT_LEVELS[boss],false)
    if boss != 2: return baseline
    # The Shogun prefers a move with future double-threat pressure when
    # tactical strength is comparable. Master is still the baseline.
    var best: int = baseline
    var highest: float = -1e20
    for candidate in range(cells.size()):
        if int(cells[candidate]) != 0: continue
        var value: float = ZenAscendRealmBot._score(cells,lines,2,candidate)
        value += ZenAscendRealmBot._fork_score(cells,lines,2,candidate)
        if value > highest:
            highest = value
            best = candidate
    return best

static func finish_chapter(data: Dictionary) -> bool:
    var won: Array = data.get("defeated",[false,false,false])
    if won.size() != 3 or not (bool(won[0]) and bool(won[1]) and bool(won[2])): return false
    if int(data.get("page",0)) != 30: return false
    data.completed = true
    return save_progress(data)
