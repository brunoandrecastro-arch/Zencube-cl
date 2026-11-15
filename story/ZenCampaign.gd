extends RefCounted

const SAVE_FILE := "user://zencube_zen_campaign_v1.json"
const VERSION := 3
const TEXT_FILE := "res://story/zen_campaign.json"
const ART := "res://assets/zen_campaign/"
const POSTER := ART + "zen_campaign_poster_de.webp"
const PROLOGUE_ART := ART + "zen_campaign_prologue.webp"
const FIRST_DEMON_ART := ART + "zen_campaign_first_demon.webp"
const CHAPTER_ART: Array[String] = [
    ART + "chapter_previews/01_zen_garden.webp",
    ART + "chapter_previews/02_bamboo_forest.webp",
    ART + "chapter_previews/03_temple.webp",
    ART + "chapter_previews/04_still_water.webp",
    ART + "chapter_previews/05_above_clouds.webp",
]
const NIGHT := 6
const LORD := 7
const SLAIN := 8
const DAWN := 9
const SELF := 10
const EPILOGUE := 11
const NIGHT_SECONDS := 25.0
const CHAPTER_FOR_STAGE := [0, 0, 1, 1, 2, 2, 2, 3, 3, 4, 4, 4]
const WINS_FOR_STAGE := [1, 1, 4, 1, 6, 1, 1, 2, 1, 2, 5, 1]
const NAME_KEYS := [
    "startle", "hungry", "frozen", "double", "red", "name", "night",
    "lord", "slain", "dawn", "self", "epilogue",
]
const AI := preload("res://story/ZenCampaignAI.gd")
static var _texts: Dictionary = {}

static func text_for(lang: String, key: String) -> String:
    if _texts.is_empty():
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEXT_FILE))
        if parsed is Dictionary:
            _texts = parsed
    var fallback: Dictionary = _texts.get("en", {})
    var locale: Dictionary = _texts.get(lang, fallback)
    return str(locale.get(key, fallback.get(key, key)))

static func chapter_name(lang: String, chapter: int) -> String:
    return text_for(lang, "chapter_%d" % chapter)

static func demon_name(lang: String, stage: int) -> String:
    return text_for(lang, NAME_KEYS[stage])

static func artwork(path: String, height: float, region := Rect2()) -> TextureRect:
    var picture := TextureRect.new()
    var texture := load(path) as Texture2D
    if region.has_area() and texture != null:
        var cropped := AtlasTexture.new()
        cropped.atlas = texture
        cropped.region = region
        cropped.filter_clip = true
        texture = cropped
    picture.name = path.get_file().get_basename()
    picture.texture = texture
    picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    picture.custom_minimum_size.y = height
    picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return picture

static func new_progress() -> Dictionary:
    return {
        "version": VERSION,
        "stage": 0,
        "wins": 0,
        "game": {},
        "prologue_seen": false,
        "introduced": false,
        "pending": "",
        "revealed": 0,
        "night": "",
        "seconds_left": NIGHT_SECONDS,
        "complete": false,
        "openings": {},
        "tempo_total": 0,
        "tempo_count": 0,
    }

static func load_progress() -> Dictionary:
    var progress := new_progress()
    if not FileAccess.file_exists(SAVE_FILE):
        return progress
    var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_FILE))
    if not saved is Dictionary:
        return progress
    var version := int(saved.get("version", 0))
    if version not in [1, 2, VERSION]:
        return progress
    if version == 1:
        # The draft ended at stage 2. Continue those saves at the Bamboo Forest.
        progress.stage = clampi(int(saved.get("stage", 0)), 0, 2)
        if progress.stage < 2:
            progress.game = saved.get("game", {})
    elif version == 2:
        _migrate_encounter_save(progress, saved)
    else:
        for key in progress:
            if saved.has(key):
                progress[key] = saved[key]
        progress.stage = clampi(int(progress.stage), 0, EPILOGUE)
        progress.wins = clampi(int(progress.wins), 0, WINS_FOR_STAGE[progress.stage])
        progress.revealed = clampi(int(progress.revealed), 0, 3)
        progress.seconds_left = clampf(float(progress.seconds_left), 0.0, NIGHT_SECONDS)
        if not progress.pending in ["", "false_ending", "false_accept", "false_refuse", "epilogue"]:
            progress.pending = ""
        if not progress.night in ["", "still", "red"]:
            progress.night = ""
        if not progress.openings is Dictionary:
            progress.openings = {}
    _normalize_game(progress)
    if version == 1:
        progress.prologue_seen = progress.stage > 0 or (
            not progress.game.is_empty() and progress.game.cells.count(0) < 54)
        if not progress.prologue_seen:
            progress.game = {}
        progress.introduced = not progress.game.is_empty()
    return progress

