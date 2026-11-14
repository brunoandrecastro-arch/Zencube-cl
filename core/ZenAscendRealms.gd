class_name ZenAscendRealms
extends RefCounted
# Isolated 4x4 progression. Never changes Classic 3x3, legacy stats, music IDs or save version.
const REALM_NAMES: Array[String] = ["Shadow Realm", "Ember Temple", "Celestial Realm", "Satori Realm"]
# Fixed Zen Ascend bot tiers; Classic bot progression is separate and unchanged.
const REALM_BOT_LEVELS: Array[int] = [1, 2, 3, 4] # Medium, Hard, Master, Grandmaster

static func fixed_bot_level(realm: int) -> int:
    return REALM_BOT_LEVELS[clampi(realm,0,3)]
const REALM_ART: Array[String] = [
    "res://assets/realms/shadow_realm.webp",
    "res://assets/realms/ember_temple.webp",
    "res://assets/realms/celestial_realm.webp",
    "res://assets/realms/satori_realm.webp"
]
const REALM_TITLES: Array = [
    ["Shadow Walker", "Keeper of Silence", "Moon Disciple", "Veil Breaker", "Master of Shadows"],
    ["Ember Initiate", "Flame Disciple", "Temple Challenger", "Fire-Bound Strategist", "Ember Master"],
    ["Sky Seeker", "Cloud Disciple", "Light Weaver", "Celestial Adept", "Celestial Master"],
    ["Mind Awakened", "Stillness Walker", "Satori Adept", "Keeper of Awareness", "Fully Aware"]
]
const OVERALL_TITLES: Array[String] = ["Ascend Initiate", "Realm Wanderer", "Temple Conqueror", "Celestial Strategist", "Satori Master"]
const TITLE_MILESTONES: Array[int] = [1, 2, 4, 6, 8]
const OVERALL_MILESTONES: Array[int] = [1, 6, 12, 22, 32]
# 8 x 4, id/required stats/reward. Titles stay independent of Classic Zen rank.
# All match tasks count real bot matches ONLY. Local two-player play never farms leaves.
const TASKS: Array = [
    [
        {"id":"shadow_first","title":"First Step into Shadow","metric":"wins","need":1,"leaves":40,"de":"Gewinne 1 Partie im Shadow Realm.","en":"Win one match in Shadow Realm.","pt":"Ganha uma partida no Shadow Realm."},
        {"id":"shadow_focus","title":"Quiet Focus","metric":"medium_win","need":1,"leaves":75,"de":"Besiege den Zen-Bot auf Mittel oder höher.","en":"Beat the Zen-Bot on Medium or higher.","pt":"Vence o Zen-Bot em Médio ou superior."},
        {"id":"shadow_edge","title":"Across the Edge","metric":"edge_wins","need":1,"leaves":75,"de":"Gewinne mit einer Gewinnlinie über eine Würfelkante.","en":"Win with a line across a cube edge.","pt":"Vence com uma linha através de uma aresta do cubo."},
        {"id":"shadow_fast","title":"No Hesitation","metric":"fast18","need":1,"leaves":75,"de":"Gewinne in höchstens 18 Gesamtzügen.","en":"Win in at most 18 total moves.","pt":"Vence em, no máximo, 18 jogadas no total."},
        {"id":"shadow_three","title":"Threefold Silence","metric":"wins","need":3,"leaves":75,"de":"Gewinne insgesamt 3 Partien in diesem Realm.","en":"Win 3 matches in this realm.","pt":"Ganha 3 partidas neste reino."},
        {"id":"shadow_streak","title":"Shadow Streak","metric":"best_streak","need":2,"leaves":75,"de":"Gewinne 2 Realm-Partien in Folge.","en":"Win 2 realm matches in a row.","pt":"Ganha 2 partidas seguidas neste reino."},
        {"id":"shadow_block","title":"Veil Tactician","metric":"block_wins","need":1,"leaves":120,"de":"Blockiere eine direkte Gewinnchance des Bots und gewinne dieselbe Partie.","en":"Block an immediate bot win and win that match.","pt":"Bloqueia uma vitória imediata do bot e ganha essa partida."},
        {"id":"shadow_hard","title":"Master of the Dark Path","metric":"face_wins","need":1,"leaves":120,"de":"Gewinne mit vier Zeichen auf einer Würfelfläche gegen Mittel.","en":"Win with four marks on one cube face against Medium.","pt":"Vence com quatro símbolos numa face do cubo contra Médio."}
    ],
    [
        {"id":"ember_first","title":"Trial by Flame","metric":"wins","need":1,"leaves":40,"de":"Gewinne 1 Partie im Ember Temple.","en":"Win one match in Ember Temple.","pt":"Ganha uma partida no Ember Temple."},
        {"id":"ember_hard","title":"Heat of Focus","metric":"hard_win","need":1,"leaves":75,"de":"Besiege den Zen-Bot auf Schwer oder höher.","en":"Beat the Zen-Bot on Hard or higher.","pt":"Vence o Zen-Bot em Difícil ou superior."},
        {"id":"ember_streak","title":"Burning Momentum","metric":"best_streak","need":2,"leaves":75,"de":"Gewinne 2 Realm-Partien in Folge.","en":"Win 2 realm matches in a row.","pt":"Ganha 2 partidas seguidas neste reino."},
        {"id":"ember_four","title":"Four Fires","metric":"wins","need":4,"leaves":75,"de":"Gewinne insgesamt 4 Partien im Ember Temple.","en":"Win 4 matches in Ember Temple.","pt":"Ganha 4 partidas no Ember Temple."},
        {"id":"ember_will","title":"Unbroken Will","metric":"wins_without_draw","need":2,"leaves":75,"de":"Gewinne zweimal, ohne dazwischen ein Unentschieden zu erzielen.","en":"Win twice without a draw between those wins.","pt":"Ganha duas vezes sem um empate pelo meio."},
        {"id":"ember_fast","title":"Temple Pressure","metric":"fast16","need":1,"leaves":120,"de":"Gewinne in höchstens 16 Gesamtzügen.","en":"Win in at most 16 total moves.","pt":"Vence em, no máximo, 16 jogadas no total."},
        {"id":"ember_edge","title":"Edge of Fire","metric":"edge_wins","need":1,"leaves":75,"de":"Gewinne mit einer Gewinnlinie über eine Würfelkante.","en":"Win with a line across a cube edge.","pt":"Vence com uma linha através de uma aresta do cubo."},
        {"id":"ember_master","title":"Ember Mastery","metric":"block_wins","need":1,"leaves":120,"de":"Blockiere einen direkten Gewinnzug des Hard-Bots und gewinne die Partie.","en":"Block an immediate Hard bot victory and win that match.","pt":"Bloqueia uma vitória imediata do bot Difícil e ganha a partida."}
    ],
    [
        {"id":"celestial_first","title":"Open Sky","metric":"wins","need":1,"leaves":40,"de":"Gewinne 1 Partie im Celestial Realm.","en":"Win one match in Celestial Realm.","pt":"Ganha uma partida no Celestial Realm."},
        {"id":"celestial_three","title":"Breath of Clarity","metric":"wins","need":3,"leaves":75,"de":"Gewinne insgesamt 3 Realm-Partien.","en":"Win 3 matches in this realm.","pt":"Ganha 3 partidas neste reino."},
        {"id":"celestial_balance","title":"Heaven’s Balance","metric":"balance","need":1,"leaves":75,"de":"Erziele 1 Sieg und 1 Unentschieden ohne Niederlage dazwischen.","en":"Get a win and a draw without a loss between them.","pt":"Consegue uma vitória e um empate sem derrotas pelo meio."},
        {"id":"celestial_master","title":"Winged Mind","metric":"master_win","need":1,"leaves":120,"de":"Besiege den Zen-Bot auf Meister oder höher.","en":"Beat the Zen-Bot on Master or higher.","pt":"Vence o Zen-Bot em Mestre ou superior."},
        {"id":"celestial_face","title":"Light Through Form","metric":"face_wins","need":1,"leaves":75,"de":"Gewinne mit vier Zeichen auf derselben Würfelseite.","en":"Win with four marks on one cube face.","pt":"Vence com quatro símbolos na mesma face do cubo."},
        {"id":"celestial_streak","title":"Still Above the Clouds","metric":"best_hard_streak","need":2,"leaves":120,"de":"Gewinne 2 Partien in Folge gegen Schwer oder höher.","en":"Win 2 consecutive games against Hard or higher.","pt":"Ganha 2 partidas seguidas contra Difícil ou superior."},
        {"id":"celestial_fast","title":"Celestial Discipline","metric":"fast15","need":1,"leaves":120,"de":"Gewinne in höchstens 15 Gesamtzügen.","en":"Win in at most 15 total moves.","pt":"Vence em, no máximo, 15 jogadas no total."},
        {"id":"celestial_grand","title":"Crown of Light","metric":"edge_wins","need":2,"leaves":120,"de":"Gewinne 2 Partien mit einer Viererlinie über die Würfelkante gegen Meister.","en":"Win 2 games across a cube edge against Master.","pt":"Ganha 2 partidas com uma linha pela aresta do cubo contra Mestre."}
    ],
    [
        {"id":"satori_first","title":"Enter Satori","metric":"wins","need":1,"leaves":40,"de":"Gewinne 1 Partie im Satori Realm.","en":"Win one match in Satori Realm.","pt":"Ganha uma partida no Satori Realm."},
        {"id":"satori_three","title":"Perfect Presence","metric":"wins","need":3,"leaves":75,"de":"Gewinne insgesamt 3 Realm-Partien.","en":"Win 3 matches in this realm.","pt":"Ganha 3 partidas neste reino."},
        {"id":"satori_master","title":"Unclouded Mind","metric":"master_win","need":1,"leaves":120,"de":"Besiege den Zen-Bot auf Meister oder höher.","en":"Beat the Zen-Bot on Master or higher.","pt":"Vence o Zen-Bot em Mestre ou superior."},
        {"id":"satori_grand","title":"Beyond Thought","metric":"grand_win","need":1,"leaves":120,"de":"Besiege den Zen-Bot auf Großmeister.","en":"Beat the Zen-Bot on Grandmaster.","pt":"Vence o Zen-Bot em Grande Mestre."},
        {"id":"satori_line","title":"Line of Insight","metric":"hard_line_wins","need":1,"leaves":120,"de":"Gewinne mit einer Viererlinie gegen Schwer oder höher.","en":"Win with a four-mark line against Hard or higher.","pt":"Vence com uma linha de quatro contra Difícil ou superior."},
        {"id":"satori_flow","title":"Flow State","metric":"best_master_streak","need":2,"leaves":120,"de":"Gewinne 2 Partien in Folge gegen Meister oder höher.","en":"Win 2 consecutive games against Master or higher.","pt":"Ganha 2 partidas seguidas contra Mestre ou superior."},
        {"id":"satori_fast","title":"No Distraction","metric":"fast14","need":1,"leaves":120,"de":"Gewinne in höchstens 14 Gesamtzügen.","en":"Win in at most 14 total moves.","pt":"Vence em, no máximo, 14 jogadas no total."},
        {"id":"satori_aware","title":"Fully Aware","metric":"satori_six","need":6,"leaves":120,"de":"Schließe 6 der ersten 7 Satori-Challenges ab.","en":"Complete 6 of the first 7 Satori challenges.","pt":"Conclui 6 dos primeiros 7 desafios de Satori."}
    ]
]

