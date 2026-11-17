# Zen Master 5×5 — Technischer Machbarkeitsbericht & isolierter Prototyp

**Status:** Satori-4×4-Testfinale mit Eis-/Fensterbruch und Void-Sanctuary-5×5-Prototyp mit eigener CI-Test-APK; kein Google-Play-Release und keine Store-Anbindung. 
**Branch:** `prototype/zen-master-5x5` (von `main` abgeleitet).
**Godot:** 4.5.1.

## Befund aus dem echten Repository

- **Classic 3×3:** `core/BoardModel.gd` hält 54 Zellen. `core/CubeGeometry.gd`, `core/WinLineGenerator.gd` und `core/RulesEngine.gd` bilden 108 Kantenlinien ab.
- **Zen Ascend 4×4:** `core/ZenAscend.gd` hält 96 Zellen, zählt 60 Linien auf den Flächen und 144 über zwölf Kanten (204 insgesamt). `ui/AscendRenderer.gd` rendert einen eigenen 3D-Würfel.
- **Classic-KI:** `core/AIEngine.gd` verwendet hartcodierte 54-Zellen-Suchen, vierstellige Auswertungen und Zeitbudgets. Auf 5×5 unverändert nicht verwendbar.
- **4×4-Bot:** `ZenAscend.next_move()` behandelt Vierergewinnlinien. Für den 5×5-Modus bleibt dieselbe Vierer-Gewinnbedingung bestehen; die taktische Auswertung wurde dafür eigenständig angepasst.
- **Touch/Rendering:** Rotieren, Raycast-Auswahl und Pinch-Zoom sind bereits erprobte Muster. 150 statt 96 Zellen bedeuten mehr Collider und kleinere Touchflächen; reale Android-Tests bleiben notwendig.

## Festgelegte 5×5-Regeln für das Experiment

- Sechs Flächen mit je 5×5 Feldern, **150 Zellen**.
- Ein Sieg benötigt weiterhin **vier** gleiche Zeichen in gerader Reihe, obwohl jede Fläche 5×5 Felder hat.
- **168 Flächenlinien**: pro Fläche 10 waagerechte und 10 senkrechte Viererfenster sowie 8 Diagonalfenster, auf sechs Flächen.
- **180 Kantenlinien**: 12 physische Kanten × 5 Spuren × 3 Aufteilungen (1+3, 2+2, 3+1).
- **348 eindeutige Viererlinien insgesamt.** Keine knickenden Ecklinien und keine Linien über drei Flächen.
- **Unentschieden** nur bei vollem Spielbrett ohne Gewinnlinie.
- Keine Sonderregeln, die klassische Spielmechanik wird nicht verändert.

## Implementierter Prototyp

- `core/ZenMaster.gd`: unabhängige Geometrie, Vierer-Sieglinien, Auswertung, unmittelbares Gewinnen/Blockieren und einfacher gewichteter Bot. Der Bot ist **kein** optimierter Master/Grandmaster.
- `ui/ZenMasterPrototype.gd`: 150 3D-Felder mit Collider, X/O, Drehung, Zoom, Touch- und Mausbedienung, hervorgehobenen Gewinnlinien, Zwei-Spieler-Modus und Zen-Bot.
- `ZenMasterPrototype.tscn`: isoliert startbare Void-Sanctuary-Szene (5×5, 4 Gewinnt), **nicht ins Hauptmenü eingebaut**, keine Änderung bestehender Spielstände.
- `ZenMasterBridgeTest.tscn`: separate Satori-4×4-Abschlussprüfung mit leichtem Bot, sichtbaren Rissen/Eisplatten, eigenem Bruchsound und Übergang in Void Sanctuary.
- `tests/test_zen_master_5x5.gd`: reale Godot-Prüfungen der Linien und der Szene.

**Android-Smartphone:** GitHub Actions baut eine separat installierbare Debug-APK mit dem nur für Tests verwendeten Paketnamen `com.zencube.game.zenmaster`. Es ersetzt weder die aktuelle Play-App `com.zencube.game.play` noch den normalen Classic-Debug-Build `com.zencube.game`. Der Workflow ändert `project.godot` und die Android-Debug-Exportkonfiguration **nur im temporären CI-Arbeitsverzeichnis**, nicht als Commit. GitHub Actions → `Zen Master 5x5 prototype checks` → erfolgreich gelaufenen Build öffnen → Artefakt `ZenMaster-Satori-Void-Android-Test` herunterladen, ZIP entpacken und APK auf Android installieren. Noch keine visuelle Gerätetest-Freigabe.\n\n**Lokal in Godot:** `ZenMasterPrototype.tscn` öffnen und „Szene starten“ wählen.

**CLI:** `godot --path . res://ZenMasterBridgeTest.tscn`

**Godot-Tests:** `godot --headless --path . --script tests/test_zen_master_5x5.gd`

## Noch nicht fertig / Risiken

1. **Echte Android-Gerätetests**: Sichtbarkeit und Treffergröße besonders bei stark rotiertem Würfel, unterschiedliche Displaygrößen, Touch- und Pinch-Zuverlässigkeit.
2. **KI-Schwierigkeitsstufen**: später Alpha-Beta/iterative Vertiefung, Kandidatenbegrenzung und Zeitbudget analysieren; auf 150 möglichen Zügen kann rohe Tiefensuche zu langsam sein. Keine Fairnessversprechen vor Tests.
3. **Realm-System**: vier mögliche neue Welten (Void Sanctuary, Moonlit Garden, Astral Monastery, Origin Realm), jeweils mit Bossen, Herausforderungen, Musik und Kuze-Kapiteln. Diese Inhalte sind **noch nicht implementiert**.
4. **Freischaltungen**: später strikt nach besiegtem Satori-Finale und allen vorgesehenen Voraussetzungen; keine Debug-Bypässe im Store-Build.
5. **Lokalisierung und Save-Migration**: neue Texte in DE/EN/PT, unabhängiger `zen_master`-Save-Abschnitt, niemals die 3×3-/4×4-Daten überschreiben.
6. **Mobilperformance**: Objekt-Pooling/MultiMesh bzw. Materialcache prüfen, falls 150 Tiles und X/O-Ringe auf Android zu teuer sind.

## Release-Schutz

Diese erste Iteration enthält **keinen** App-Menüeintrag, **keine** Play-AAB, **keine** Aktualisierung von `main` oder PR #3, **keine** Änderung der existierenden Paketnamen und **keine** Google-Play-Veröffentlichung. Testszene im eigenen Branch.