static func _migrate_encounter_save(progress: Dictionary, saved: Dictionary) -> void:
    # The first full campaign build asked for one win per encounter. Its stage,
    # unfinished match and already chosen Night branch remain valid.
    var old_stage := int(saved.get("stage", 0))
    progress.stage = clampi(old_stage, 0, EPILOGUE)
    progress.game = saved.get("game", {}) if old_stage <= EPILOGUE else {}
    progress.prologue_seen = bool(saved.get("prologue_seen", old_stage > 0))
    progress.introduced = progress.game is Dictionary and not progress.game.is_empty()
    progress.revealed = int(bool(saved.get("slain_revealed", false))) if old_stage == SLAIN else 0
    progress.complete = old_stage >= EPILOGUE
    if old_stage > EPILOGUE:
        progress.pending = "epilogue"
    var old_result := str(saved.get("night_result", ""))
    if old_result != "":
        progress.night = "still" if old_result == "win" else "red"
    progress.seconds_left = clampf(float(saved.get("seconds_left", NIGHT_SECONDS)), 0.0, NIGHT_SECONDS)
    var old_openings: Variant = saved.get("openings", [])
    if old_openings is Array and old_openings.size() == 54:
        for cell in range(54):
            if int(old_openings[cell]) > 0:
                progress.openings[str(cell)] = int(old_openings[cell])
    progress.tempo_count = clampi(int(saved.get("moves_timed", 0)), 0, 10000)
    progress.tempo_total = progress.tempo_count * clampi(int(saved.get("average_move_ms", 0)), 0, 8000)

static func _normalize_game(progress: Dictionary) -> void:
    var game: Variant = progress.game
    if not game is Dictionary or not SaveManager.valid_game(game):
        progress.game = {}
        return
    game.starter_owner = clampi(int(game.get("starter_owner", starting_owner(int(progress.stage)))), 0, 1)
    game.owners = [game.starter_owner, 1 - game.starter_owner]
    game.swap_enabled = false
    game.swap_pending = false
    game.result_recorded = false
    game.win_lines = []
    if not game.get("history") is Array:
        game.history = []

static func save_progress(progress: Dictionary) -> bool:
    var temp := SAVE_FILE + ".tmp"
    var file := FileAccess.open(temp, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(progress))
    file.flush()
    var error := file.get_error()
    file.close()
    if error != OK:
        return false
    return DirAccess.rename_absolute(
        ProjectSettings.globalize_path(temp),
        ProjectSettings.globalize_path(SAVE_FILE)
    ) == OK

static func starting_owner(stage: int) -> int:
    return int(stage in [LORD, SELF, EPILOGUE])

static func victory_by_player(board: BoardModel) -> bool:
    return board.winner in [1, 2] and board.owners[board.winner - 1] == 0

static func bot_delay(stage: int, moves: int, progress: Dictionary) -> int:
    if stage == 0:
        return [140, 720, 260][moves % 3]
    if stage == SELF and int(progress.tempo_count) > 0:
        return clampi(roundi(float(progress.tempo_total) / int(progress.tempo_count)), 180, 1400)
    return [220, 280, 780, 520, 180, 600, 180, 640, 880, 300, 520][stage]

static func pick_move(cells: Array, stage: int, seed_value: int, context := {}) -> int:
    return AI.pick_move(cells, stage, seed_value, context)
