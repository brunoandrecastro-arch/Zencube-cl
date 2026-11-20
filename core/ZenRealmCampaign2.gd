extends RefCounted
## ZenCube 2.0 Realm: achievements are earned in normal 4x4 Zen-Bot
## matches, never by tapping on an individually launched tactical puzzle.
## Legacy Realm achievements / leaves are the source of truth for Shadow.
const Shadow = preload("res://story/ZenShadowCampaign.gd")
const Abyss = preload("res://story/ZenAbyssCampaign.gd")
const Ember = preload("res://story/ZenEmberCampaign.gd")
const Celestial = preload("res://story/ZenCelestialCampaign.gd")
const Realms = preload("res://core/ZenAscendRealms.gd")
const Ascend = preload("res://core/ZenAscend.gd")
const SAVE := "user://zencube_realm_2_0_v2.json"
const VERSION := 2
const REALM_NAMES: Array[String] = ["Shadow Realm","Abyss of Memories","Ember Temple","Celestial Realm","Satori Realm"]
const SOURCE_ART: Array[String] = [
    "res://assets/realms/shadow_realm.webp",
    "res://assets/abyss_of_memories/realm.webp",
    "res://assets/ember_campaign/realm.webp",
    "res://assets/realms/celestial_realm.webp",
    "res://assets/realms/satori_realm.webp"
]
# Three existing, automatically awarded regular 4x4 Shadow tasks.
const SHADOW_TASK_IDS: Array[String] = ["shadow_first","shadow_edge","shadow_block"]
const ABYSS_TITLES: Array[String] = ["First Echo","Across the Memories","The Three Remembrances"]
const ABYSS_DE: Array[String] = [
    "Gewinne eine reguläre Abyss-Partie gegen den Zen-Bot.",
    "Gewinne mit einer Viererlinie über eine Würfelkante.",
    "Gewinne insgesamt drei reguläre Abyss-Partien."
]
const ABYSS_EN: Array[String] = [
    "Win a regular Abyss match against the Zen-Bot.",
    "Win with four marks across a cube edge.",
    "Win three regular Abyss matches in total."
]
const ABYSS_PT: Array[String] = [
    "Vence uma partida normal de Abyss contra o Zen-Bot.",
    "Vence com quatro símbolos através de uma aresta do cubo.",
    "Vence três partidas normais de Abyss no total."
]

static func qa_mode() -> bool:
    return OS.has_feature("zencube_realm_2_0_test")

static func base_unlocked() -> bool:
    # No QA bypass: the Story is locked until real, persistent 4x4 ownership.
    return Ascend.unlocked(SaveManager.load_data())

static func defaults() -> Dictionary:
    return {"version":VERSION,"entered":[false,false,false,false],
        "abyss_stats":{"played":0,"wins":0,"edge_wins":0,"losses":0,"draws":0},
        "ember_stats":{"played":0,"wins":0,"edge_wins":0,"losses":0,"draws":0},
        "celestial_stats":{"played":0,"wins":0,"edge_wins":0,"block_wins":0,"losses":0,"draws":0}}

static func load_progress() -> Dictionary:
    var data: Dictionary = defaults()
    if not FileAccess.file_exists(SAVE): return data
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
    if not parsed is Dictionary or int(parsed.get("version",-1)) != VERSION: return data
    var flags: Variant = parsed.get("entered",[])
    if flags is Array and flags.size()>=2:
        data.entered = [bool(flags[0]),bool(flags[1]),bool(flags[2]) if flags.size()>2 else false,bool(flags[3]) if flags.size()>3 else false]
    var stats: Variant = parsed.get("abyss_stats",{})
    if stats is Dictionary:
        for key in data.abyss_stats.keys():
            data.abyss_stats[key] = maxi(0,int(stats.get(key,0)))
    data.abyss_stats.wins = mini(int(data.abyss_stats.wins),int(data.abyss_stats.played))
    data.abyss_stats.edge_wins = mini(int(data.abyss_stats.edge_wins),int(data.abyss_stats.wins))
    var ember_stats: Variant = parsed.get("ember_stats",{})
    if ember_stats is Dictionary:
        for key in data.ember_stats.keys():
            data.ember_stats[key] = maxi(0,int(ember_stats.get(key,0)))
    data.ember_stats.wins = mini(int(data.ember_stats.wins),int(data.ember_stats.played))
    data.ember_stats.edge_wins = mini(int(data.ember_stats.edge_wins),int(data.ember_stats.wins))
    var celestial_stats: Variant = parsed.get("celestial_stats",{})
    if celestial_stats is Dictionary:
        for key in data.celestial_stats.keys():
            data.celestial_stats[key] = maxi(0,int(celestial_stats.get(key,0)))
    return data

