class_name ZenRealmStoryGate
extends RefCounted
## Read-only bridge from the independent Realm Chronicles save to normal 4x4
## progression. No circular preload: ZenRealmChronicles depends on
## ZenAscendRealms, so the Realms class must not depend on the Story class.
## A story stage is the number of consecutively beaten bosses (0..12).
const STORY_SAVE := "user://zencube_realm_chronicles_v1.json"
const BOSSES_PER_REALM := 3
const REALM_COUNT := 4

static func defeated_bosses(realm: int) -> int:
    if realm < 0 or realm >= REALM_COUNT: return 0
    var old_count: int = 0
    if FileAccess.file_exists(STORY_SAVE):
        var legacy: Variant = JSON.parse_string(FileAccess.get_file_as_string(STORY_SAVE))
        if legacy is Dictionary and int(legacy.get("version",-1))==1:
            var stage: int = clampi(int(legacy.get("stage",0)),0,REALM_COUNT*BOSSES_PER_REALM)
            old_count = clampi(stage-realm*BOSSES_PER_REALM,0,BOSSES_PER_REALM)
    # Campaign 2.0 has independent saves. Count genuinely defeated bosses
    # from either storyline; never mint achievements or alter the save data.
    var recent_saves: Array[String] = [
        "user://zencube_shadow_campaign_v1.json",
        "user://zencube_ember_campaign_v1.json",
        "user://zencube_celestial_campaign_v1.json",
        "user://zencube_satori_campaign_v1.json"
    ]
    var recent_count: int = 0
    var path: String = recent_saves[realm]
    if FileAccess.file_exists(path):
        var new_progress: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
        if new_progress is Dictionary and int(new_progress.get("version",-1))==1:
            var wins: Variant = new_progress.get("defeated",[])
            if wins is Array and wins.size()==BOSSES_PER_REALM:
                for win in wins:
                    if not bool(win): break
                    recent_count += 1
    return maxi(old_count,recent_count)

static func defeated_all(realm: int) -> bool:
    return defeated_bosses(realm) == BOSSES_PER_REALM

static func progress_summary(realm: int, language: String) -> String:
    var bosses: int = defeated_bosses(realm)
    if language == "de": return "Story-Bosse: %d/3" % bosses
    if language == "pt": return "Chefes da história: %d/3" % bosses
    return "Story bosses: %d/3" % bosses
