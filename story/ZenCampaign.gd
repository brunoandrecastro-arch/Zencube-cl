extends RefCounted
## Zen Campaign – isolated progress and two playable Chapter 1 demon personalities.
## Does not touch Classic stats/ranks, the 4x4 realms, or the Play Store release.
const SAVE_FILE := "user://zencube_zen_campaign_v1.json"
const VERSION := 1

const TEXT := {
    "de": {
        "play": "Zen Campaign · Spielen",
        "title": "ZEN CAMPAIGN",
        "subtitle": "Kapitel 1 · Der erste Stein",
        "start": "Kuze Tadanobu steigt zum Bergtempel auf. Seine Schwerthand zittert. Der Abt reicht ihm einen Besen und zeigt auf einen Steinwürfel.\n\n«Er hat sechs Seiten. Drei kannst du sehen. Setz dich.»",
        "first": "DER SCHRECK · Dämon 1/2",
        "first_intro": "Ein Schatten aus plötzlichen Geräuschen nimmt gegenüber Platz.\n\nDER SCHRECK: «Hast du das gehört?»\n\nDrehe den echten ZenCube und verbinde vier Zeichen über benachbarte Seiten.",
        "first_win": "Der Schatten verneigt sich und setzt sich an den Rand des Gartens.\n\nABT: «Morgen wird die Hand wieder zittern. Setz dich trotzdem.»",
        "first_loss": "DER SCHRECK: «Du hast es auch gehört!»\n\nABT: «Noch einmal.»",
        "second": "DER HUNGRIGE · Boss 2/2",
        "second_intro": "Ein zweiter Dämon kommt mit einer Schale Reis. Er isst nichts davon.\n\nDER HUNGRIGE: «Ein Schwert kaufte elf Tage Reis. Am vierzehnten Tag starb sie.»\n\nEr verfolgt seine eigenen Linien und vergisst oft die Verteidigung.",
        "second_win": "Der Hungrige senkt die Schale. Auch er bleibt sitzen.\n\nKUZE: «Gehen sie irgendwann fort?»\nABT: «Nein. Sie setzen sich nur hin.»",
        "second_loss": "DER HUNGRIGE: «Setz dich. Es ist noch Reis da.»\n\nABT: «Du hast auf seinen Hunger geschaut, nicht auf den Stein. Noch einmal.»",
        "done": "Kapitel 1 abgeschlossen! Zwei Dämonen sitzen jetzt still im Garten.\n\nDies ist die erste spielbare Kampagnen-Etappe. Die weiteren Kapitel folgen später.",
        "begin": "Kampf beginnen",
        "again": "Erneut versuchen",
        "continue": "Zum nächsten Dämon",
        "chronicles": "Zurück zu Zen Chronicles",
        "leave": "Kampagne verlassen",
        "resume": "Kampf fortsetzen",
        "chapter_done": "Kapitel abgeschlossen",
        "result_win": "Du hast den Dämon besiegt",
        "result_loss": "Der Dämon gewinnt",
        "result_draw": "Stille · Unentschieden",
        "not_finished": "Der Weg ist noch nicht zu Ende."
    },
    "en": {
        "play": "Zen Campaign · Play",
        "title": "ZEN CAMPAIGN",
        "subtitle": "Chapter 1 · The First Stone",
        "start": "Kuze Tadanobu climbs to a mountain temple. His sword hand shakes. The abbot hands him a broom, then points to a stone cube.\n\n«It has six sides. You can see three. Sit.»",
        "first": "THE STARTLE · Demon 1/2",
        "first_intro": "A shadow made of sudden noises sits opposite him.\n\nTHE STARTLE: «Did you hear that?»\n\nTurn the real ZenCube and connect four marks across adjacent sides.",
        "first_win": "The shadow bows and takes a seat at the garden's edge.\n\nABBOT: «The hand will jump again tomorrow. Sit anyway.»",
        "first_loss": "THE STARTLE: «You heard it too!»\n\nABBOT: «Again.»",
        "second": "THE HUNGRY ONE · Boss 2/2",
        "second_intro": "A second demon arrives holding a bowl of rice he never eats.\n\nTHE HUNGRY ONE: «One sword bought eleven days of rice. She died on the fourteenth.»\n\nHe chases his own lines and often forgets to defend.",
        "second_win": "The Hungry One lowers his bowl and sits down too.\n\nKUZE: «Do they ever go away?»\nABBOT: «No. They sit down. That is all.»",
        "second_loss": "THE HUNGRY ONE: «Sit. There is rice left.»\n\nABBOT: «You watched his hunger, not the stone. Again.»",
        "done": "Chapter 1 complete! Two demons now sit quietly in the garden.\n\nThis is the first playable campaign milestone. More chapters will follow.",
        "begin": "Begin battle",
        "again": "Try again",
        "continue": "Face the next demon",
        "chronicles": "Back to Zen Chronicles",
        "leave": "Leave campaign",
        "resume": "Resume battle",
        "chapter_done": "Chapter complete",
        "result_win": "You defeated the demon",
        "result_loss": "The demon wins",
        "result_draw": "Stillness · Draw",
        "not_finished": "The path is not over."
    },
    "pt": {
        "play": "Zen Campaign · Jogar",
        "title": "ZEN CAMPAIGN",
        "subtitle": "Capítulo 1 · A Primeira Pedra",
        "start": "Kuze Tadanobu sobe até um templo na montanha. A mão que segura a espada treme. O abade entrega-lhe uma vassoura e aponta para um cubo de pedra.\n\n«Tem seis faces. Só consegues ver três. Senta-te.»",
        "first": "O SOBRESSALTO · Demónio 1/2",
        "first_intro": "Uma sombra feita de ruídos inesperados senta-se diante dele.\n\nSOBRESSALTO: «Ouviste isso?»\n\nRoda o ZenCube e liga quatro símbolos através de faces adjacentes.",
        "first_win": "A sombra inclina-se e senta-se na borda do jardim.\n\nABADE: «A mão voltará a tremer amanhã. Senta-te na mesma.»",
        "first_loss": "SOBRESSALTO: «Também ouviste!»\n\nABADE: «Outra vez.»",
        "second": "O FAMINTO · Chefe 2/2",
        "second_intro": "Chega um segundo demónio com uma tigela de arroz que nunca come.\n\nFAMINTO: «Uma espada comprou onze dias de arroz. Ela morreu no décimo quarto.»\n\nProcura as suas linhas e esquece-se muitas vezes de defender.",
        "second_win": "O Faminto baixa a tigela e senta-se também.\n\nKUZE: «Alguma vez desaparecem?»\nABADE: «Não. Apenas se sentam.»",
        "second_loss": "FAMINTO: «Senta-te. Ainda há arroz.»\n\nABADE: «Olhaste para a fome dele, não para a pedra. Outra vez.»",
        "done": "Capítulo 1 concluído! Dois demónios estão agora sentados em silêncio no jardim.\n\nEsta é a primeira etapa jogável da campanha. Os próximos capítulos virão depois.",
        "begin": "Começar combate",
        "again": "Tentar novamente",
        "continue": "Enfrentar o próximo demónio",
        "chronicles": "Voltar às Zen Chronicles",
        "leave": "Sair da campanha",
        "resume": "Continuar combate",
        "chapter_done": "Capítulo concluído",
        "result_win": "Venceste o demónio",
        "result_loss": "O demónio venceu",
        "result_draw": "Quietude · Empate",
        "not_finished": "O caminho ainda não terminou."
    }
}

