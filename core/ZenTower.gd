extends RefCounted

const ASSETS = "res://data/zen_tower/assets.json"
const EXPANSION = "res://data/zen_tower/expansions/stages_061_100.json"
const LORE = "res://data/zen_tower/lore_en.json"
const MAX_LIVES = 5
const UPDATE_VERSION = 2
const Grid = preload("res://core/ZenTowerGrid.gd")
const TowerBoard = preload("res://core/ZenTowerBoard.gd")
const TowerRules = preload("res://core/ZenTowerRules.gd")
const FourBot = preload("res://core/ZenAscendRealmBot.gd")
static var _catalog: Dictionary = {}

static func defaults() -> Dictionary:
    return {
        "active": false, "floor": 1, "lives": MAX_LIVES,
        "record": 0, "cards": [], "runs": 0, "attempt": 0,
        "game": {}, "level": 0, "finished": {}, "series": {}
    }

static func ensure(data: Dictionary) -> Dictionary:
    if not data.get("tower") is Dictionary:
        data["tower"] = defaults()
    var state: Dictionary = data["tower"]
    state.merge(defaults(), false)
    if not state.get("series") is Dictionary:
        state.series = {}
    if not state.get("finished") is Dictionary:
        state.finished = {}
    return state

static func manifest() -> Dictionary:
    if not _catalog.is_empty():
        return _catalog
    var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ASSETS))
    if not raw is Dictionary:
        return {}
    var info: Dictionary = raw
    if FileAccess.file_exists(EXPANSION):
        var extra: Variant = JSON.parse_string(FileAccess.get_file_as_string(EXPANSION))
        if extra is Dictionary:
            for key in ["sections", "guardians", "images"]:
                var target: Array = info.get(key, [])
                var additions: Array = extra.get(key, [])
                for entry in additions:
                    var identity: String = str(entry.get("path", "")) if key == "images" else str(entry.get("id", ""))
                    var present: bool = false
                    for existing in target:
                        var old_id: String = str(existing.get("path", "")) if key == "images" else str(existing.get("id", ""))
                        if identity == old_id:
                            present = true
                            break
                    if not present:
                        target.append(entry)
                info[key] = target
    info["image_count"] = (info.get("images", []) as Array).size()
    _catalog = info
    return _catalog

static func cycle_floor(stage: int) -> int:
    var count: int = 1
    for section in manifest().get("sections", []):
        count = maxi(count, int(section.get("first_cycle_boss_floor", 1)))
    return (maxi(1, stage) - 1) % count + 1

static func section_index(stage: int) -> int:
    var local_floor: int = cycle_floor(stage)
    var sections: Array = manifest().get("sections", [])
    for i in range(sections.size()):
        var section: Dictionary = sections[i]
        var first: int = int(section.get("first_cycle_normal_floors", {}).get("from", 1))
        var last: int = int(section.get("first_cycle_boss_floor", first))
        if local_floor >= first and local_floor <= last:
            return i
    return 0

static func is_boss(stage: int) -> bool:
    if stage < 1:
        return false
    var sections: Array = manifest().get("sections", [])
    if sections.is_empty():
        return false
    return cycle_floor(stage) == int(sections[section_index(stage)].get("first_cycle_boss_floor", -1))

static func floor_info(stage: int) -> Dictionary:
    var info: Dictionary = manifest()
    var sections: Array = info.get("sections", [])
    if sections.is_empty():
        return {}
    var section: Dictionary = sections[section_index(stage)]
    var guardian: Dictionary = {}
    for candidate in info.get("guardians", []):
        if str(candidate.get("id", "")) == str(section.get("guardian_id", "")):
            guardian = candidate
            break
    if guardian.is_empty():
        return {}
    var boss: bool = is_boss(stage)
    return {
        "section": section, "guardian": guardian, "boss": boss,
        "background": section["boss_arena"] if boss else section["background"]
    }

static func board_size(stage: int) -> int:
    return 4 if stage >= 101 else 3

static func new_board(side: int) -> BoardModel:
    return TowerBoard.new(side)

static func make_rules(side: int) -> RulesEngine:
    return TowerRules.new(side)

static func valid_game(snapshot: Dictionary, expected_cells: int = 0) -> bool:
    if not snapshot.get("cells") is Array:
        return false
    var count: int = snapshot.cells.size()
    if count not in [54, 96] or (expected_cells > 0 and count != expected_cells):
        return false
    if not snapshot.get("owners") is Array or snapshot.owners.size() != 2:
        return false
    if not int(snapshot.get("turn", 0)) in [1, 2] or not int(snapshot.get("winner", -1)) in [0, 1, 2, 3]:
        return false
    if not snapshot.get("win_lines") is Array:
        return false
    for cell in snapshot.cells:
        if not (cell is int or cell is float) or cell != int(cell) or not int(cell) in [0, 1, 2]:
            return false
    for line in snapshot.win_lines:
        if not line is Array:
            return false
        for index in line:
            if not (index is int or index is float) or index != int(index) or int(index) < 0 or int(index) >= count:
                return false
    return snapshot.has("swap_enabled") and snapshot.has("swap_pending")

static func difficulty(stage: int, roll: float) -> int:
    stage = maxi(1, stage)

    if is_boss(stage):
        if stage <= 45: return 1
        if stage <= 200: return 2
        return 3

    if stage <= 15: return 0
    if stage <= 30: return 1 if roll < 0.25 else 0
    if stage <= 45: return 1 if roll < 0.70 else 0
    if stage <= 75: return 1
    if stage <= 100: return 2 if roll < 0.30 else 1

    # Softer introduction to the larger 4x4 board.
    if stage <= 130: return 1 if roll < 0.65 else 0
    if stage <= 200: return 2 if roll < 0.30 else 1
    return 2

