# ZenCube v3 – Testbericht (8. November 2026)

## Tatsächlich durchgeführte unabhängige Prüfungen

- `python3 tests/test_108_rules.py` – PASS:
  - 6 Seiten, 54 getrennte Felder, 12 Kanten
  - 108 Viererlinien, je 36 der Verteilungen 3+1, 2+2, 1+3
  - Alle 24 Eigendrehungen des Würfels behalten die Gewinnlinien bei
  - Für beide Spieler wurde jede der 108 Linien als gültiger Sieg und jede zugehörige 3-Steine-Drohung geprüft
  - Ungültige gleiche-Fläche- und Mehrseiten-Muster abgewiesen
  - 3000 deterministische Zufallspartien ohne frühen Gewinn vor Halbzug 7
- Unabhängiger Abgleich der in Godot geplanten `CubeGeometry.boundary`-Logik gegen den separaten Python-Generator – PASS (108 identische Feldkombinationen).
- `g++ -O3 -std=c++17 tests/simulate.cpp` plus 10.000 Partie-Simulationen auf der 108-Linien-Referenz – PASS als Simulation, *kein* Beweis von Fairness.
- Statische Prüfung auf unausgeglichene Klammern/Zeichenketten bei allen 12 `.gd`-Dateien – PASS als reine Textanalyse.

## Noch nicht ausgeführt

- `godot --headless --editor --import --quit` (kein Godot-Binary verfügbar)
- `godot --headless --script tests/test_engine.gd`
- `godot --headless --script tests/test_ui.gd`
- Android-GUI-Tap-Tests und realer Gerätetest
- Android-APK-Export/Installation

**Die oben aufgeführten nicht ausgeführten Prüfungen dürfen nicht als bestanden ausgegeben werden.**

## Ergebnis der 10.000 KI-/Zufallsspiele

Details in `reports/simulation_v3.json`. Stärkere taktische Strategien gewinnen gegen schwächere in den Tests häufig. Für gleich starke Strategien treten unterschiedliche X/O-Gewinnquoten und teils viele Remis auf. Daraus lässt sich keine mathematisch perfekte Balance ableiten.

## Testplan auf dem Android-Gerät

1. Starten: Willkommensbildschirm mit 3+1/2+2 visuell korrekt
2. Starten: erster Gegner Zen-Bot auf Leicht
3. Würfel drehen und zoomen: keine versehentlichen Spielzüge
4. Nur tippen: genau eine Markierung setzen
5. Menü öffnen, lokales Spiel, Einstellungen, Tutorial, Statistik öffnen und schließen
6. Neue Partie nach einem Zug: Bestätigung → Spielfeld leer
7. Tutorial 3+1, 2+2 und Blockieren mit echten Regelprüfungen
8. Eine 1+3-Linie und eine 2+2-Linie als Sieg, eine einfache Dreierreihe ohne Sieg
9. Wiederholter App-Neustart: gespeicherte Einstellungen bleiben erhalten
10. Ausführung nach Rotation des Würfels und Wechsel der Startperson
