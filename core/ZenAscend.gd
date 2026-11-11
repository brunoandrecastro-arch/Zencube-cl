class_name ZenAscend
extends RefCounted
# Separate 4x4 mode: the existing Classic 3x3 rules and saves are untouched.
# Only exported Android debug APKs with the internal feature tag receive test access.
# Production / Play Store releases can never use this override.
const TEST_UNLOCKED: bool = true
const PRICE: int = 750
const CELLS: int = 96
const SIDE: int = 4

const WORDS: Dictionary = {
    "Zen Ascend 4×4": ["Zen Ascend 4×4", "Zen Ascend 4×4"],
    "Testversion: direkt spielbar": ["Test build: playable immediately", "Versão de teste: disponível já"],
    "Neuer Modus: 6 Seiten mit je 4×4 Feldern (96 Felder).": ["New mode: six 4×4 faces (96 cells).", "Novo modo: seis faces 4×4 (96 casas)."],
    "Gewinne mit vier X oder O in einer Reihe: waagerecht, senkrecht oder diagonal auf einer Fläche ODER gerade über eine Würfelkante (1+3, 2+2, 3+1).": ["Win with four X or O in a row: horizontally, vertically or diagonally on one face OR straight across a cube edge (1+3, 2+2, 3+1).", "Ganha com quatro X ou O em linha: horizontal, vertical ou diagonal numa face OU em linha reta através de uma aresta (1+3, 2+2, 3+1)."],
    "204 mögliche Gewinnlinien. Die klassische 3×3-Version bleibt unverändert.": ["204 possible winning lines. Classic 3×3 remains unchanged.", "204 linhas de vitória possíveis. O Clássico 3×3 não muda."],
    "Ab Zen-Meister freischaltbar oder für 750 Zen-Blätter im Shop.": ["Unlock at Zen Master rank or for 750 Zen Leaves in the shop.", "Desbloqueia ao alcançar Mestre Zen ou por 750 Folhas Zen na loja."],
    "Zen Ascend freigeschaltet!": ["Zen Ascend unlocked!", "Zen Ascend desbloqueado!"],
    "Zen Ascend ausprobieren": ["Try Zen Ascend", "Experimentar Zen Ascend"],
    "Zen Ascend freischalten": ["Unlock Zen Ascend", "Desbloquear Zen Ascend"],
    "Zen Ascend kaufen · 🍃 750": ["Buy Zen Ascend · 🍃 750", "Comprar Zen Ascend · 🍃 750"],
    "Modus freigeschaltet!": ["Mode unlocked!", "Modo desbloqueado!"],
    "Du brauchst 750 Zen-Blätter oder den Rang Zen-Meister.": ["You need 750 Zen Leaves or the Zen Master rank.", "Precisas de 750 Folhas Zen ou do nível Mestre Zen."],
    "Regeln ansehen": ["View rules", "Ver regras"],
    "Gegen Zen-Bot": ["Play Zen-Bot", "Jogar contra o Zen-Bot"],
    "Zu zweit spielen": ["Two players", "Dois jogadores"],
    "Vier auf einer Fläche oder über eine Kante gewinnen!": ["Connect four on a face or across an edge to win!", "Liga quatro numa face ou através de uma aresta para ganhar!"],
    "Ziehen: drehen · Tippen: setzen · Zwei Finger: zoomen": ["Drag: rotate · Tap: mark · Two fingers: zoom", "Arrastar: rodar · Tocar: jogar · Dois dedos: zoom"],
    "Neue Partie": ["New match", "Nova partida"],
    "Hauptmenü": ["Main menu", "Menu principal"],
    "Spielername": ["Player name", "Nome do jogador"],
    "Spieler 1": ["Player 1", "Jogador 1"],
    "Spieler 2": ["Player 2", "Jogador 2"],
    "Statistik & Rang": ["Statistics & rank", "Estatísticas e nível"],
    "Partien": ["Matches", "Partidas"],
    "Siege": ["Wins", "Vitórias"],
    "Niederlagen": ["Losses", "Derrotas"],
    "Unentschieden": ["Draws", "Empates"],
    "Siegquote": ["Win rate", "Taxa de vitórias"],
    "Beste Siegesserie": ["Best win streak", "Melhor série de vitórias"],
    "Aktuelle Siegesserie": ["Current win streak", "Série de vitórias atual"],
    "Züge gesamt": ["Total moves", "Jogadas no total"],
    "Züge pro Partie": ["Moves per match", "Jogadas por partida"],
    "Schnellster Sieg": ["Fastest win", "Vitória mais rápida"],
    "Zen-Rang": ["Zen rank", "Nível Zen"],
    "Nächste Rangprüfung": ["Next rank challenge", "Próximo desafio de nível"],
    "4×4 Partien": ["4×4 matches", "Partidas 4×4"],
    "4×4 gegen Bot": ["4×4 vs Bot", "4×4 contra bot"],
    "4×4 zu zweit": ["4×4 local", "4×4 local"],
    "Rückkehr zum klassischen Spiel": ["Return to Classic", "Regressar ao Clássico"],
    "Du bist am Zug": ["Your turn", "É a tua vez"],
    "Zen-Bot überlegt …": ["Zen-Bot is thinking …", "O Zen-Bot está a pensar …"],
    "hat gewonnen!": ["wins!", "venceu!"],
    "Zen-Bot hat gewonnen!": ["Zen-Bot won!", "O Zen-Bot ganhou!"],
    "Unentschieden!": ["Draw!", "Empate!"],
    "Zurück": ["Back", "Voltar"],
    "In Zen Ascend werden Ergebnisse separat vom klassischen Modus gezählt.": ["Zen Ascend results are tracked separately from Classic.", "Os resultados de Zen Ascend contam separadamente do Clássico."],
}
static func t(source: String, language: String) -> String:
    var phrase: Variant = WORDS.get(source, [])
    if phrase is Array and phrase.size() == 2:
        if language == "en": return str(phrase[0])
        if language == "pt": return str(phrase[1])
    return source

