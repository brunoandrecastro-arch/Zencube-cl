extends RefCounted
## Navigation follows the existing Act gates. No new progression or save file.
const ActOne = preload("res://story/ZenActOne.gd")
const ActTwo = preload("res://story/ZenActTwo.gd")
const ActThree = preload("res://story/ZenActThree.gd")
const ActFour = preload("res://story/ZenActFour.gd")
const Locale = preload("res://core/ZenLocalization.gd")
const MODELS: Array[Script] = [ActOne, ActTwo, ActThree, ActFour]
const TITLES: Array[String] = ["ACT I · The Roots of Peace", "ACT II · The Art of Balance", "ACT III · The Beautiful Imperfection", "ACT IV · The Day Everything Broke"]

static func text(source: String, language: String) -> String:
    return Locale.translate(source, language)

static func gate_count(data: Dictionary, act: int) -> int:
    match act:
        2: return ActTwo.easy_wins(data)
        3: return ActThree.medium_wins(data)
        4: return ActFour.hard_wins(data)
    return 0

static func gate_target(act: int) -> int:
    return [0, 3, 5, 7][clampi(act - 1, 0, 3)]

static func gate_task(act: int, language: String) -> String:
    if act < 2 or act > 4:
        return text("Von Anfang an verfügbar", language)
    # Earn the next World in the preceding, already accessible World.
    # E.g. Easy wins in Zen Garden lead to Act II in Bamboo Path.
    var level: int = act - 2
    return text("Gewinne %d Partien auf der Stufe %s in %s.", language) % [
        gate_target(act), text(ZenAscension.LEVELS[level], language),
        text(ZenAscension.WORLDS[level], language)]

static func gate_hint(data: Dictionary, act: int, language: String) -> String:
    var hint: String = text(ZenAscension.WORLDS[clampi(act - 1, 0, 3)], language)
    if act == 1:
        return hint
    hint += "\n" + gate_task(act, language)
    hint += "\n" + text("Fortschritt: %d/%d", language) % [gate_count(data, act), gate_target(act)]
    if not bool(MODELS[act - 2].load_progress().complete):
        hint += "\n" + text("Schließe zuerst Akt %s ab.", language) % ["I", "II", "III"][act - 2]
    return hint

static func next_step(data: Dictionary) -> Dictionary:
    for index in range(4):
        var model: Script = MODELS[index]
        var progress: Dictionary = model.load_progress()
        if bool(progress.complete):
            continue
        var act: int = index + 1
        var started: bool = index > 0 or int(progress.page) > 1 or bool(progress.reached)
        if act == 1 or model.unlocked(data):
            return {"kind": "story", "act": act, "world": index, "started": started,
                "current": int(progress.page), "target": 12}
        return {"kind": "matches", "act": act, "world": index - 1, "level": index - 1,
            "started": true, "current": gate_count(data, act), "target": gate_target(act)}
    return {"kind": "realms", "act": 4, "world": 3, "started": true, "current": 4, "target": 4}

static func step_caption(step: Dictionary, language: String) -> String:
    if str(step.kind) == "matches":
        return gate_task(int(step.act), language)
    if str(step.kind) == "realms":
        return text("Deine Reise geht weiter.", language)
    return TITLES[int(step.act) - 1]

static func progress_caption(step: Dictionary, language: String) -> String:
    if str(step.kind) == "matches":
        return text("Fortschritt: %d/%d", language) % [int(step.current), int(step.target)]
    if str(step.kind) == "story":
        return text("Seite %d von %d", language) % [int(step.current), int(step.target)]
    return ""
