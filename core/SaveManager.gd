class_name SaveManager
extends RefCounted
const PATH = "user://zencube.json"
const VERSION = 3
static func defaults() -> Dictionary:
    return {"version":VERSION,"settings":{"mode":1,"level":0,"swap":false,"alternate":true,"next_start":0,"hints":true,"sound":true,"haptics":true,"music":true,"music_track":0,"language":"","intro_seen":false,"tutorial_seen":false,"names":["Du","Spieler 2"]},"stats":{"played":0,"p1":0,"p2":0,"draw":0,"ai_wins":[0,0,0,0,0],"ai_losses":[0,0,0,0,0],"starter_wins":0,"second_wins":0,"starter_draws":0},"ascension":{"completed":[false,false,false,false,false],"streaks":[0,0,0,0,0],"rank":0,"world":0},"economy":{"leaves":0,"owned":[0],"equipped":0,"migrated":false},"ascend":{},"game":{}}
static func load_data() -> Dictionary:
    var base = defaults()
    if not FileAccess.file_exists(PATH): return base
    var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
    if not data is Dictionary: return base
    var ver := int(data.get("version",0))
    if ver != VERSION:
        # The previous versions used three-in-a-row (120 or 72 lines).
        # Never restore their games or results into the new four-in-a-row engine.
        if data.get("settings") is Dictionary:
            for setting in ["hints","sound","alternate"]:
                if data.settings.has(setting): base.settings[setting] = data.settings[setting]
        return base
    for key in ["settings","stats"]:
        if data.get(key) is Dictionary: base[key].merge(data[key],true)
    if data.get("game") is Dictionary: base.game = data.game
    if data.get("ascension") is Dictionary: base.ascension.merge(data.ascension, true)
    if data.get("economy") is Dictionary: base.economy.merge(data.economy, true)
    if data.get("ascend") is Dictionary: base.ascend.merge(data.ascend, true)
    for key in ["ai_wins", "ai_losses"]:
        var raw_values: Variant = base.stats.get(key, [])
        var values: Array = raw_values if raw_values is Array else []
        var extended: Array = [0, 0, 0, 0, 0]
        for i in range(mini(values.size(), 5)):
            extended[i] = maxi(0, int(values[i]))
        base.stats[key] = extended
    var raw_names: Variant = base.settings.get("names", ["Du","Spieler 2"])
    if not raw_names is Array or raw_names.size() != 2:
        base.settings.names = ["Du", "Spieler 2"]
    else:
        var clean_names: Array = []
        for i in range(2):
            var name: String = str(raw_names[i]).strip_edges().substr(0,24)
            clean_names.append(name if name != "" else ("Du" if i == 0 else "Spieler 2"))
        base.settings.names = clean_names
    return base
static func save_data(data: Dictionary) -> bool:
    var file = FileAccess.open(PATH+".tmp",FileAccess.WRITE)
    if file == null: return false
    file.store_string(JSON.stringify(data))
    file.close()
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH+".tmp"),ProjectSettings.globalize_path(PATH)) == OK
static func valid_game(s: Dictionary) -> bool:
    if not s.get("cells") is Array or s.cells.size() != 54: return false
    if not s.get("owners") is Array or s.owners.size() != 2: return false
    if not int(s.get("turn",0)) in [1,2] or not int(s.get("winner",-1)) in [0,1,2,3]: return false
    for c in s.cells:
        if not (c is float or c is int) or not int(c) in [0,1,2] or c != int(c): return false
    return s.has("swap_enabled") and s.has("swap_pending") and s.has("win_lines")
