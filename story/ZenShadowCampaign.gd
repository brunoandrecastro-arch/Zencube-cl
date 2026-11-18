extends RefCounted
## Campaign 2.0 – independent, 30-page Shadow Realm chapter.
## Reuses the original Realm Chronicles first three bosses and their music.
## Does not modify existing Realm Chronicles progression, 4x4 unlocks or shop.
const RealmStory = preload("res://story/ZenRealmChronicles.gd")
const BossMusic = preload("res://core/ZenRealmBossMusic.gd")
const RealmMusic = preload("res://core/ZenRealmMusic.gd")
const SAVE := "user://zencube_shadow_campaign_v1.json"
const VERSION := 1
const BOSS_IDS: Array[String] = ["mist_guardian","mirror_novice","veil_monk"]
const BOSS_NAMES: Array[String] = ["Mist Guardian","Mirror Novice","Veil Monk"]
const GATES: Array[int] = [4,8,15]
const CONTINUE_PAGES: Array[int] = [5,9,16]
const BOT_LEVELS: Array[int] = [1,1,1] # Shadow remains Medium
const ASSET_ROOT := "res://assets/shadow_campaign/"
const REALM_ART := "res://assets/realms/shadow_realm.webp"

static func qa_mode() -> bool:
    return OS.has_feature("zencube_shadow_test")

static func page_path(page: int) -> String:
    if page < 1 or page > 30: return ""
    return ASSET_ROOT + "pages/page_%02d.webp" % page

static func boss_art(index: int) -> Texture2D:
    if index < 0 or index >= 3: return null
    return RealmStory.boss_texture(index)

static func story_stream() -> AudioStream:
    return RealmMusic.stream_for(0)

static func boss_stream(index: int) -> AudioStream:
    if index < 0 or index >= 3: return null
    return BossMusic.stream_for(index)

static func battle_backdrop(index: int = -1) -> Texture2D:
    # Original Shadow background stays a fallback when optional HD images
    # have not yet been committed to this development branch.
    if index >= 0 and index < 3:
        var boss_path: String = ASSET_ROOT + "arenas/" + BOSS_IDS[index] + ".webp"
        if ResourceLoader.exists(boss_path):
            return load(boss_path) as Texture2D
    if not ResourceLoader.exists(REALM_ART): return null
    return load(REALM_ART) as Texture2D

static func defaults() -> Dictionary:
    return {"version":VERSION,"page":1,"defeated":[false,false,false],"attempts":[0,0,0],"game":{},"completed":false}

static func page_limit(data: Dictionary) -> int:
    var won: Array = data.get("defeated",[false,false,false])
    if won.size() != 3: return 4
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
    var saved_game: Variant = parsed.get("game",{})
    if saved_game is Dictionary and not saved_game.is_empty():
        var index: int = int(saved_game.get("boss",-1))
        var marks: Variant = saved_game.get("cells",[])
        if index >= 0 and index < 3 and not bool(data.defeated[index]) and marks is Array and marks.size() == 96:
            var valid: bool = int(saved_game.get("turn",0)) in [1,2] and int(saved_game.get("result",0)) in [0,1,2,3]
            for mark in marks:
                if int(mark) not in [0,1,2]: valid = false
            if valid: data.game = saved_game.duplicate(true)
    data.completed = bool(parsed.get("completed",false)) and bool(data.defeated[0]) and bool(data.defeated[1]) and bool(data.defeated[2])
    return data

static func save_progress(data: Dictionary) -> bool:
    var payload: Dictionary = {
        "version":VERSION,
        "page":clampi(int(data.get("page",1)),1,page_limit(data)),
        "defeated":data.get("defeated",[false,false,false]),
        "attempts":data.get("attempts",[0,0,0]),
        "game":data.get("game",{}),
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
    var next: Dictionary = next_action(data)
    if next.get("type") != "battle" or int(next.get("boss",-1)) != index: return {}
    var existing: Dictionary = data.get("game",{})
    if not existing.is_empty() and int(existing.get("boss",-1)) == index: return existing
    var attempts: Array = data.get("attempts",[0,0,0])
    var attempt: int = int(attempts[index])
    attempts[index] = attempt + 1
    data.attempts = attempts
    var cells: Array = []
    cells.resize(96)
    cells.fill(0)
    var game: Dictionary = {"boss":index,"cells":cells,"turn":(1 if (index+attempt)%2==0 else 2),"result":0,"last_human":-1}
    data.game = game
    return game

static func choose_move(cells: Array, lines: Array, index: int, last_human: int = -1) -> int:
    # The same authored bot logic and Medium tier as Realm Chronicles Shadow bosses.
    return RealmStory.choose_move(cells,lines,clampi(index,0,2),last_human)

static func record_victory(data: Dictionary, index: int) -> bool:
    var action: Dictionary = next_action(data)
    if action.get("type") != "battle" or int(action.get("boss",-1)) != index: return false
    # Do not unlock story pages from an unfinished/lost/drawn match.
    var battle: Dictionary = data.get("game",{})
    if int(battle.get("boss",-1)) != index or int(battle.get("result",0)) != 1: return false
    var won: Array = data.get("defeated",[false,false,false])
    won[index] = true
    data.defeated = won
    data.page = CONTINUE_PAGES[index]
    data.game = {}
    return save_progress(data)

static func finish_chapter(data: Dictionary) -> bool:
    var won: Array = data.get("defeated",[false,false,false])
    if won.size() != 3 or not (bool(won[0]) and bool(won[1]) and bool(won[2])): return false
    if int(data.get("page",0)) != 30: return false
    data.completed = true
    return save_progress(data)
