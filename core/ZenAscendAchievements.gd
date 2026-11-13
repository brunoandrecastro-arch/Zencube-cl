class_name ZenAscendAchievements
extends RefCounted
# Independent secret accomplishments. Realm Challenges keep their original
# eight-task logic; titles are now earned only at full Realm mastery.
const MAIN_TITLES: Array[String] = [
    "Master of Shadows", "Ember Master", "Celestial Master", "Fully Aware"
]
const MAIN_QUOTES: Array[String] = [
    "Even in darkness, your path remains clear.",
    "The fiercest flame bends to a patient mind.",
    "Above the clouds, every move finds its meaning.",
    "The still mind sees beyond every edge."
]
# Names are preserved from the previous five-tier Realm title catalogue.
# Each now has an independent statistic-based unlock condition, not a
# duplicate of the 1/2/4/6/8 completed-Challenge title ladder.
const SECRETS: Array = [
    {"id":"shadow_walker","realm":0,"name":"Shadow Walker","metric":"wins","need":2,"condition":"Win 2 matches in Shadow Realm.","quote":"Every long journey begins where the light ends."},
    {"id":"keeper_silence","realm":0,"name":"Keeper of Silence","metric":"best_streak","need":3,"condition":"Win 3 Shadow Realm matches in a row.","quote":"Silence is not empty. It is full of answers."},
    {"id":"moon_disciple","realm":0,"name":"Moon Disciple","metric":"edge_wins","need":2,"condition":"Win 2 Shadow matches across a cube edge.","quote":"The moon lights paths unseen by day."},
    {"id":"veil_breaker","realm":0,"name":"Veil Breaker","metric":"block_wins","need":2,"condition":"Win 2 Shadow matches after blocking an immediate loss.","quote":"Beyond the veil, fear becomes focus."},
    {"id":"ember_initiate","realm":1,"name":"Ember Initiate","metric":"wins","need":2,"condition":"Win 2 Ember Temple matches.","quote":"A single spark can light a thousand steps."},
    {"id":"flame_disciple","realm":1,"name":"Flame Disciple","metric":"hard_win","need":2,"condition":"Win 2 Ember matches on Hard or higher.","quote":"The flame tests resolve, not haste."},
    {"id":"temple_challenger","realm":1,"name":"Temple Challenger","metric":"face_wins","need":2,"condition":"Win 2 Ember matches with a line on one face.","quote":"Stand before the fire, and let purpose lead."},
    {"id":"fire_strategist","realm":1,"name":"Fire-Bound Strategist","metric":"best_hard_streak","need":3,"condition":"Win 3 Ember matches in a row on Hard or higher.","quote":"A steady heart commands even the wildest fire."},
    {"id":"sky_seeker","realm":2,"name":"Sky Seeker","metric":"wins","need":3,"condition":"Win 3 Celestial Realm matches.","quote":"Those who seek the sky first learn to stand still."},
    {"id":"cloud_disciple","realm":2,"name":"Cloud Disciple","metric":"best_streak","need":4,"condition":"Win 4 Celestial matches in a row.","quote":"Clouds drift. Clarity remains."},
    {"id":"light_weaver","realm":2,"name":"Light Weaver","metric":"edge_wins","need":3,"condition":"Win 3 Celestial matches across cube edges.","quote":"A single thread of light connects distant worlds."},
    {"id":"celestial_adept","realm":2,"name":"Celestial Adept","metric":"master_win","need":2,"condition":"Win 2 Celestial matches on Master or higher.","quote":"The highest view belongs to the quietest mind."},
    {"id":"mind_awakened","realm":3,"name":"Mind Awakened","metric":"wins","need":2,"condition":"Win 2 Satori Realm matches.","quote":"Awareness begins when distraction ends."},
    {"id":"stillness_walker","realm":3,"name":"Stillness Walker","metric":"best_master_streak","need":2,"condition":"Win 2 Satori matches in a row on Master or higher.","quote":"To move without haste is to master the moment."},
    {"id":"satori_adept","realm":3,"name":"Satori Adept","metric":"block_wins","need":3,"condition":"Win 3 Satori matches after blocking an immediate loss.","quote":"Insight arrives between one breath and the next."},
    {"id":"keeper_awareness","realm":3,"name":"Keeper of Awareness","metric":"grand_win","need":1,"condition":"Win a Satori match against Grandmaster.","quote":"To see the whole is to fear no single move."},
]

static func ensure(data: Dictionary) -> void:
    var st: Dictionary = ZenAscendRealms.state(data)
    if not st.get("secret_achievements") is Dictionary:
        st["secret_achievements"] = {}

static func earned(data: Dictionary, key: String) -> bool:
    ensure(data)
    return bool(ZenAscendRealms.state(data).secret_achievements.get(key, false))

static func claim_after_match(data: Dictionary, realm: int) -> Array:
    ensure(data)
    var result: Array = []
    var st: Dictionary = ZenAscendRealms.state(data)
    var completed: Dictionary = st.secret_achievements
    var stats: Dictionary = st.stats[clampi(realm,0,3)]
    for item in SECRETS:
        if int(item.realm) != realm: continue
        var key: String = str(item.id)
        if bool(completed.get(key,false)): continue
        if int(stats.get(str(item.metric),0)) >= int(item.need):
            completed[key] = true
            result.append(item)
    return result

static func main_title(data: Dictionary, realm: int) -> String:
    if realm < 0 or realm > 3: return "—"
    if ZenAscendRealms.count(data,realm) < 8: return "—"
    return MAIN_TITLES[realm]

static func main_quote(realm: int) -> String:
    return MAIN_QUOTES[clampi(realm,0,3)]

static func secret_count(data: Dictionary) -> int:
    ensure(data)
    var total: int = 0
    for item in SECRETS:
        if earned(data,str(item.id)): total += 1
    return total
