extends RefCounted
## Realm Chronicles is an *additional* 4x4 story. Never edits normal Ascend
## ranks, challenges, economy, equipped shop skins or the existing 3x3 campaign.
const SAVE := "user://zencube_realm_chronicles_v1.json"
const VERSION := 1
const BOSS_IDS: Array[String] = [
    "mist_guardian", "mirror_novice", "veil_monk",
    "ash_runner", "banner_guardian", "ember_high_priest"
]
const BOSS_ART: Array[String] = [
    "res://assets/realm_chronicles/boss_mist_guardian.svg",
    "res://assets/realm_chronicles/boss_mirror_novice.svg",
    "res://assets/realm_chronicles/boss_veil_monk.svg",
    "res://assets/realm_chronicles/boss_ash_runner.svg",
    "res://assets/realm_chronicles/boss_banner_guardian.svg",
    "res://assets/realm_chronicles/boss_ember_high_priest.svg"
]
const CHAPTER_ART: Array[String] = [
    "res://assets/realms/shadow_realm.webp",
    "res://assets/realms/ember_temple.webp",
    "res://assets/realms/celestial_realm.webp",
    "res://assets/realms/satori_realm.webp"
]
const LOCALE: Dictionary = {
    "de": {
        "menu": "Zen Ascend · Realm Chronicles",
        "intro": "Eine zweite Reise beginnt. Der Stein ist größer, die Wege sind fremd. Kuze betritt vier Reiche – doch erst die ersten beiden Pfade sind bereit.",
        "shadow": "Kapitel 1 · Shadow Realm",
        "ember": "Kapitel 2 · Ember Temple",
        "celestial": "Kapitel 3 · Celestial Realm",
        "satori": "Kapitel 4 · Satori Realm",
        "shadow_sub": "The Whispering Veil · Zweifel und Geduld",
        "ember_sub": "The Trial of Flame · Zorn und Disziplin",
        "celestial_sub": "The Bridge Above Clouds · In Vorbereitung",
        "satori_sub": "The Summit of Awakening · In Vorbereitung",
        "continue": "Kampf beginnen / fortsetzen",
        "back": "Zurück",
        "leave": "Zurück zum Hauptspiel",
        "retry": "Erneut kämpfen",
        "next": "Weiter zum nächsten Dämon",
        "completed": "Geschafft",
        "current": "Aktuell",
        "locked": "Gesperrt",
        "coming": "Folgt in einem späteren Update",
        "gate": "Der Ember Temple öffnet sich nach dem Sieg über den Schleiermönch UND allen 8 Shadow-Realm-Challenges.",
        "gate_mode": "Zen Ascend muss zuerst über Zen-Meister oder den Shop freigeschaltet werden.",
        "done": "Die Glut wird still. Kuze hat den Shadow Realm und den Ember Temple durchquert. Die Himmelsbrücke wartet auf eine kommende Geschichte.",
        "win": "Der Dämon verneigt sich.",
        "loss": "Der Dämon bleibt sitzen.",
        "draw": "Keiner weicht. Stille.",
        "chapter1_end": "Der Schleiermönch legt seine Hand auf den Stein. Das Tor öffnet sich, als Kuze nicht mehr versucht, den Nebel zu vertreiben. Hinter dem Schatten lodert der ferne Ember Temple.",
        "chapter2_end": "Die Flammen legen sich. Kuze senkt den Blick. »Mein Zorn war laut. Die Entscheidung war meine.« Der Hohepriester weicht zurück. Über dem Tempel erscheint eine Brücke aus Wolken.",
        "boss_0": "Nebelwächter",
        "boss_1": "Spiegel-Novize",
        "boss_2": "Schleiermönch",
        "boss_3": "Aschenläufer",
        "boss_4": "Bannerhüter",
        "boss_5": "Hohepriester der Glut",
        "intro_0": "Zwischen Bambusstämmen erhebt sich eine Gestalt aus mondblauem Nebel. »Du greifst an, bevor du siehst«, sagt der Nebelwächter. »Lerne zuerst zu schützen, was schon steht.«",
        "intro_1": "Im Spiegelteich sitzt ein Novize. Jeder seiner Züge sieht aus wie Kuzes eigener Schatten. »Wenn du dich wiederholst, werde ich dich lesen.«",
        "intro_2": "Am Schleiertor ruht ein Mönch im indigoenen Gewand. »Nicht jeder leere Platz muss sofort gefüllt werden.« Der Stein leuchtet mit alten goldenen Zeichen.",
        "intro_3": "Der Aschenläufer springt über glühende Stufen. »Zu langsam!« Er bringt Feuer in jede freie Reihe. Kuze hält die Hand ruhig.",
        "intro_4": "Unter roten Bannern wartet der Bannerhüter. »Eine Flamme ohne Ordnung vernichtet auch ihren eigenen Tempel.« Er schließt die Reihen wie Tore.",
        "intro_5": "Am Flammenaltar hebt der Hohepriester den Vulkanstein. »Beherrschst du das Feuer – oder beherrscht es dich?« Der letzte Kampf beginnt.",
        "win_0": "Der Nebelwächter senkt seinen Stab. Kuze entdeckt zwischen zwei Schritten erstmals eine Stille.",
        "win_1": "Der Spiegel-Novize lächelt: »Du hast deine Gewohnheit verlassen. Jetzt kann ich dir nicht mehr folgen.«",
        "win_2": "Der Schleiermönch verbeugt sich. Der Bambusnebel teilt sich und gibt das Schleiertor frei.",
        "win_3": "Der Aschenläufer atmet aus. »Auch eine Flamme muss einmal zur Ruhe kommen.«",
        "win_4": "Der Bannerhüter senkt sein Banner. Ordnung ist kein Käfig, sondern eine Entscheidung.",
        "win_5": "Der Hohepriester erkennt Kuzes stillen Blick. Die Glut wird warmes Licht, nicht länger Zorn.",
        "loss_0": "»Du hast die Lücke gesehen, aber zu spät«, raunt der Nebelwächter. »Versuche es erneut.«",
        "loss_1": "»Ich kenne diesen Schritt«, antwortet der Spiegel-Novize. »Finde einen anderen.«",
        "loss_2": "Der Schleiermönch rührt sich nicht. »Auch ein verlorener Zug kann ein Lehrer sein.«",
        "loss_3": "»Die Flamme war schneller!«, ruft der Aschenläufer. »Noch einmal!«",
        "loss_4": "Der Bannerhüter schließt das Tor. »Schütze erst die eigenen Reihen.«",
        "loss_5": "Der Hohepriester hebt die Hand. »Die Glut wartet. Beginne wieder.«",
        "react_0": "Nebelwächter: »Ein guter Block ist auch ein Weg.«",
        "react_1": "Spiegel-Novize: »Sieh hin. Deine Form kehrt zurück.«",
        "react_2": "Schleiermönch: »Stille ist nicht Stillstand.«",
        "react_3": "Aschenläufer: »Schneller! Nimm die offene Reihe!«",
        "react_4": "Bannerhüter: »Die Ränder sind ebenfalls ein Tor.«",
        "react_5": "Hohepriester: »Hüte die Flamme, ohne ihr zu folgen.«",
        "skin": "Boss-Skin aktiv",
        "saved": "Fortschritt wird separat gespeichert",
        "challenge_unlock": "Realm-Voraussetzungen fehlen",
        "missing_art": "Bild nicht verfügbar",
        "resume": "Partie fortsetzen",
        "new": "Nächster Kampf",
        "chapter_complete": "Kapitel abgeschlossen",
        "story": "Realm Chronicles",
        "finish_active": "Beende zuerst deine laufende 4×4-Partie, bevor du die Story startest.",
        "menu_button": "Zen Ascend · Realm Chronicles (4×4)"
    },
    "en": {
        "menu": "Zen Ascend · Realm Chronicles",
        "intro": "A second journey begins. The stone is larger and the paths unfamiliar. Kuze faces four realms, but only the first two paths are ready.",
        "shadow": "Chapter 1 · Shadow Realm",
        "ember": "Chapter 2 · Ember Temple",
        "celestial": "Chapter 3 · Celestial Realm",
        "satori": "Chapter 4 · Satori Realm",
        "shadow_sub": "The Whispering Veil · Doubt and patience",
        "ember_sub": "The Trial of Flame · Anger and discipline",
        "celestial_sub": "The Bridge Above Clouds · Coming later",
        "satori_sub": "The Summit of Awakening · Coming later",
        "continue": "Begin / resume battle",
        "back": "Back",
        "leave": "Return to main game",
        "retry": "Fight again",
        "next": "Face the next demon",
        "completed": "Completed",
        "current": "Current",
        "locked": "Locked",
        "coming": "Coming in a future update",
        "gate": "Ember Temple opens after defeating the Veil Monk AND completing all 8 Shadow Realm challenges.",
        "gate_mode": "Unlock Zen Ascend through Zen Master rank or the shop first.",
        "done": "The fire is calm. Kuze has walked the Shadow Realm and Ember Temple. The heavenly bridge awaits a future story.",
        "win": "The demon bows.",
        "loss": "The demon stays seated.",
        "draw": "Neither moves. Silence.",
        "chapter1_end": "The Veil Monk places his hand on the stone. The gate opens when Kuze stops trying to chase away the mist. Beyond the shadows, the Ember Temple burns.",
        "chapter2_end": "The flames subside. Kuze lowers his eyes. 'My anger was loud. My decision was mine.' The High Priest steps aside. A bridge of clouds appears above the temple.",
        "boss_0": "Mist Guardian",
        "boss_1": "Mirror Novice",
        "boss_2": "Veil Monk",
        "boss_3": "Ash Runner",
        "boss_4": "Banner Guardian",
        "boss_5": "High Priest of Embers",
        "intro_0": "Between the bamboo, a figure rises from moon-blue fog. 'You attack before you see,' says the Mist Guardian. 'First protect what is already there.'",
        "intro_1": "Beside the mirror pond sits a novice. Each move resembles Kuze's own shadow. 'Repeat yourself and I shall read you.'",
        "intro_2": "At the veiled gate, a monk rests in indigo robes. 'Not every empty space must be filled at once.' The stone glows with ancient golden signs.",
        "intro_3": "The Ash Runner leaps across blazing stairs. 'Too slow!' He brings fire into every open line. Kuze steadies his hand.",
        "intro_4": "Under red banners waits the Banner Guardian. 'Fire without order will destroy its own temple.' He seals the lines like gates.",
        "intro_5": "At the altar, the High Priest raises a volcanic stone. 'Do you command the fire, or does it command you?' The final battle begins.",
        "win_0": "The Mist Guardian lowers his staff. Between two steps Kuze finds silence.",
        "win_1": "The Mirror Novice smiles. 'You have left your habit behind. I can no longer follow you.'",
        "win_2": "The Veil Monk bows. The bamboo fog divides, revealing the gate.",
        "win_3": "The Ash Runner exhales. 'Even fire must rest.'",
        "win_4": "The Banner Guardian lowers his standard. Order is not a cage but a choice.",
        "win_5": "The High Priest sees Kuze's calm gaze. The embers become warmth instead of fury.",
        "loss_0": "'You saw the opening, but too late,' whispers the Mist Guardian. 'Try again.'",
        "loss_1": "'I know that step,' says the Mirror Novice. 'Find another.'",
        "loss_2": "The Veil Monk remains still. 'Even a lost move can teach.'",
        "loss_3": "'The flame was faster!' cries the Ash Runner. 'Again!'",
        "loss_4": "The Banner Guardian shuts the gate. 'Protect your lines first.'",
        "loss_5": "The High Priest raises his hand. 'The fire waits. Begin again.'",
        "react_0": "Mist Guardian: 'A good block is also a way.'",
        "react_1": "Mirror Novice: 'Look. Your form returns.'",
        "react_2": "Veil Monk: 'Stillness is not stagnation.'",
        "react_3": "Ash Runner: 'Faster! Take the open line!'",
        "react_4": "Banner Guardian: 'The edges are a gate too.'",
        "react_5": "High Priest: 'Guard the fire without following it.'",
        "skin": "Boss skin active",
        "saved": "Progress saved separately",
        "challenge_unlock": "Realm requirements not met",
        "missing_art": "Image unavailable",
        "resume": "Resume match",
        "new": "Next battle",
        "chapter_complete": "Chapter complete",
        "story": "Realm Chronicles",
        "finish_active": "Finish your current 4×4 match before starting the story.",
        "menu_button": "Zen Ascend · Realm Chronicles (4×4)"
    },
    "pt": {
        "menu": "Zen Ascend · Realm Chronicles",
        "intro": "Começa uma segunda viagem. A pedra é maior e os caminhos são desconhecidos. Kuze atravessará quatro reinos, mas só os primeiros dois estão preparados.",
        "shadow": "Capítulo 1 · Shadow Realm",
        "ember": "Capítulo 2 · Ember Temple",
        "celestial": "Capítulo 3 · Celestial Realm",
        "satori": "Capítulo 4 · Satori Realm",
        "shadow_sub": "The Whispering Veil · Dúvida e paciência",
        "ember_sub": "The Trial of Flame · Fúria e disciplina",
        "celestial_sub": "The Bridge Above Clouds · Em preparação",
        "satori_sub": "The Summit of Awakening · Em preparação",
        "continue": "Iniciar / continuar combate",
        "back": "Voltar",
        "leave": "Voltar ao jogo principal",
        "retry": "Lutar novamente",
        "next": "Enfrentar o próximo demónio",
        "completed": "Concluído",
        "current": "Atual",
        "locked": "Bloqueado",
        "coming": "Disponível numa futura atualização",
        "gate": "O Ember Temple abre depois de vencer o Monge do Véu E de completar os 8 desafios do Shadow Realm.",
        "gate_mode": "Primeiro, desbloqueia Zen Ascend com o título Mestre Zen ou na loja.",
        "done": "A chama acalmou. Kuze atravessou o Shadow Realm e o Ember Temple. A ponte celestial aguarda uma futura história.",
        "win": "O demónio inclina-se.",
        "loss": "O demónio continua sentado.",
        "draw": "Ninguém se move. Silêncio.",
        "chapter1_end": "O Monge do Véu pousa a mão na pedra. O portão abre-se quando Kuze deixa de tentar afastar a névoa. Para lá das sombras, arde o Ember Temple.",
        "chapter2_end": "As chamas abrandam. Kuze baixa os olhos. «A minha raiva era ruidosa. A decisão foi minha.» O Sumo Sacerdote afasta-se. Uma ponte de nuvens surge acima do templo.",
        "boss_0": "Guardião da Névoa",
        "boss_1": "Noviço do Espelho",
        "boss_2": "Monge do Véu",
        "boss_3": "Corredor das Cinzas",
        "boss_4": "Guardião do Estandarte",
        "boss_5": "Sumo Sacerdote das Brasas",
        "intro_0": "Entre bambus surge uma figura de névoa azulada. «Atacas antes de ver», diz o Guardião. «Protege primeiro o que já existe.»",
        "intro_1": "Junto ao lago espelhado senta-se um noviço. Cada jogada parece a sombra de Kuze. «Se te repetires, saberei ler-te.»",
        "intro_2": "No portão velado, um monge descansa em vestes índigo. «Nem todas as casas vazias exigem uma pedra.» O cubo brilha com sinais dourados.",
        "intro_3": "O Corredor das Cinzas salta por escadas em chamas. «Muito lento!» Acelera cada linha aberta. Kuze mantém a mão firme.",
        "intro_4": "Sob estandartes vermelhos espera o Guardião. «O fogo sem ordem destruirá o próprio templo.» Fecha linhas como portões.",
        "intro_5": "No altar, o Sumo Sacerdote ergue uma pedra vulcânica. «Dominas o fogo, ou ele domina-te?» Começa o último combate.",
        "win_0": "O Guardião da Névoa baixa o bastão. Entre dois passos, Kuze encontra silêncio.",
        "win_1": "O Noviço sorri. «Abandonaste o teu hábito. Já não consigo seguir-te.»",
        "win_2": "O Monge inclina-se. A névoa abre-se e revela o portão.",
        "win_3": "O Corredor das Cinzas expira. «Até o fogo precisa de repousar.»",
        "win_4": "O Guardião baixa o estandarte. A ordem é uma escolha, não uma prisão.",
        "win_5": "O Sumo Sacerdote reconhece a serenidade de Kuze. As brasas aquecem em vez de enfurecer.",
        "loss_0": "«Viste a abertura, mas tarde demais», murmura o Guardião. «Tenta de novo.»",
        "loss_1": "«Conheço esse passo», responde o Noviço. «Encontra outro.»",
        "loss_2": "O Monge permanece imóvel. «Uma jogada perdida também ensina.»",
        "loss_3": "«A chama foi mais rápida!», grita o Corredor. «Outra vez!»",
        "loss_4": "O Guardião fecha o portão. «Protege primeiro as tuas linhas.»",
        "loss_5": "O Sumo Sacerdote levanta a mão. «O fogo espera. Começa de novo.»",
        "react_0": "Guardião da Névoa: «Defender também é avançar.»",
        "react_1": "Noviço: «Vê. A tua forma regressa.»",
        "react_2": "Monge do Véu: «A quietude não é estagnação.»",
        "react_3": "Corredor: «Mais depressa! Toma a linha aberta!»",
        "react_4": "Guardião: «As arestas também são portões.»",
        "react_5": "Sumo Sacerdote: «Guarda a chama sem a seguir.»",
        "skin": "Aspeto do chefe ativo",
        "saved": "Progresso guardado separadamente",
        "challenge_unlock": "Requisitos do reino por cumprir",
        "missing_art": "Imagem indisponível",
        "resume": "Continuar partida",
        "new": "Próximo combate",
        "chapter_complete": "Capítulo concluído",
        "story": "Realm Chronicles",
        "finish_active": "Termina primeiro a tua partida 4×4 antes de iniciares a história.",
        "menu_button": "Zen Ascend · Realm Chronicles (4×4)"
    }
}
static func text_for(lang: String, key: String) -> String:
    var language: Dictionary = LOCALE.get(lang, LOCALE["en"])
    return str(language.get(key, LOCALE["en"].get(key, key)))