static func budget(stage: int, level: int) -> int:
    var value: int = 45 + level * 30 + mini(55, stage)
    if is_boss(stage):
        value += 30
    return mini(250, value)

static func choose_move(cells: Array, level: int, time_budget: int, seed_value: int) -> int:
    if cells.size() == 96:
        return FourBot.next_move(cells, Grid.generate_lines(), 2, level, false)
    return AIEngine.new(seed_value).choose(cells, 2, level, time_budget)

static func new_run(data: Dictionary) -> bool:
    var state: Dictionary = ensure(data)
    if bool(state.active):
        return false
    state.active = true
    state.floor = 1
    state.lives = MAX_LIVES
    state.runs = int(state.runs) + 1
    state.attempt = 0
    state.game = {}
    state.finished = {}
    state.series = {}
    return true

static func checkpoint_floor(data: Dictionary) -> int:
    var state: Dictionary = ensure(data)
    return 1 + floori(float(maxi(0, int(state.record))) / 50.0) * 50

static func restart_run(data: Dictionary, stage: int) -> bool:
    var state: Dictionary = ensure(data)
    if stage != 1 and stage != checkpoint_floor(data): return false
    state.active = false
    if not new_run(data): return false
    state.floor = stage
    return begin_floor(data)

static func _new_series(stage: int) -> Dictionary:
    return {"floor": stage, "player": 0, "guardian": 0, "round": 1, "complete": false, "intro_seen": false}

static func begin_floor(data: Dictionary) -> bool:
    var state: Dictionary = ensure(data)
    if not bool(state.active) or not state.finished.is_empty():
        return false
    var stage: int = int(state.floor)
    if is_boss(stage):
        if int(state.series.get("floor", -1)) != stage or bool(state.series.get("complete", false)):
            state.series = _new_series(stage)
    else:
        state.series = {}
    var side: int = board_size(stage)
    var count: int = 6 * side * side
    if not state.game.is_empty():
        if valid_game(state.game, count):
            return false
        # An unfinished legacy 3x3 board above 100 starts this floor on 4x4.
        state.game = {}
    if is_boss(stage):
        state.series["round"] = mini(3, int(state.series.player) + int(state.series.guardian) + 1)
    var board: BoardModel = new_board(side)
    board.turn = 1 if int(state.attempt) % 2 == 0 else 2
    board.starter_owner = board.turn - 1
    state.attempt = int(state.attempt) + 1
    state.level = difficulty(stage, randf())
    state.game = board.snapshot()
    return true

static func play(data: Dictionary, cell: int, player: int) -> bool:
    var state: Dictionary = ensure(data)
    var side: int = board_size(int(state.floor))
    if not bool(state.active) or not valid_game(state.game, 6 * side * side):
        return false
    var board: BoardModel = new_board(side)
    board.restore(state.game)
    if board.turn != player:
        return false
    var rules: RulesEngine = make_rules(side)
    if not rules.play(board, cell):
        return false
    state.game = board.snapshot()
    return true

static func settle(data: Dictionary) -> Dictionary:
    var state: Dictionary = ensure(data)
    var stage: int = int(state.floor)
    var side: int = board_size(stage)
    if not bool(state.active) or not state.finished.is_empty() or not valid_game(state.game, 6 * side * side):
        return {}
    var winner: int = int(state.game.winner)
    if winner not in [1, 2, 3]:
        return {}
    var boss: bool = is_boss(stage)
    var series_complete: bool = true
    var player_wins: int = 0
    var guardian_wins: int = 0
    if boss:
        if int(state.series.get("floor", -1)) != stage:
            state.series = _new_series(stage)
        if bool(state.series.get("complete", false)):
            return {}
        if winner == 1:
            state.series.player = int(state.series.player) + 1
        elif winner == 2:
            state.series.guardian = int(state.series.guardian) + 1
        player_wins = int(state.series.player)
        guardian_wins = int(state.series.guardian)
        series_complete = player_wins >= 2 or guardian_wins >= 2
        state.series.complete = series_complete
    var floor_complete: bool = winner == 1 and (not boss or series_complete)
    var defeat: bool = winner == 2 and (not boss or series_complete)
    var reward: int = 0
    var life_bonus: int = 0
    var unlocked: String = ""
    if floor_complete:
        state.record = maxi(int(state.record), stage)
        reward = 3 + int(state.level) * 2
        if boss:
            reward += 15
            life_bonus = 3
            state.lives = int(state.lives) + life_bonus
            var info: Dictionary = floor_info(stage)
            if not info.is_empty():
                var card_id: String = str(info.guardian.id)
                if not state.cards.has(card_id):
                    state.cards.append(card_id)
                    unlocked = card_id
        ZenCollection.ensure(data)
        data.economy.leaves = mini(100000000, int(data.economy.leaves) + reward)
        state.floor = stage + 1
    elif defeat:
        state.lives = maxi(0, int(state.lives) - 1)
        if int(state.lives) == 0:
            state.active = false
    state.game = {}
    return {
        "winner": winner, "completed_floor": stage, "next_floor": state.floor,
        "lives": state.lives, "record": state.record, "reward": reward,
        "life_bonus": life_bonus, "unlocked_card": unlocked,
        "game_over": not bool(state.active), "boss": boss,
        "series_complete": series_complete, "floor_complete": floor_complete,
        "player_wins": player_wins, "guardian_wins": guardian_wins,
        "round": int(state.series.get("round", 1))
    }
