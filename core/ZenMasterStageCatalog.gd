class_name ZenMasterStageCatalog
extends RefCounted

# Stage-art contract for the independent Zen Master 5x5 campaign.
# Boss portraits and arena art are TWO DIFFERENT resources.
# These paths are planned; background assets must be created and imported before
# enabling any boss stage. Never fall back silently to another boss's background.
const STAGES: Array[Dictionary] = [
    {"realm":"void_sanctuary", "boss":"nameless_ronin", "role":"mid", "arena":"The Forgotten Dojo", "art":"res://assets/zen_master/arenas/void_sanctuary/nameless_ronin.webp", "mood":"Broken torii, empty duel court, drifting ash, violet eclipse"},
    {"realm":"void_sanctuary", "boss":"weeping_oracle", "role":"mid", "arena":"Lake of Unspoken Tears", "art":"res://assets/zen_master/arenas/void_sanctuary/weeping_oracle.webp", "mood":"Flooded shrine, suspended mirrors, tear-black water, spectral lanterns"},
    {"realm":"void_sanctuary", "boss":"void_executioner", "role":"mid", "arena":"The Chained Gate", "art":"res://assets/zen_master/arenas/void_sanctuary/void_executioner.webp", "mood":"Obsidian fortress gate, iron chains, fractured stone bridge, void rifts"},
    {"realm":"void_sanctuary", "boss":"hollow_abbot", "role":"final", "arena":"Sanctum of Holy Emptiness", "art":"res://assets/zen_master/arenas/void_sanctuary/hollow_abbot.webp", "mood":"Sacred silent chamber, shattered sutras, fragmented halo, dark lotus pool"},

    {"realm":"moonlit_garden", "boss":"silver_kitsune", "role":"mid", "arena":"Nine-Tail Lantern Grove", "art":"res://assets/zen_master/arenas/moonlit_garden/silver_kitsune.webp", "mood":"Moonlit bamboo and sakura grove, nine foxfire lantern trails"},
    {"realm":"moonlit_garden", "boss":"petal_dancer", "role":"mid", "arena":"Petalfall Pavilion", "art":"res://assets/zen_master/arenas/moonlit_garden/petal_dancer.webp", "mood":"Open silk-draped dance pavilion, vortex of cherry petals, reflecting pools"},
    {"realm":"moonlit_garden", "boss":"moonless_knight", "role":"mid", "arena":"Garden of the Eclipsed Moon", "art":"res://assets/zen_master/arenas/moonlit_garden/moonless_knight.webp", "mood":"Abandoned stone bridge, black lunar eclipse, unlit torches, broken crescent"},
    {"realm":"moonlit_garden", "boss":"tsukihana", "role":"final", "arena":"Temple of the Last Blossom", "art":"res://assets/zen_master/arenas/moonlit_garden/tsukihana.webp", "mood":"Moon waterfall, blossom throne, mirrored koi pond, radiant sakura boughs"},

    {"realm":"astral_monastery", "boss":"comet_guardian", "role":"mid", "arena":"Falling-Star Causeway", "art":"res://assets/zen_master/arenas/astral_monastery/comet_guardian.webp", "mood":"Narrow sky bridge, meteor streaks, clouds and blue-gold flame"},
    {"realm":"astral_monastery", "boss":"silent_astronomer", "role":"mid", "arena":"Observatory of Hidden Patterns", "art":"res://assets/zen_master/arenas/astral_monastery/silent_astronomer.webp", "mood":"Ancient observatory, immense astrolabe, rotating zodiac charts"},
    {"realm":"astral_monastery", "boss":"seven_stars_keeper", "role":"mid", "arena":"Seven-Star Trial", "art":"res://assets/zen_master/arenas/astral_monastery/seven_stars_keeper.webp", "mood":"Seven luminous pillars, orbiting sigils and open cosmos"},
    {"realm":"astral_monastery", "boss":"star_bell_master", "role":"final", "arena":"Belfry of a Thousand Rings", "art":"res://assets/zen_master/arenas/astral_monastery/star_bell_master.webp", "mood":"Celestial pagoda of floating bells, luminous star mandala, golden sound waves"},

    {"realm":"origin_realm", "boss":"forgotten_self", "role":"mid", "arena":"Gallery of Lost Names", "art":"res://assets/zen_master/arenas/origin_realm/forgotten_self.webp", "mood":"Dust-covered mirror corridor, fading portraits, memory fractures"},
    {"realm":"origin_realm", "boss":"eternal_judge", "role":"mid", "arena":"Tribunal of First Light", "art":"res://assets/zen_master/arenas/origin_realm/eternal_judge.webp", "mood":"Symmetrical cosmic court, suspended golden scales, white-violet pillars"},
    {"realm":"origin_realm", "boss":"mirror_of_kuze", "role":"mid", "arena":"Hall of Two Selves", "art":"res://assets/zen_master/arenas/origin_realm/mirror_of_kuze.webp", "mood":"Infinite reflective floor, opposing light and shadow doorways"},
    {"realm":"origin_realm", "boss":"first_witness", "role":"final", "arena":"Before the First Dawn", "art":"res://assets/zen_master/arenas/origin_realm/first_witness.webp", "mood":"Primordial void splitting into light and dark around the original cube"}
]

static func stage_for(boss_id: String) -> Dictionary:
    for stage in STAGES:
        if stage["boss"] == boss_id:
            return stage.duplicate(true)
    return {}

static func validate() -> bool:
    if STAGES.size() != 16:
        return false
    var keys: Dictionary = {}
    var arts: Dictionary = {}
    var realms: Dictionary = {}
    var counts: Dictionary = {}
    for stage in STAGES:
        var realm: String = stage.get("realm", "")
        var boss: String = stage.get("boss", "")
        var art: String = stage.get("art", "")
        var role: String = stage.get("role", "")
        if realm.is_empty() or boss.is_empty() or art.is_empty():
            return false
        if keys.has(boss) or arts.has(art):
            return false
        if not art.begins_with("res://assets/zen_master/arenas/%s/" % realm):
            return false
        if role != "mid" and role != "final":
            return false
        keys[boss] = true
        arts[art] = true
        realms[realm] = true
        counts[realm] = int(counts.get(realm, 0)) + 1
    if realms.size() != 4:
        return false
    for realm in realms:
        if int(counts[realm]) != 4:
            return false
    return true

# This is intentionally strict. A production campaign cannot claim a stage
# is visually finished until its unique matching background exists on disk.
static func all_arena_art_imported() -> bool:
    if not validate():
        return false
    for stage in STAGES:
        if not ResourceLoader.exists(stage["art"]):
            return false
    return true
