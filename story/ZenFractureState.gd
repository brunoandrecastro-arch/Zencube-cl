extends RefCounted
## A separate, one-use cinematic checkpoint. Existing rank, economy and Realm saves are never reset.
const PATH := "user://zencube_moon_shadow_transition_v1.json"
const VERSION := 1

static func defaults() -> Dictionary:
    return {"version":VERSION,"portal":false,"awakening":false}

static func state() -> Dictionary:
    var empty: Dictionary = defaults()
    if not FileAccess.file_exists(PATH): return empty
    var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
    if not raw is Dictionary or int(raw.get("version",0))!=VERSION: return empty
    empty.portal = bool(raw.get("portal",false))
    empty.awakening = bool(raw.get("awakening",false))
    return empty

static func portal_seen() -> bool:
    return bool(state().portal)

static func awakening_seen() -> bool:
    return bool(state().awakening)

static func _save(data: Dictionary) -> bool:
    var temp: String = PATH+".tmp"
    var out: FileAccess = FileAccess.open(temp,FileAccess.WRITE)
    if out==null: return false
    out.store_string(JSON.stringify(data))
    out.flush()
    var ok: Error = out.get_error()
    out.close()
    if ok!=OK: return false
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp),ProjectSettings.globalize_path(PATH))==OK

static func mark_portal() -> bool:
    var saved: Dictionary = state()
    saved.portal = true
    return _save(saved)

static func mark_awakening() -> bool:
    var saved: Dictionary = state()
    saved.portal = true
    saved.awakening = true
    return _save(saved)