const COPY: Dictionary = {
    "realm": ["Realm", "Reino"],
    "realms": ["Realms", "Reinos"],
    "challenges": ["Challenges", "Desafios"],
    "titles": ["Titles", "Títulos"],
    "locked": ["Locked", "Bloqueado"],
    "unlocked": ["Unlocked", "Desbloqueado"],
    "select": ["Select realm", "Selecionar reino"],
    "selected": ["Selected realm", "Reino selecionado"],
    "earned": ["Earned", "Concluído"],
    "progress": ["Progress", "Progresso"],
    "leaves": ["Zen Leaves", "Folhas Zen"],
    "total": ["Total progress", "Progresso total"],
    "return": ["Back", "Voltar"],
    "ember_unlock": ["Complete all 8 Shadow Realm challenges", "Conclui todos os 8 desafios do Reino das Sombras"],
    "celestial_unlock": ["Complete all 8 Ember Temple challenges", "Conclui todos os 8 desafios do Templo das Chamas"],
    "satori_unlock": ["Complete all 8 Celestial Realm challenges", "Conclui todos os 8 desafios do Reino Celestial"],
    "play_finish": ["Finish the current match before switching realms.", "Termina a partida atual antes de mudares de reino."],
    "bot_only": ["Realm challenges only count Zen-Bot matches.", "Os desafios dos reinos contam apenas partidas contra o Zen-Bot."],
    "music_later": ["Realm music is coming soon.", "A música dos reinos chega em breve."],
    "reward": ["Reward", "Recompensa"],
    "total_titles": ["Overall title", "Título geral"],
    "rank": ["Realm title", "Título do reino"],
    "subtitle": ["A deeper path of strategy and awareness.", "Um caminho mais profundo de estratégia e consciência."],
    "choose_level": ["Choose a bot difficulty or play locally", "Escolhe a dificuldade do bot ou joga localmente"],
    "all_titles": ["Titles earned", "Títulos conquistados"],
    "new_awards": ["New realm rewards!", "Novas recompensas do reino!"],
    "realm_complete": ["Realm completed!", "Reino concluído!"],
    "matches": ["Realm wins", "Vitórias no reino"],
    "continue": ["Continue", "Continuar"]
}
const DE_COPY: Dictionary = {
    "realm":"Reich", "realms":"Reiche", "challenges":"Herausforderungen", "titles":"Titel", "locked":"Gesperrt",
    "unlocked":"Freigeschaltet", "select":"Realm wählen", "selected":"Aktives Realm", "earned":"Abgeschlossen",
    "progress":"Fortschritt", "leaves":"Zen-Blätter", "total":"Gesamtfortschritt", "return":"Zurück",
    "ember_unlock":"Schließe alle 8 Herausforderungen im Schattenreich ab",
    "celestial_unlock":"Schließe alle 8 Herausforderungen im Feuertempel ab",
    "satori_unlock":"Schließe alle 8 Herausforderungen im Himmelsreich ab",
    "play_finish":"Beende zuerst die aktuelle Partie, bevor du das Realm wechselst.",
    "bot_only":"Realm-Challenges zählen nur gegen den Zen-Bot.",
    "music_later":"Eigene Realm-Musik folgt später.", "reward":"Belohnung", "total_titles":"Gesamttitel", "rank":"Realm-Titel",
    "subtitle":"Ein tieferer Weg der Strategie und Achtsamkeit.",
    "choose_level":"Wähle eine Bot-Stufe oder spiele lokal zu zweit.",
    "all_titles":"Erhaltene Titel", "new_awards":"Neue Realm-Belohnungen!", "realm_complete":"Realm abgeschlossen!",
    "matches":"Realm-Siege", "continue":"Weiter"
}

