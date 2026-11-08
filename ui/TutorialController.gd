class_name TutorialController
extends RefCounted
var step: int = 0
const TEXTS = [
    "Bewegen · Streiche über den Würfel. Ziehen dreht, zwei Finger zoomen.",
    "Setzen · Tippe ein freies Feld. Du spielst X gegen Zen-Bot O.",
    "3+1 · Drei X auf einer Seite und eines auf der Nachbarseite. Setze das letzte X!",
    "2+2 · Zwei X pro Seite, gegenüber einer gemeinsamen Kante. Ergänze das letzte X!",
    "Verteidigen · O droht mit vier Steinen. Blockiere das markierte Feld mit X.",
    "Wichtig · Drei X auf einer Seite allein reichen NICHT. Nur 4 über zwei Seiten zählen.",
    "Bereit? Über „Spielen“ geht es los. Beim ersten Start spielst du gegen Zen-Bot auf Leicht."
]
func setup(board: BoardModel, lines: Array) -> Array:
    board.cells.fill(0)
    board.last_cell = -1
    board.turn = 1
    board.winner = 0
    board.win_lines = []
    board.history = []
    board.swap_pending = false
    board.swap_enabled = false
    board.owners = [0,1]
    board.result_recorded = false
    var line: Array = []
    if step in [2,3,4]:
        var desired := 2 if step == 3 else 3
        for candidate in lines:
            var first_face := CubeGeometry.face(int(candidate[0]))
            var count := 0
            for c in candidate:
                if CubeGeometry.face(int(c)) == first_face: count += 1
            if count == desired:
                line = candidate.duplicate()
                break
        for i in range(3): board.cells[line[i]] = 2 if step == 4 else 1
    elif step == 5:
        for c in [0,1,2]: board.cells[c] = 1
    return line