static func save_progress(data: Dictionary) -> bool:
    var clean: Dictionary = defaults()
    var flags: Variant = data.get("entered",[])
    if flags is Array and flags.size()>=2: clean.entered = [bool(flags[0]),bool(flags[1]),bool(flags[2]) if flags.size()>2 else false,bool(flags[3]) if flags.size()>3 else false]
    var stats: Variant = data.get("abyss_stats",{})
    if stats is Dictionary:
        for key in clean.abyss_stats.keys():
            clean.abyss_stats[key] = maxi(0,int(stats.get(key,0)))
    var ember_stats: Variant = data.get("ember_stats",{})
    if ember_stats is Dictionary:
        for key in clean.ember_stats.keys():
            clean.ember_stats[key] = maxi(0,int(ember_stats.get(key,0)))
    var celestial_stats: Variant = data.get("celestial_stats",{})
    if celestial_stats is Dictionary:
        for key in clean.celestial_stats.keys():
            clean.celestial_stats[key] = maxi(0,int(celestial_stats.get(key,0)))
    var path: String = SAVE+".tmp"
    var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
    if file==null: return false
    file.store_string(JSON.stringify(clean))
    file.close()
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(SAVE))==OK

static func shadow_task(index: int) -> Dictionary:
    if index<0 or index>=3: return {}
    for task in Realms.TASKS[0]:
        if str(task.id)==SHADOW_TASK_IDS[index]: return task
    return {}

static func challenge_done(chapter: int, index: int) -> bool:
    if chapter not in [0,1,2,3] or index not in [0,1,2]: return false
    if chapter==0:
        var task: Dictionary = shadow_task(index)
        if task.is_empty(): return false
        var saved: Dictionary = SaveManager.load_data()
        Realms.ensure(saved)
        return bool(Realms.state(saved).completed.get(str(task.id),false))
    if chapter==3:
        var celestial: Dictionary = load_progress().celestial_stats
        return int(celestial.wins)>=1 if index==0 else (int(celestial.block_wins)>=1 if index==1 else int(celestial.edge_wins)>=1)
    var stats: Dictionary = load_progress().ember_stats if chapter==2 else load_progress().abyss_stats
    if index==0: return int(stats.wins)>=1
    if chapter==2:
        return int(stats.wins)>=3 if index==1 else int(stats.edge_wins)>=1
    if index==1: return int(stats.edge_wins)>=1
    return int(stats.wins)>=3

static func completed_count(_data: Dictionary, chapter: int) -> int:
    if chapter not in [0,1,2,3]: return 0
    var count: int = 0
    for i in range(3):
        if challenge_done(chapter,i): count+=1
    return count

static func bosses_won(chapter: int) -> int:
    if chapter not in [0,1,2,3]: return 0
    var saved: Dictionary = Shadow.load_progress() if chapter==0 else (Abyss.load_progress() if chapter==1 else (Ember.load_progress() if chapter==2 else Celestial.load_progress()))
    var won: Array = saved.get("defeated",[])
    if won.size()!=3: return 0
    var count: int = 0
    for flag in won:
        if bool(flag): count+=1
    return count

