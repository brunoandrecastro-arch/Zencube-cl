extends RefCounted
## Progress and encounters for the existing 54-cell cube.

const SAVE_FILE := "user://zencube_zen_campaign_v1.json"
const VERSION := 2
const ART := "res://assets/zen_campaign/"
const POSTER := ART + "zen_campaign_poster_de.webp"
const PROLOGUE := ART + "zen_campaign_prologue.webp"
const FIRST_DEMON := ART + "zen_campaign_first_demon.webp"
const CHAPTER_ART := [
    ART + "chapter_previews/01_zen_garden.webp",
    ART + "chapter_previews/02_bamboo_forest.webp",
    ART + "chapter_previews/03_temple.webp",
    ART + "chapter_previews/04_still_water.webp",
    ART + "chapter_previews/05_above_clouds.webp",
]
const CHAPTER_START := [0, 2, 4, 7, 9]
const CHAPTER_BY_STAGE := [0, 0, 1, 1, 2, 2, 2, 3, 3, 4, 4, 4, 4]
const NIGHT := 6
const LORD := 7
const SLAIN := 8
const SELF := 10
const EPILOGUE := 11
const COMPLETE := 12
const TURN_SECONDS := 22.0
const NIGHT_RESULTS := ["win", "loss", "draw", "timeout"]
const TEXT_FILE := "res://story/zen_campaign.json"
const AI := preload("res://story/ZenCampaignAI.gd")
static var _texts: Dictionary = {}

static func text_for(lang: String, key: String) -> String:
    if _texts.is_empty():
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEXT_FILE))
        if parsed is Dictionary:
            _texts = parsed
    var line: Array = _texts.get(key, [])
    if line.size() != 3:
        push_error("Missing Zen Campaign text: " + key)
        return key
    return str(line[0] if lang == "de" else line[2] if lang == "pt" else line[1])

static func branch_text(lang: String, key: String, night_result: String) -> String:
    return text_for(lang, key + ("_still" if night_result == "win" else "_red"))

static func chapter_for(stage: int) -> int:
    return CHAPTER_BY_STAGE[clampi(stage, 0, COMPLETE)]

static func stage_title(lang: String, stage: int) -> String:
    return text_for(lang, "stage_%d" % stage)

static func stage_art(stage: int) -> String:
    if stage == 0:
        return FIRST_DEMON
    return CHAPTER_ART[chapter_for(stage)]

static func defaults() -> Dictionary:
    var openings: Array = []
    openings.resize(54)
    openings.fill(0)
    return {
        "version": VERSION, "stage": 0, "game": {}, "prologue_seen": false,
        "night_result": "", "seconds_left": TURN_SECONDS, "slain_revealed": false,
        "openings": openings, "average_move_ms": 0, "moves_timed": 0,
    }

static func load_progress() -> Dictionary:
    var progress := defaults()
    if not FileAccess.file_exists(SAVE_FILE):
        return progress
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_FILE))
    if not parsed is Dictionary:
        return progress
    var version := int(parsed.get("version", 0))
    if version not in [1, VERSION]:
        return progress
    var stage := clampi(int(parsed.get("stage", 0)), 0, 2 if version == 1 else COMPLETE)
    var saved_game: Variant = parsed.get("game", {})
    progress.stage = stage
    if stage < COMPLETE and saved_game is Dictionary and SaveManager.valid_game(saved_game):
        # A terminal v1 Chapter 1 save stored stage 2 beside an old board in some builds.
        if version != 1 or stage < 2:
            var board_state: Dictionary = saved_game.duplicate()
            board_state.erase("history")
            board_state.swap_enabled = false
            board_state.swap_pending = false
            board_state.owners = [1, 0] if stage in [LORD, EPILOGUE] else [0, 1]
            board_state.win_lines = []
            progress.game = board_state
    progress.prologue_seen = bool(parsed.get("prologue_seen", stage > 0 or (
        version == 1 and not progress.game.is_empty() and progress.game.cells.count(0) < 54
    )))
    var night_result := str(parsed.get("night_result", ""))
    if night_result in NIGHT_RESULTS:
        progress.night_result = night_result
    progress.seconds_left = clampf(float(parsed.get("seconds_left", TURN_SECONDS)), 0.0, TURN_SECONDS)
    progress.slain_revealed = bool(parsed.get("slain_revealed", false))
    var openings: Variant = parsed.get("openings", [])
    if openings is Array and openings.size() == 54:
        for cell in range(54):
            progress.openings[cell] = maxi(0, int(openings[cell]))
    progress.average_move_ms = clampi(int(parsed.get("average_move_ms", 0)), 0, 5000)
    progress.moves_timed = clampi(int(parsed.get("moves_timed", 0)), 0, 10000)
    return progress

static func save_progress(progress: Dictionary) -> bool:
    var file := FileAccess.open(SAVE_FILE + ".tmp", FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(progress))
    var error := file.get_error()
    file.close()
    if error != OK:
        return false
    return DirAccess.rename_absolute(
        ProjectSettings.globalize_path(SAVE_FILE + ".tmp"),
        ProjectSettings.globalize_path(SAVE_FILE)) == OK

static func can_advance(stage: int, winner: int, player_won: bool) -> bool:
    return winner != 0 and (player_won or stage in [NIGHT, EPILOGUE])

static func bot_delay(stage: int, seed_value: int, average_move_ms: int) -> int:
    if stage == 0:
        return 130 + seed_value % 420
    if stage == SELF:
        return clampi(roundi(average_move_ms * 0.55), 240, 1000)
    return [0, 180, 670, 410, 110, 485, 170, 650, 830, 270][stage]

static func pick_move(cells: Array, stage: int, seed_value: int, player: int = 2,
        last_cell: int = -1, hidden_faces: Array = [], openings: Array = []) -> int:
    return AI.pick_move(cells, stage, seed_value, player, last_cell, hidden_faces, openings)