const ZEN_DISPLAY_NAMES: Dictionary = {
    "Shadow Realm": ["Schattenreich", "Reino das Sombras"],
    "Ember Temple": ["Feuertempel", "Templo das Chamas"],
    "Celestial Realm": ["Himmelsreich", "Reino Celestial"],
    "Satori Realm": ["Satori-Reich", "Reino de Satori"],
    "Shadow Walker": ["Schattenwanderer", "Caminhante das Sombras"],
    "Keeper of Silence": ["Hüter der Stille", "Guardião do Silêncio"],
    "Moon Disciple": ["Schüler des Mondes", "Discípulo da Lua"],
    "Veil Breaker": ["Schleierbrecher", "Quebra-Véus"],
    "Master of Shadows": ["Meister der Schatten", "Mestre das Sombras"],
    "Ember Initiate": ["Feuer-Novize", "Iniciado das Chamas"],
    "Flame Disciple": ["Schüler der Flammen", "Discípulo das Chamas"],
    "Temple Challenger": ["Tempel-Herausforderer", "Desafiante do Templo"],
    "Fire-Bound Strategist": ["Stratege des Feuers", "Estratega do Fogo"],
    "Ember Master": ["Meister der Glut", "Mestre das Brasas"],
    "Sky Seeker": ["Himmelssucher", "Explorador dos Céus"],
    "Cloud Disciple": ["Schüler der Wolken", "Discípulo das Nuvens"],
    "Light Weaver": ["Lichtweber", "Tecelão da Luz"],
    "Celestial Adept": ["Himmelsadept", "Adepto Celestial"],
    "Celestial Master": ["Meister des Himmels", "Mestre Celestial"],
    "Mind Awakened": ["Erwachter Geist", "Mente Desperta"],
    "Stillness Walker": ["Wanderer der Stille", "Caminhante da Serenidade"],
    "Satori Adept": ["Satori-Adept", "Adepto de Satori"],
    "Keeper of Awareness": ["Hüter der Achtsamkeit", "Guardião da Consciência"],
    "Fully Aware": ["Vollkommene Klarheit", "Consciência Plena"],
    "Ascend Initiate": ["Aufstiegs-Novize", "Iniciado da Ascensão"],
    "Realm Wanderer": ["Wanderer der Reiche", "Viajante dos Reinos"],
    "Temple Conqueror": ["Tempelbezwinger", "Conquistador do Templo"],
    "Celestial Strategist": ["Himmelsstratege", "Estratega Celestial"],
    "Satori Master": ["Satori-Meister", "Mestre de Satori"],
    "First Step into Shadow": ["Erster Schritt im Schatten", "Primeiro Passo nas Sombras"],
    "Quiet Focus": ["Stille Konzentration", "Concentração Serena"],
    "Across the Edge": ["Über die Kante", "Para Lá da Aresta"],
    "No Hesitation": ["Ohne Zögern", "Sem Hesitar"],
    "Threefold Silence": ["Dreifache Stille", "Silêncio Triplo"],
    "Shadow Streak": ["Schatten-Siegesserie", "Série de Vitórias das Sombras"],
    "Veil Tactician": ["Taktiker des Schleiers", "Tático do Véu"],
    "Master of the Dark Path": ["Meister des dunklen Pfades", "Mestre do Caminho Sombrio"],
    "Trial by Flame": ["Feuerprobe", "Prova de Fogo"],
    "Heat of Focus": ["Brennender Fokus", "Foco Ardente"],
    "Burning Momentum": ["Brennende Siegesserie", "Ímpeto Ardente"],
    "Four Fires": ["Vier Flammen", "Quatro Chamas"],
    "Unbroken Will": ["Ungebrochener Wille", "Vontade Inabalável"],
    "Temple Pressure": ["Druck im Tempel", "Pressão no Templo"],
    "Edge of Fire": ["Feuerkante", "Aresta de Fogo"],
    "Ember Mastery": ["Beherrschung der Glut", "Domínio das Brasas"],
    "Open Sky": ["Offener Himmel", "Céu Aberto"],
    "Breath of Clarity": ["Atem der Klarheit", "Sopro de Clareza"],
    "Heaven’s Balance": ["Himmlisches Gleichgewicht", "Equilíbrio Celestial"],
    "Winged Mind": ["Beflügelter Geist", "Mente Alada"],
    "Light Through Form": ["Licht durch Form", "Luz na Forma"],
    "Still Above the Clouds": ["Stille über den Wolken", "Serenidade sobre as Nuvens"],
    "Celestial Discipline": ["Himmlische Disziplin", "Disciplina Celestial"],
    "Crown of Light": ["Krone des Lichts", "Coroa de Luz"],
    "Enter Satori": ["Eintritt ins Satori", "Entrada em Satori"],
    "Perfect Presence": ["Vollkommene Präsenz", "Presença Plena"],
    "Unclouded Mind": ["Klarer Geist", "Mente Límpida"],
    "Beyond Thought": ["Jenseits der Gedanken", "Além do Pensamento"],
    "Line of Insight": ["Linie der Erkenntnis", "Linha de Perceção"],
    "Flow State": ["Im Fluss", "Estado de Fluxo"],
    "No Distraction": ["Ohne Ablenkung", "Sem Distrações"],
}