static func defaults() -> Dictionary:
    return {"version": VERSION, "stage": 0, "introduced": {}, "game": {}}

static func load_progress() -> Dictionary:
    var data: Dictionary = defaults()
    if not FileAccess.file_exists(SAVE):
        return data
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
    if not parsed is Dictionary or int(parsed.get("version", -1)) != VERSION:
        return data
    data.stage = clampi(int(parsed.get("stage",0)),0,6)
    data.introduced = parsed.get("introduced",{}) if parsed.get("introduced",{}) is Dictionary else {}
    data.game = parsed.get("game",{}) if parsed.get("game",{}) is Dictionary else {}
    if not valid_game(data.game): data.game = {}
    return data

static func valid_game(game: Dictionary) -> bool:
    if game.is_empty(): return true
    if not game.get("cells") is Array or game.cells.size() != 96: return false
    for mark in game.cells:
        if int(mark) not in [0,1,2]: return false
    return int(game.get("turn",0)) in [1,2] and int(game.get("result",0)) in [0,1,2,3]

static func save_progress(data: Dictionary) -> bool:
    var progress: Dictionary = {
        "version": VERSION,
        "stage": clampi(int(data.get("stage",0)),0,6),
        "introduced": data.get("introduced",{}),
        "game": data.get("game",{})
    }
    var temp: String = SAVE + ".tmp"
    var file := FileAccess.open(temp, FileAccess.WRITE)
    if file == null: return false
    file.store_string(JSON.stringify(progress))
    file.close()
    return DirAccess.rename_absolute(
        ProjectSettings.globalize_path(temp),
        ProjectSettings.globalize_path(SAVE)) == OK

