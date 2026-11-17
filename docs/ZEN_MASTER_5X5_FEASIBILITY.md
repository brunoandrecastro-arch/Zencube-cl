# Zen Master 5×5 — Technischer Machbarkeitsbericht & isolierter Prototyp

**Status:** erste technische Spielszene, kein Android-Release, keine Store-Anbindung. 
**Branch:** `prototype/zen-master-5x5` (von `main` abgeleitet).
**Godot:** 4.5.1.

## Befund aus dem echten Repository

- **Classic 3×3:** `core/BoardModel.gd` hält 54 Zellen. `core/CubeGeometry.gd`, `core/WinLineGenerator.gd` und `core/RulesEngine.gd` bilden 108 Kantenlinien ab.
- **Zen Ascend 4×4:** `core/ZenAscend.gd` hält 96 Zellen, zählt 60 Linien auf den Flächen und 144 über zwölf Kanten (204 insgesamt). `ui/AscendRenderer.gd` rendert einen eigenen 3D-Würfel.
- **Classic-KI:** `core/AIEngine.gd` verwendet hartcodierte 54-Zellen-Suchen, vierstellige Auswertungen und Zeitbudgets. Auf 5×5 unverändert nicht verwendbar.
- **4×4-Bot:** `ZenAscend.next_move()` behandelt Vierergewinnlinien. Auch diese Funktion muss für Fünferlinien angepasst werden.
- **Touch/Rendering:** Rotieren, Raycast-Auswahl und Pinch-Zoom sind bereits erprobte Muster. 150 statt 96 Zellen bedeuten mehr Collider und kleinere Touchflächen; reale Android-Tests bleiben notwendig.

## Festgelegte 5×5-Regeln für das Experiment

- Sechs Flächen mit je 5×5 Feldern, **150 Zellen**.
- Ein Sieg benötigt **fünf** gleiche Zeichen in gerader Reihe.
- **72 Flächenlinien**: 6 × (5 Reihen + 5 Spalten + 2 Diagonalen).
- **240 Kantenlinien**: 12 physische Kanten × 5 Spuren × 4 Aufteilungen (1+4, 2+3, 3+2, 4+1).
- **312 eindeutige Linien insgesamt.** Keine knickenden Ecklinien und keine Linien über drei Flächen.
- **Unentschieden** nur bei vollem Spielbrett ohne Gewinnlinie.
- Keine Sonderregeln, die klassische Spielmechanik wird nicht verändert.

## Implementierter Prototyp

- `core/ZenMaster.gd`: unabhängige Geometrie, Fünfer-Sieglinien, Auswertung, unmittelbares Gewinnen/Blockieren und einfacher gewichteter Bot. Der Bot ist **kein** optimierter Master/Grandmaster.
- `ui/ZenMasterPrototype.gd`: 150 3D-Felder mit Collider, X/O, Drehung, Zoom, Touch- und Mausbedienung, hervorgehobenen Gewinnlinien, Zwei-Spieler-Modus und Zen-Bot.
- `ZenMasterPrototype.tscn`: isoliert startbare Szene, **nicht ins Hauptmenü eingebaut**, keine Änderung bestehender Spielstände.
- `tests/test_zen_master_5x5.gd`: reale Godot-Prüfungen der Linien und der Szene.

**Lokal in Godot:** `ZenMasterPrototype.tscn` öffnen und „Szene starten“ wählen.

**CLI:** `godot --path . res://ZenMasterPrototype.tscn`

**Godot-Tests:** `godot --headless --path . --script tests/test_zen_master_5x5.gd`

## Noch nicht fertig / Risiken

1. **Echte Android-Gerätetests**: Sichtbarkeit und Treffergröße besonders bei stark rotiertem Würfel, unterschiedliche Displaygrößen, Touch- und Pinch-Zuverlässigkeit.
2. **KI-Schwierigkeitsstufen**: später Alpha-Beta/iterative Vertiefung, Kandidatenbegrenzung und Zeitbudget analysieren; auf 150 möglichen Zügen kann rohe Tiefensuche zu langsam sein. Keine Fairnessversprechen vor Tests.
3. **Realm-System**: vier mögliche neue Welten (Void Sanctuary, Moonlit Garden, Astral Monastery, Origin Realm), jeweils mit Bossen, Herausforderungen, Musik und Kuze-Kapiteln. Diese Inhalte sind **noch nicht implementiert**.
4. **Freischaltungen**: später strikt nach besiegtem Satori-Finale und allen vorgesehenen Voraussetzungen; keine Debug-Bypässe im Store-Build.
5. **Lokalisierung und Save-Migration**: neue Texte in DE/EN/PT, unabhängiger `zen_master`-Save-Abschnitt, niemals die 3×3-/4×4-Daten überschreiben.
6. **Mobilperformance**: Objekt-Pooling/MultiMesh bzw. Materialcache prüfen, falls 150 Tiles und X/O-Ringe auf Android zu teuer sind.

## Release-Schutz

Diese erste Iteration enthält **keinen** App-Menüeintrag, **keine** Play-AAB, **keine** Aktualisierung von `main` oder PR #3, **keinen** neuen Paketnamen und **keine** Google-Play-Veröffentlichung. Testszene im eigenen Branch.