static func localized_name(source: String, language: String) -> String:
    if language != "de" and language != "pt": return source
    var item: Variant = ZEN_DISPLAY_NAMES.get(source, [])
    if item is Array and item.size() == 2:
        return str(item[0] if language == "de" else item[1])
    return source

static func realm_name(idx: int, language: String) -> String:
    return localized_name(REALM_NAMES[clampi(idx, 0, 3)], language)

static func task_title(task: Dictionary, language: String) -> String:
    return localized_name(str(task.title), language)

static func title_for_realm(data: Dictionary, idx: int, language: String) -> String:
    return localized_name(current_title(data, idx), language)

static func overall_title_local(data: Dictionary, language: String) -> String:
    return localized_name(overall_title(data), language)

static func t(key: String, language: String) -> String:
    if language != "en" and language != "pt": return str(DE_COPY.get(key,key))
    var value: Variant = COPY.get(key, [])
    if value is Array and value.size() == 2:
        return str(value[0] if language == "en" else value[1])
    return key

static func task_description(task: Dictionary, language: String) -> String:
    var description: String = str(task.get(language if language in ["en","pt"] else "de", ""))
    if language in ["de", "pt"]:
        for index in range(REALM_NAMES.size()):
            description = description.replace(REALM_NAMES[index], realm_name(index, language))
    return description