static func tr(lang: String, key: String) -> String:
    var dictionary: Dictionary = TEXT.get(lang, TEXT["en"])
    return str(dictionary.get(key, TEXT["en"].get(key, key)))

static func load_progress() -> Dictionary:
    if not FileAccess.file_exists(SAVE_FILE):
        return {"version": VERSION, "stage": 0, "game": {}}
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_FILE))
    if not parsed is Dictionary or int(parsed.get("version", -1)) != VERSION:
        return {"version": VERSION, "stage": 0, "game": {}}
    return {"version": VERSION,
        "stage": clampi(int(parsed.get("stage", 0)), 0, 2),
        "game": parsed.get("game", {}) if parsed.get("game", {}) is Dictionary else {}}

static func save_progress(stage: int, game: Dictionary) -> bool:
    var payload: Dictionary = {"version": VERSION, "stage": clampi(stage, 0, 2), "game": game}
    var file := FileAccess.open(SAVE_FILE + ".tmp", FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(payload))
    file.close()
    return DirAccess.rename_absolute(
        ProjectSettings.globalize_path(SAVE_FILE + ".tmp"),
        ProjectSettings.globalize_path(SAVE_FILE)) == OK

static func pick_move(cells_in: Array, stage: int, seed_value: int) -> int:
    # Pure data calculation: safe to call from GameController's AI worker thread.
    var random := RandomNumberGenerator.new()
    random.seed = seed_value
    var cells: Array = cells_in.duplicate()
    var available: Array = []
    for i in range(cells.size()):
        if int(cells[i]) == 0:
            available.append(i)
    if available.is_empty():
        return -1
    if stage == 0:
        # The Startle jumps between faces and sometimes forgets its own lines.
        if random.randf() < 0.79:
            return int(available[random.randi_range(0, available.size() - 1)])
    var engine := RulesEngine.new()
    var best: Array = []
    var best_score: float = -INF
    for cell in available:
        cells[cell] = 2
        var score: float = random.randf_range(-0.35, 0.35)
        if not engine.victories(cells, 2).is_empty():
            score += 100000.0
        for line in engine.lines:
            if not line.has(cell):
                continue
            var own: int = 0
            var other: int = 0
            for position in line:
                if cells[position] == 2:
                    own += 1
                elif cells[position] == 1:
                    other += 1
            if other == 0:
                score += [0.0, 1.0, 4.0, 26.0, 500.0][own]
        cells[cell] = 0
        if score > best_score + 0.00001:
            best_score = score
            best = [cell]
        elif absf(score - best_score) < 0.00001:
            best.append(cell)
    if best.is_empty():
        return int(available[0])
    return int(best[random.randi_range(0, best.size() - 1)])