static func chapter(stage: int) -> int:
    return 0 if stage < 3 else 1 if stage < 6 else 2

static func can_enter(data: Dictionary, stage: int) -> bool:
    if not ZenAscend.unlocked(data): return false
    if stage < 3: return ZenAscendRealms.unlocked(data,0)
    if stage < 6: return ZenAscendRealms.unlocked(data,1)
    return true

static func boss_level(stage: int) -> int:
    return ZenAscendRealms.fixed_bot_level(chapter(stage)) if stage < 6 else 2

static func _moves(cells: Array, lines: Array, player: int) -> Array:
    var free: Array = []
    for line in lines:
        var count: int = 0
        var empty: int = -1
        var blanks: int = 0
        var blocked: bool = false
        for index in line:
            if int(cells[index]) == player: count += 1
            elif int(cells[index]) == 0:
                empty = index
                blanks += 1
            else:
                blocked = true
                break
        if not blocked and count == 3 and blanks == 1 and not free.has(empty):
            free.append(empty)
    return free

static func choose_move(cells: Array, lines: Array, stage: int, last_player_cell: int = -1) -> int:
    # All bosses use exactly their Realm's fixed Medium/Hard baseline.
    # Their personality is a tactical *preference*, never a weaker tier.
    var level: int = boss_level(stage)
    var wins: Array = _moves(cells,lines,2)
    if not wins.is_empty(): return int(wins[0])
    var blocks: Array = _moves(cells,lines,1)
    if not blocks.is_empty():
        if stage in [0,2,4,5] or randf() < (0.84 if level == 1 else 0.92):
            return int(blocks[0])
    var standard: int = ZenAscendRealmBot.next_move(cells,lines,2,level,stage < 3)
    if standard < 0: return -1
    # Mirror Novice: genuine mirror of the player's last square when legal.
    if stage == 1 and last_player_cell >= 0 and randf() < 0.63:
        var face: int = int(last_player_cell / 16)
        var row: int = int(last_player_cell % 16 / 4)
        var col: int = last_player_cell % 4
        var opposite: int = face * 16 + (3-row) * 4 + (3-col)
        if int(cells[opposite]) == 0: return opposite
    # Ash Runner: prioritise own open three-mark threats; still respects
    # immediate win/block rules above and keeps the realm's Hard difficulty.
    if stage == 3 or stage == 5:
        var favorite: int = standard
        var best: float = -1e20
        for cell in range(cells.size()):
            if int(cells[cell]) != 0: continue
            var score: float = ZenAscendRealmBot._score(cells,lines,2,cell)
            if stage == 5: score += ZenAscendRealmBot._fork_score(cells,lines,2,cell)
            if score > best: best = score; favorite = cell
        if randf() < 0.6: return favorite
    # Veil Monk adds strategic fork preference at Medium, avoiding a forced
    # full difficulty bump to Master.
    if stage == 2 and randf() < 0.65:
        var best_cell: int = standard
        var best_value: float = -1.0
        for cell in range(cells.size()):
            if int(cells[cell]) != 0: continue
            var value: float = ZenAscendRealmBot._fork_score(cells,lines,2,cell)
            if value > best_value: best_value = value; best_cell = cell
        if best_value >= 25.0: return best_cell
    return standard
