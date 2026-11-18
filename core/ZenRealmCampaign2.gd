extends RefCounted
## ZenCube 2.0 Realm — separate Campaign 2.0 challenge achievements and gates.
## Never modifies original Classic 3x3, 8x4 Legacy Realm tasks, rank or shop.
const Shadow = preload("res://story/ZenShadowCampaign.gd")
const Abyss = preload("res://story/ZenAbyssCampaign.gd")
const SAVE := "user://zencube_realm_2_0_v1.json"
const VERSION := 1
const REALM_NAMES: Array[String] = ["Shadow Realm","Abyss of Memories","Ember Temple"]
const SOURCE_ART: Array[String] = [
    "res://assets/realms/shadow_realm.webp",
    "res://assets/abyss_of_memories/realm.webp",
    "res://assets/realms/ember_temple.webp"
]
const TITLES: Array = [
    ["Veil of Insight","The Edge of Silence","The Guardian's Answer"],
    ["Fractured Reflection","Echo of the Deep","The Shogun's Resolve"]
]
const OBJECTIVES: Array = [
    ["win_face","win_edge","block"],
    ["win_edge","block","win_face"]
]
const DE: Array = [
    ["Finde den einzigen Siegzug auf einer Würfelseite.","Gewinne mit einer Linie über eine Würfelkante.","Blockiere die unmittelbare Gewinnchance des Gegners."],
    ["Finde den Siegzug über die Würfelkante.","Rette Kuze durch den einzigen rettenden Block.","Schließe die Viererlinie auf einer Würfelseite."]
]
const EN: Array = [
    ["Find the winning move on a single cube face.","Complete four across a cube edge.","Block the opponent's immediate winning move."],
    ["Find the winning move across the edge.","Save Kuze with the only defensive move.","Complete four on a single cube face."]
]
const PT: Array = [
    ["Encontra a vitória numa face do cubo.","Completa quatro símbolos através de uma aresta.","Bloqueia a vitória imediata do adversário."],
    ["Encontra a vitória através da aresta.","Salva Kuze com a única defesa.","Completa quatro símbolos numa face."]
]

static func qa_mode() -> bool:
    return OS.has_feature("zencube_realm_2_0_test")

static func defaults() -> Dictionary:
    return {"version":VERSION,"completed":[[false,false,false],[false,false,false]],
        "entered":[false,false],"achievement_count":0}

static func _valid_completed(raw: Variant) -> Array:
    var result: Array = [[false,false,false],[false,false,false]]
    if not raw is Array or raw.size() != 2: return result
    for chapter in range(2):
        if not raw[chapter] is Array or raw[chapter].size() != 3: continue
        for i in range(3): result[chapter][i] = bool(raw[chapter][i])
    return result

static func load_progress() -> Dictionary:
    var data: Dictionary = defaults()
    if not FileAccess.file_exists(SAVE): return data
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
    if not parsed is Dictionary or int(parsed.get("version",-1)) != VERSION: return data
    data.completed = _valid_completed(parsed.get("completed",[]))
    var raw: Variant = parsed.get("entered",[])
    if raw is Array and raw.size()==2: data.entered = [bool(raw[0]),bool(raw[1])]
    data.achievement_count = completed_count(data,0)+completed_count(data,1)
    return data

static func save_progress(data: Dictionary) -> bool:
    var clean: Dictionary = {
        "version":VERSION,
        "completed":_valid_completed(data.get("completed",[])),
        "entered":[false,false],
        "achievement_count":0
    }
    var raw: Variant = data.get("entered",[])
    if raw is Array and raw.size()==2: clean.entered = [bool(raw[0]),bool(raw[1])]
    clean.achievement_count = completed_count(clean,0)+completed_count(clean,1)
    var temp: String = SAVE + ".tmp"
    var file: FileAccess = FileAccess.open(temp,FileAccess.WRITE)
    if file == null: return false
    file.store_string(JSON.stringify(clean))
    file.close()
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp),ProjectSettings.globalize_path(SAVE)) == OK

static func completed_count(data: Dictionary, chapter: int) -> int:
    if chapter < 0 or chapter > 1: return 0
    var flags: Array = _valid_completed(data.get("completed",[]))[chapter]
    var count: int = 0
    for flag in flags:
        if bool(flag): count += 1
    return count

static func bosses_won(chapter: int) -> int:
    var saved: Dictionary = Shadow.load_progress() if chapter == 0 else Abyss.load_progress()
    var won: Array = saved.get("defeated",[])
    if won.size()!=3: return 0
    var count: int = 0
    for flag in won:
        if bool(flag): count += 1
    return count