static func story_finished(chapter: int) -> bool:
    if chapter not in [0,1,2,3]: return false
    var saved: Dictionary = Shadow.load_progress() if chapter==0 else (Abyss.load_progress() if chapter==1 else (Ember.load_progress() if chapter==2 else Celestial.load_progress()))
    return bool(saved.get("completed",false)) and int(saved.get("page",1))==30

# The final win opens the remaining pages; Finish Chapter confirms travel.
static func can_unlock(bosses: int, challenges: int, story_done: bool) -> bool:
    return bosses==3 and challenges==3 and story_done

static func final_boss_waiting(chapter: int) -> bool:
    if not can_face_boss(chapter,2): return false
    if bosses_won(chapter)!=2: return false
    var progress: Dictionary = Shadow.load_progress() if chapter==0 else (Abyss.load_progress() if chapter==1 else (Ember.load_progress() if chapter==2 else Celestial.load_progress()))
    var action: Dictionary = Shadow.next_action(progress) if chapter==0 else (Abyss.next_action(progress) if chapter==1 else (Ember.next_action(progress) if chapter==2 else Celestial.next_action(progress)))
    return action.get("type")=="battle" and int(action.get("boss",-1))==2

static func can_face_boss(chapter: int, boss: int) -> bool:
    if chapter not in [0,1,2,3] or boss not in [0,1,2]: return false
    if not unlocked(chapter): return false
    return boss < 2 or completed_count(load_progress(),chapter)==3

static func ready(chapter: int) -> bool:
    if chapter not in [0,1,2,3] or not base_unlocked(): return false
    # Preserve access already earned in Build 361, which recorded travel early.
    return can_unlock(bosses_won(chapter),completed_count(load_progress(),chapter),story_finished(chapter) or already_entered(chapter))

static func unlocked(chapter: int) -> bool:
    if not base_unlocked(): return false
    if chapter==0: return true
    if chapter==1: return ready(0)
    if chapter==2: return ready(0) and ready(1)
    if chapter==3: return Ascend.test_access_enabled() or (ready(0) and ready(1) and ready(2))
    if chapter==4: return ready(3) and unlocked(3)
    return false

static func task_title(chapter: int, index: int, language: String = "en") -> String:
    if chapter not in [0,1,2,3] or index not in [0,1,2]: return ""
    if chapter==0: return Realms.localized_name(str(shadow_task(index).get("title","")),language)
    if chapter==3: return ["Foresight","Inner Stillness","Perfect Harmony"][index]
    if chapter==2: return ["Tactics","Endurance","Clarity"][index]
    return ABYSS_TITLES[index]

static func task_description(chapter: int, index: int, language: String) -> String:
    if chapter not in [0,1,2,3] or index not in [0,1,2]: return ""
    if chapter==0: return Realms.task_description(shadow_task(index),language)
    if chapter==3:
        var de: Array = ["Gewinne eine Celestial-Partie gegen den Zen-Bot.","Blockiere eine unmittelbare gegnerische Gewinnlinie und gewinne die Partie.","Gewinne mit vier Markierungen über eine Würfelkante."]
        var en: Array = ["Win a Celestial match against the Zen-Bot.","Block an immediate winning threat and win the match.","Win with four marks across a cube edge."]
        var pt: Array = ["Vence uma partida Celestial contra o Zen-Bot.","Bloqueia uma vitória imediata do adversário e vence a partida.","Vence com quatro símbolos através de uma aresta do cubo."]
        return str((de if language=="de" else (pt if language=="pt" else en))[index])
    if chapter==2:
        var de: Array = ["Gewinne eine Ember-Partie gegen den Zen-Bot.","Gewinne insgesamt drei Ember-Partien gegen den Zen-Bot.","Gewinne eine Ember-Partie mit vier Markierungen über eine Würfelkante."]
        var en: Array = ["Win an Ember match against the Zen-Bot.","Win three Ember matches against the Zen-Bot.","Win an Ember match with four marks across a cube edge."]
        var pt: Array = ["Vence uma partida Ember contra o Zen-Bot.","Vence três partidas Ember contra o Zen-Bot.","Vence uma partida Ember com quatro símbolos através de uma aresta."]
        return str((de if language=="de" else (pt if language=="pt" else en))[index])
    var pool: Array = ABYSS_DE if language=="de" else (ABYSS_PT if language=="pt" else ABYSS_EN)
    return str(pool[index])