static func blank_stats() -> Dictionary:
    return {"played":0,"wins":0,"draws":0,"losses":0,"streak":0,"best_streak":0,
        "hard_streak":0,"best_hard_streak":0,"master_streak":0,"best_master_streak":0,
        "wins_without_draw":0,"best_wins_without_draw":0,"balance_win":false,"balance_draw":false,"balance":0,
        "edge_wins":0,"face_wins":0,"block_wins":0,"medium_win":0,"hard_win":0,
        "master_win":0,"grand_win":0,"hard_line_wins":0,"fast18":0,"fast16":0,"fast15":0,"fast14":0}

static func ensure(data: Dictionary) -> void:
    ZenAscend.ensure(data)
    var existing: Variant = data.ascend.get("realm_state", {})
    var state: Dictionary = existing if existing is Dictionary else {}
    var selected: int = clampi(int(state.get("selected",0)),0,3)
    state["selected"] = selected
    var original_stats: Variant = state.get("stats", [])
    var raw_stats: Array = original_stats if original_stats is Array else []
    var stats: Array = []
    var default: Dictionary = blank_stats()
    for realm in range(4):
        var entry: Dictionary = raw_stats[realm] if raw_stats.size() > realm and raw_stats[realm] is Dictionary else {}
        var cleaned: Dictionary = default.duplicate(true)
        for key in default:
            if default[key] is bool: cleaned[key] = bool(entry.get(key,default[key]))
            else: cleaned[key] = maxi(0, int(entry.get(key,default[key])))
        stats.append(cleaned)
    state["stats"] = stats
    if not state.get("completed") is Dictionary: state["completed"] = {}
    if not state.get("realm_rewards") is Dictionary: state["realm_rewards"] = {}
    data.ascend["realm_state"] = state

