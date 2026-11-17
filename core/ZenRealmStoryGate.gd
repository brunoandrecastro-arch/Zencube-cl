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
    if not FileAccess.file_exists(STORY_SAVE): return 0
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(STORY_SAVE))
    if not parsed is Dictionary or int(parsed.get("version",-1)) != 1: return 0
    var stage: int = clampi(int(parsed.get("stage",0)),0,REALM_COUNT*BOSSES_PER_REALM)
    return clampi(stage-realm*BOSSES_PER_REALM,0,BOSSES_PER_REALM)

static func defeated_all(realm: int) -> bool:
    return defeated_bosses(realm) == BOSSES_PER_REALM

static func progress_summary(realm: int, language: String) -> String:
    var bosses: int = defeated_bosses(realm)
    if language == "de": return "Story-Bosse: %d/3" % bosses
    if language == "pt": return "Chefes da história: %d/3" % bosses
    return "Story bosses: %d/3" % bosses