static func story_finished(chapter: int) -> bool:
    if chapter not in [0,1]: return false
    var saved: Dictionary = Shadow.load_progress() if chapter == 0 else Abyss.load_progress()
    return bool(saved.get("completed",false)) and int(saved.get("page",1))==30

static func can_unlock(bosses: int, challenges: int, story_done: bool) -> bool:
    return bosses == 3 and challenges == 3 and story_done

static func ready(chapter: int) -> bool:
    if chapter not in [0,1]: return false
    return can_unlock(bosses_won(chapter),completed_count(load_progress(),chapter),story_finished(chapter))

static func unlocked(chapter: int) -> bool:
    if chapter == 0: return true
    if chapter == 1: return ready(0)
    if chapter == 2: return ready(0) and ready(1)
    return false

static func challenge_done(chapter: int, index: int) -> bool:
    if chapter not in [0,1] or index < 0 or index > 2: return false
    return bool(load_progress().completed[chapter][index])

static func record_challenge(chapter: int, index: int) -> bool:
    if chapter not in [0,1] or index not in [0,1,2]: return false
    if not unlocked(chapter) or challenge_done(chapter,index): return false
    var data: Dictionary = load_progress()
    data.completed[chapter][index] = true
    return save_progress(data)

static func enter_next_realm(chapter: int) -> bool:
    if chapter not in [0,1] or not ready(chapter): return false
    var data: Dictionary = load_progress()
    data.entered[chapter] = true
    return save_progress(data)

static func already_entered(chapter: int) -> bool:
    if chapter not in [0,1]: return false
    return bool(load_progress().entered[chapter])

static func task_title(chapter: int, index: int) -> String:
    if chapter not in [0,1] or index not in [0,1,2]: return ""
    return str(TITLES[chapter][index])

static func task_description(chapter: int, index: int, language: String) -> String:
    if chapter not in [0,1] or index not in [0,1,2]: return ""
    var copy: Array = DE if language=="de" else (PT if language=="pt" else EN)
    return str(copy[chapter][index])

static func _edge(line: Array) -> bool:
    return int(line[0]/16)!=int(line[3]/16)

static func _winning_moves(cells: Array, lines: Array, mark: int) -> Array:
    var wins: Array = []
    for cell in range(cells.size()):
        if int(cells[cell]) != 0: continue
        cells[cell] = mark
        if not ZenAscend.winning_lines(cells,lines,mark).is_empty(): wins.append(cell)
        cells[cell] = 0
    return wins

static func puzzle(chapter: int, index: int, lines: Array) -> Dictionary:
    # A genuine 96-cell native cube position with ONE legal tactical answer.
    # No synthetic wins, unlocks or free progress.
    if chapter not in [0,1] or index not in [0,1,2] or lines.size()!=204: return {}
    var kind: String = str(OBJECTIVES[chapter][index])
    var preferred_edge: bool = kind == "win_edge" or (kind=="block" and chapter==1)
    var owner: int = 2 if kind=="block" else 1
    var seed: int = (chapter*53 + index*29 + 7)%lines.size()
    for offset in range(lines.size()):
        var candidate: Array = lines[(seed+offset)%lines.size()]
        if _edge(candidate)!=preferred_edge: continue
        for missing in [3,0,2,1]:
            var cells: Array = []
            cells.resize(96)
            cells.fill(0)
            for n in range(4):
                if n!=missing: cells[int(candidate[n])] = owner
            var answers: Array = _winning_moves(cells,lines,owner)
            if answers.size()==1 and int(answers[0])==int(candidate[missing]):
                return {
                    "chapter":chapter,"index":index,"cells":cells,
                    "target":int(candidate[missing]),"kind":kind,
                    "mark":owner,"line":candidate.duplicate(),
                    "title":task_title(chapter,index)
                }
    return {}

static func valid_move(puzzle_data: Dictionary, cell: int, lines: Array) -> bool:
    var cells: Array = puzzle_data.get("cells",[])
    if cells.size()!=96 or cell<0 or cell>=96 or int(cells[cell])!=0: return false
    var kind: String = str(puzzle_data.get("kind",""))
    var mark: int = 2 if kind=="block" else 1
    var threats: Array = _winning_moves(cells,lines,mark)
    if threats.size()!=1 or int(threats[0])!=cell: return false
    # Verify the exact four in a row using the production game's win detector.
    cells[cell] = mark
    var valid: bool = not ZenAscend.winning_lines(cells,lines,mark).is_empty()
    cells[cell] = 0
    return valid