static func state(data: Dictionary) -> Dictionary:
    ensure(data)
    return data.ascend.realm_state

static func count(data: Dictionary, realm: int) -> int:
    var st: Dictionary = state(data)
    var done: Dictionary = st.completed
    var amount: int = 0
    for task in TASKS[clampi(realm,0,3)]:
        if bool(done.get(str(task.id), false)): amount += 1
    return amount

static func total_count(data: Dictionary) -> int:
    var total: int = 0
    for realm in range(4): total += count(data,realm)
    return total

static func unlocked(data: Dictionary, realm: int) -> bool:
    if realm < 0 or realm >= 4 or not ZenAscend.unlocked(data): return false
    var st: Dictionary = state(data)
    if realm == 0: return true
    # A following Realm becomes accessible ONLY after all eight challenges
    # in the preceding Realm. Previous early-unlock shortcuts are removed.
    for required_realm in range(realm):
        if count(data,required_realm) < 8: return false
    return true

static func select(data: Dictionary, realm: int) -> bool:
    if not unlocked(data,realm): return false
    var st: Dictionary = state(data)
    st["selected"] = realm
    return true

static func current_title(data: Dictionary, realm: int) -> String:
    # Only one prestige title per realm. The other old title names became
    # independently earned secret achievements in ZenAscendAchievements.
    if realm < 0 or realm > 3: return "—"
    if count(data,realm) < 8: return "—"
    return str(REALM_TITLES[realm][4])

static func overall_title(data: Dictionary) -> String:
    var done: int = total_count(data)
    var title: String = "—"
    for i in range(5):
        if done >= OVERALL_MILESTONES[i]: title = str(OVERALL_TITLES[i])
    return title

static func missing_reason(data: Dictionary, realm: int, language: String) -> String:
    if realm <= 0 or realm >= 4: return ""
    var first_missing: int = realm - 1
    for earlier in range(realm):
        if count(data,earlier) < 8:
            first_missing = earlier
            break
    var key: String = ["ember_unlock", "celestial_unlock", "satori_unlock"][first_missing]
    return t(key, language)