static func record_abyss_match(outcome: int, over_edge: bool) -> Array[String]:
    # Called ONLY after a finished, genuine Abyss free-play match vs the bot.
    # outcome: 1 human victory, 0 draw, -1 loss. No Classic 3x3 or 4x4
    # Realm ranks, leaves, or secret achievements are changed.
    if not base_unlocked() or not unlocked(1) or outcome not in [-1,0,1]: return []
    var old: Array[bool] = [challenge_done(1,0),challenge_done(1,1),challenge_done(1,2)]
    var data: Dictionary = load_progress()
    var stats: Dictionary = data.abyss_stats
    stats.played = int(stats.played)+1
    if outcome==1:
        stats.wins = int(stats.wins)+1
        if over_edge: stats.edge_wins = int(stats.edge_wins)+1
    elif outcome==0:
        stats.draws = int(stats.draws)+1
    else:
        stats.losses = int(stats.losses)+1
    data.abyss_stats = stats
    if not save_progress(data): return []
    var newly_earned: Array[String] = []
    for i in range(3):
        if not old[i] and challenge_done(1,i):
            newly_earned.append(task_title(1,i))
    return newly_earned

static func record_ember_match(outcome: int, over_edge: bool) -> Array[String]:
    # Called ONLY after a finished, genuine Abyss free-play match vs the bot.
    # outcome: 1 human victory, 0 draw, -1 loss. No Classic 3x3 or 4x4
    # Realm ranks, leaves, or secret achievements are changed.
    if not base_unlocked() or not unlocked(2) or outcome not in [-1,0,1]: return []
    var old: Array[bool] = [challenge_done(2,0),challenge_done(2,1),challenge_done(2,2)]
    var data: Dictionary = load_progress()
    var stats: Dictionary = data.ember_stats
    stats.played = int(stats.played)+1
    if outcome==1:
        stats.wins = int(stats.wins)+1
        if over_edge: stats.edge_wins = int(stats.edge_wins)+1
    elif outcome==0:
        stats.draws = int(stats.draws)+1
    else:
        stats.losses = int(stats.losses)+1
    data.ember_stats = stats
    if not save_progress(data): return []
    var newly_earned: Array[String] = []
    for i in range(3):
        if not old[i] and challenge_done(2,i):
            newly_earned.append(task_title(2,i))
    return newly_earned

static func record_celestial_match(outcome: int, over_edge: bool, blocked: bool) -> Array[String]:
    if not unlocked(3) or outcome not in [-1,0,1]: return []
    if int(Celestial.load_progress().page)<19: return []
    var old: Array[bool] = [challenge_done(3,0),challenge_done(3,1),challenge_done(3,2)]
    var data: Dictionary = load_progress()
    var stats: Dictionary = data.celestial_stats
    stats.played = int(stats.played)+1
    if outcome==1:
        stats.wins = int(stats.wins)+1
        if over_edge: stats.edge_wins = int(stats.edge_wins)+1
        if blocked: stats.block_wins = int(stats.block_wins)+1
    elif outcome==0:
        stats.draws = int(stats.draws)+1
    else:
        stats.losses = int(stats.losses)+1
    data.celestial_stats = stats
    if not save_progress(data): return []
    var earned: Array[String] = []
    for i in range(3):
        if not old[i] and challenge_done(3,i): earned.append(task_title(3,i))
    return earned

static func enter_next_realm(chapter: int) -> bool:
    if chapter not in [0,1,2,3] or not ready(chapter): return false
    var data: Dictionary = load_progress()
    data.entered[chapter] = true
    return save_progress(data)

static func already_entered(chapter: int) -> bool:
    if chapter not in [0,1,2,3]: return false
    return bool(load_progress().entered[chapter])
