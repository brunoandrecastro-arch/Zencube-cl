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
        "zen_tower_003_stillwater_dragon": return "res://assets/video/tower_stillwater_dragon_defeat.ogv"
        "zen_tower_004_amber_fox": return "res://assets/video/tower_amber_fox_defeat.ogv"
        "zen_tower_005_snowbound_kirin": return "res://assets/video/tower_snowbound_kirin_defeat.ogv"
        "zen_tower_006_dawnwing_crane": return "res://assets/video/tower_dawnwing_crane_defeat.ogv"
        "zen_tower_007_eclipse_sovereign": return "res://assets/video/tower_eclipse_sovereign_defeat.ogv"
        _: return ""

static func defeat_for(outcome: Dictionary) -> String:
    if not bool(outcome.get("boss",false)) or not bool(outcome.get("series_complete",false)) or not bool(outcome.get("floor_complete",false)) or int(outcome.get("winner",0)) != 1:
        return ""
    return guardian_video(str(outcome.get("unlocked_card","")))

static func transition_for(outcome: Dictionary) -> String:
    if not bool(outcome.get("floor_complete",false)) or int(outcome.get("winner",0)) != 1: return ""
    var stage: int = int(outcome.get("completed_floor",0))
    if stage == 100 and int(outcome.get("next_floor",0)) == 101 and bool(outcome.get("boss",false)) and bool(outcome.get("series_complete",false)): return "res://assets/video/tower_eclipse_to_ascend_gate.ogv"
    if bool(outcome.get("boss",false)):
        if not bool(outcome.get("series_complete",false)): return ""
        match Tower.cycle_floor(stage):
            15: return ROOT_GATE
            30: return "res://assets/video/tower_wind_to_water_gate.ogv"
            45: return "res://assets/video/tower_water_to_amber_gate.ogv"
            60: return "res://assets/video/tower_amber_to_frost_gate.ogv"
            75: return "res://assets/video/tower_frost_to_dawn_gate.ogv"
            90: return "res://assets/video/tower_dawn_to_eclipse_gate.ogv"
            _: return "guardian"
    return ""