# Does placing at this cell block an opponent's immediate four-in-a-row?
static func prevents_immediate_win(cells: Array, lines: Array, human_turn: int, cell: int) -> bool:
    if cell < 0 or cell >= cells.size() or int(cells[cell]) != 0: return false
    var enemy: int = 3 - human_turn
    for line in lines:
        if not line.has(cell): continue
        var other_marks: int = 0
        var valid: bool = true
        for index in line:
            var c: int = int(index)
            if c == cell: continue
            if int(cells[c]) == enemy: other_marks += 1
            else:
                valid = false
                break
        if valid and other_marks == 3: return true
    return false

static func is_edge_line(line: Array) -> bool:
    if line.size() != 4: return false
    var face: int = int(int(line[0])/16)
    for c in line:
        if int(int(c)/16) != face: return true
    return false

# outcome: 1 human win, 0 draw, -1 human loss; win_line(s) from real 4x4 rules.
# No result is counted twice: caller's recorded flag prevents duplicate finish calls.
static func record_bot_match(data: Dictionary, realm: int, outcome: int, difficulty: int, moves: int, lines_won: Array, blocked_a_threat: bool) -> Dictionary:
    var summary: Dictionary = {"new_tasks":[],"leaves":0,"realm_completed":false}
    if realm < 0 or realm > 3 or outcome not in [-1,0,1] or difficulty < 0 or difficulty > 4: return summary
    if not unlocked(data,realm): return summary
    var st: Dictionary = state(data)
    var stats: Dictionary = st.stats[realm]
    stats.played += 1
    if outcome == 1:
        stats.wins += 1
        stats.streak += 1
        stats.best_streak = maxi(int(stats.best_streak),int(stats.streak))
        stats.wins_without_draw += 1
        stats.best_wins_without_draw = maxi(int(stats.best_wins_without_draw),int(stats.wins_without_draw))
        stats.balance_win = true
        if difficulty >= 2: stats.hard_streak += 1
        else: stats.hard_streak = 0
        stats.best_hard_streak = maxi(int(stats.best_hard_streak),int(stats.hard_streak))
        if difficulty >= 3: stats.master_streak += 1
        else: stats.master_streak = 0
        stats.best_master_streak = maxi(int(stats.best_master_streak),int(stats.master_streak))
        if difficulty >= 1: stats.medium_win += 1
        if difficulty >= 2: stats.hard_win += 1
        if difficulty >= 3: stats.master_win += 1
        if difficulty == 4: stats.grand_win += 1
        if blocked_a_threat: stats.block_wins += 1
        var face: bool = false
        var edge: bool = false
        for line in lines_won:
            if line is Array and line.size() == 4:
                if is_edge_line(line): edge = true
                else: face = true
        if edge: stats.edge_wins += 1
        if face: stats.face_wins += 1
        if difficulty >= 2 and (edge or face): stats.hard_line_wins += 1
        if moves <= 18: stats.fast18 += 1
        if moves <= 16: stats.fast16 += 1
        if moves <= 15: stats.fast15 += 1
        if moves <= 14: stats.fast14 += 1
    elif outcome == 0:
        stats.draws += 1
        stats.streak = 0
        stats.hard_streak = 0
        stats.master_streak = 0
        stats.wins_without_draw = 0
        stats.balance_draw = true
    else:
        stats.losses += 1
        stats.streak = 0
        stats.hard_streak = 0
        stats.master_streak = 0
        stats.balance_win = false
        stats.balance_draw = false
    if bool(stats.balance_win) and bool(stats.balance_draw): stats.balance = 1
    var earned: Dictionary = st.completed
    for task in TASKS[realm]:
        var id: String = str(task.id)
        if bool(earned.get(id,false)): continue
        var value: int = 0
        if str(task.metric) == "wins_without_draw": value = int(stats.best_wins_without_draw)
        elif str(task.metric) == "satori_six":
            for i in range(7):
                if bool(earned.get(str(TASKS[3][i].id),false)): value += 1
        else: value = int(stats.get(str(task.metric),0))
        if value >= int(task.need):
            earned[id] = true
            data.economy.leaves = maxi(0,int(data.economy.get("leaves",0))) + int(task.leaves)
            summary.leaves += int(task.leaves)
            summary.new_tasks.append(id)
    if count(data,realm) == 8 and not bool(st.realm_rewards.get(str(realm),false)):
        st.realm_rewards[str(realm)] = true
        data.economy.leaves = maxi(0,int(data.economy.get("leaves",0))) + 250
        summary.leaves += 250
        summary.realm_completed = true
    return summary
