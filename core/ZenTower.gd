extends RefCounted

const ASSETS = "res://data/zen_tower/assets.json"
const LORE = "res://data/zen_tower/lore_en.json"
const MAX_LIVES = 3 # Start lives for a new run

static func defaults() -> Dictionary:
    return {
        "active": false,
        "floor": 1,
        "lives": MAX_LIVES,
        "record": 0,
        "cards": [],
        "runs": 0,
        "attempt": 0,
        "game": {},
        "level": 0
    }

static func ensure(data: Dictionary) -> Dictionary:
    if not data.get("tower") is Dictionary:
        data["tower"] = defaults()
    var state: Dictionary = data["tower"]
    state.merge(defaults(), false)
    return state

static func section_index(stage: int) -> int:
    return floori(float(maxi(1, stage)-1)/15.0) % 4

static func is_boss(stage: int) -> bool:
    return stage > 0 and stage % 15 == 0

static func manifest() -> Dictionary:
    var raw: Variant = JSON.parse_string(
        FileAccess.get_file_as_string(ASSETS))
    return raw if raw is Dictionary else {}

static func floor_info(stage: int) -> Dictionary:
    var info := manifest()
    var sections: Array = info.get("sections", [])
    var guardians: Array = info.get("guardians", [])
    var index := section_index(stage)
    if sections.size() != 4 or guardians.size() != 4:
        return {}
    var section: Dictionary = sections[index]
    var guardian: Dictionary = guardians[index]
    return {
        "section": section,
        "guardian": guardian,
        "boss": is_boss(stage),
        "background": section["boss_arena"] if is_boss(stage) else section["background"]
    }

static func difficulty(stage: int, roll: float) -> int:
    var group := floori(float(maxi(1,stage)-1)/15.0)
    var base := mini(3, group)
    if is_boss(stage):
        return mini(4, base+2)
    var position := (maxi(1,stage)-1) % 15
    var chance := float(position)/14.0
    return mini(4, base+1) if roll < chance else base

static func budget(stage: int, level: int) -> int:
    var value := 45 + level*30 + mini(55,stage)
    if is_boss(stage):
        value += 30
    return mini(250,value)

static func new_run(data: Dictionary) -> bool:
    var state := ensure(data)
    if bool(state.active):
        return false
    state.active = true
    state.floor = 1
    state.lives = MAX_LIVES
    state.runs = int(state.runs)+1
    state.attempt = 0
    state.game = {}
    return true

static func begin_floor(data: Dictionary) -> bool:
    var state := ensure(data)
    if not bool(state.active):
        return false
    if not state.game.is_empty():
        return false

    var board := BoardModel.new()
    board.swap_enabled = false
    board.swap_pending = false
    board.turn = 1 if int(state.attempt)%2 == 0 else 2
    board.starter_owner = board.turn-1

    state.attempt = int(state.attempt)+1
    state.level = difficulty(int(state.floor),randf())
    state.game = board.snapshot()
    return true

static func play(data: Dictionary, cell: int, player: int) -> bool:
    var state := ensure(data)
    if not bool(state.active):
        return false
    if not SaveManager.valid_game(state.game):
        return false
    var board := BoardModel.new()
    board.restore(state.game)
    if board.turn != player:
        return false
    var rules := RulesEngine.new()
    if not rules.play(board,cell):
        return false
    state.game = board.snapshot()
    return true

static func settle(data: Dictionary) -> Dictionary:
    var state := ensure(data)
    if not bool(state.active):
        return {}
    if not SaveManager.valid_game(state.game):
        return {}

    var winner := int(state.game.winner)
    if not winner in [1,2,3]:
        return {}

    var stage := int(state.floor)
    var reward := 0
    var unlocked := ""
    var life_bonus := 0

    if winner == 1:
        state.record = maxi(int(state.record),stage)
        reward = 3 + int(state.level)*2

        if is_boss(stage):
            reward += 15
            life_bonus = 3
            state.lives = int(state.lives) + life_bonus
            var info := floor_info(stage)
            if not info.is_empty():
                var card_id: String = info.guardian.id
                if not state.cards.has(card_id):
                    state.cards.append(card_id)
                    unlocked = card_id

        ZenCollection.ensure(data)
        data.economy.leaves = mini(
            100000000,int(data.economy.leaves)+reward)
        state.floor = stage+1

    elif winner == 2:
        state.lives = maxi(0,int(state.lives)-1)
        if int(state.lives) == 0:
            state.active = false

    state.game = {}

    return {
        "winner": winner,
        "completed_floor": stage,
        "next_floor": state.floor,
        "lives": state.lives,
        "record": state.record,
        "reward": reward,
        "life_bonus": life_bonus,
        "unlocked_card": unlocked,
        "game_over": not bool(state.active)
    }