# Production entitlement, independent from the temporary test override.
static func unlocked_for_release(data: Dictionary) -> bool:
    return bool(data.get("economy",{}).get("ascend_owned",false)) or int(data.get("ascension",{}).get("rank",0)) >= 3

static func test_access_enabled() -> bool:
    # Both the debug-only tag and a debug runtime are required; release always wins.
    return TEST_UNLOCKED and OS.has_feature("zencube_ascend_test") and OS.has_feature("debug") and not OS.has_feature("release")

static func unlocked(data: Dictionary) -> bool:
    return test_access_enabled() or unlocked_for_release(data)

static func buy(data: Dictionary) -> bool:
    # Do not charge anyone who already unlocked the mode through Zen-Meister.
    if unlocked_for_release(data): return false
    if int(data.get("economy",{}).get("leaves",0)) < PRICE: return false
    data.economy.leaves -= PRICE
    data.economy["ascend_owned"] = true
    return true

static func ensure(data: Dictionary) -> void:
    if not data.get("ascend") is Dictionary: data["ascend"] = {}
    var st: Dictionary = data["ascend"]
    for key in ["played","p1","p2","draw","bot_wins","bot_losses","bot_played","local_played","current_streak","best_streak","moves","fastest_win"]:
        st[key] = maxi(0, int(st.get(key,0)))
    st["help_seen"] = bool(st.get("help_seen",false))
    st["next_start"] = clampi(int(st.get("next_start",0)),0,1)

static func center(cell: int, height: float = 1.62) -> Vector3:
    var f: int = int(cell / 16)
    var pos: int = cell % 16
    var row: int = int(pos / 4)
    var col: int = pos % 4
    return CubeGeometry.N[f] * height + CubeGeometry.U[f] * (float(col) - 1.5) * 0.8 + CubeGeometry.V[f] * (float(row) - 1.5) * 0.8

static func boundary(face: int, neighbor: int, tangent: Vector3, lane: int, inward: int) -> int:
    var desired_near: float = 1.2 - float(inward) * 0.8
    var desired_lane: float = -1.2 + float(lane) * 0.8
    for c in range(face * 16, face * 16 + 16):
        var p: Vector3 = center(c, 0.0)
        if absf(p.dot(CubeGeometry.N[neighbor]) - desired_near) < 0.001 and absf(p.dot(tangent) - desired_lane) < 0.001:
            return c
    return -1

static func generate_lines() -> Array:
    var lines: Array = []
    for f in range(6):
        for r in range(4):
            var horizontal: Array = []
            var vertical: Array = []
            for c in range(4):
                horizontal.append(f * 16 + r * 4 + c)
                vertical.append(f * 16 + c * 4 + r)
            lines.append(horizontal)
            lines.append(vertical)
        lines.append([f*16, f*16+5, f*16+10, f*16+15])
        lines.append([f*16+3, f*16+6, f*16+9, f*16+12])
    for a in range(6):
        for b in range(a+1, 6):
            if CubeGeometry.N[a].dot(CubeGeometry.N[b]) != 0.0: continue
            var tangent: Vector3 = CubeGeometry.N[a].cross(CubeGeometry.N[b])
            for lane in range(4):
                for split in range(1, 4):
                    var line: Array = []
                    for k in range(split-1, -1, -1):
                        line.append(boundary(a,b,tangent,lane,k))
                    for k in range(4-split):
                        line.append(boundary(b,a,tangent,lane,k))
                    if not line.has(-1): lines.append(line)
    return lines

static func winning_lines(cells: Array, lines: Array, player: int) -> Array:
    var complete: Array = []
    for line in lines:
        var ok: bool = true
        for c in line:
            if cells[int(c)] != player:
                ok = false
                break
        if ok: complete.append(line)
    return complete

static func next_move(cells: Array, lines: Array, player: int) -> int:
    # Tactical bot: win now; otherwise block immediate loss; then favor rich lines.
    for owner in [player, 3-player]:
        for line in lines:
            var missing: int = -1
            var count: int = 0
            var viable: bool = true
            for c in line:
                if cells[int(c)] == owner: count += 1
                elif cells[int(c)] == 0:
                    if missing == -1: missing = int(c)
                    else: viable = false
                else: viable = false
            if viable and count == 3 and missing >= 0: return missing
    var weights: Array = []
    weights.resize(CELLS)
    weights.fill(0)
    for line in lines:
        var own: int = 0
        var enemy: int = 0
        for c in line:
            if cells[int(c)] == player: own += 1
            elif cells[int(c)] == 3-player: enemy += 1
        if own > 0 and enemy > 0: continue
        var score: int = 2 + own*own*4 + enemy*enemy*2
        for c in line:
            if cells[int(c)] == 0: weights[int(c)] += score
    var best_score: int = -1
    var best_cells: Array = []
    for c in range(CELLS):
        if cells[c] != 0: continue
        if int(weights[c]) > best_score:
            best_score = int(weights[c])
            best_cells = [c]
        elif int(weights[c]) == best_score:
            best_cells.append(c)
    if best_cells.is_empty(): return -1
    return int(best_cells[randi_range(0,best_cells.size()-1)])
