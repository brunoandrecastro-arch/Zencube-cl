extends RefCounted
# Pure selection logic; no mutations of Tower state or rewards.
const Tower = preload("res://core/ZenTower.gd")
const ROOT_VIDEO = "res://assets/video/tower_rootbound_warden_defeat.ogv"
const WIND_VIDEO = "res://assets/video/tower_windweave_keeper_defeat.ogv"
const ROOT_GATE = "res://assets/video/tower_root_to_wind_gate.ogv"

static func guardian_video(id: String) -> String:
    match id:
        "zen_tower_001_rootbound_warden": return ROOT_VIDEO
        "zen_tower_002_windweave_keeper": return WIND_VIDEO
        _: return ""

static func defeat_for(outcome: Dictionary) -> String:
    if not bool(outcome.get("boss",false)) or not bool(outcome.get("series_complete",false)) or not bool(outcome.get("floor_complete",false)) or int(outcome.get("winner",0)) != 1:
        return ""
    return guardian_video(str(outcome.get("unlocked_card","")))

static func transition_for(outcome: Dictionary) -> String:
    if not bool(outcome.get("floor_complete",false)) or int(outcome.get("winner",0)) != 1: return ""
    var stage: int = int(outcome.get("completed_floor",0))
    if stage == 100 and int(outcome.get("next_floor",0)) == 101: return "ascend"
    if bool(outcome.get("boss",false)):
        if not bool(outcome.get("series_complete",false)): return ""
        if Tower.cycle_floor(stage) == 15: return ROOT_GATE
        return "guardian"
    return "fade"
