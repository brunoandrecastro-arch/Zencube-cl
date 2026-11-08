# WORK: ZenCube 3D – GitHub- und Android-Abnahmeauftrag

**Projektbasis:** Dieses Repository ist ein existierendes, bearbeitbares Godot-4.5.1-Projekt. Bewahre die 54-Felder-Würfelgeometrie, 108 Vierergewinnlinien, Screens, Bot und SaveManager. Dies ist keine Bild-only-Demo.

**Auftrag:** Öffne das bestehende Repository, führe die Godot-Engine-/UI-Tests aus, behebe auftretende GDScript-, Godot-, Input- und Exportfehler, und liefere eine tatsächlich installierbare, getestete Android-Debug-APK. Erstelle keine von Grund auf neue App und gib nicht bloß die alte APK zurück.

**Designabnahme:** `docs/approved_ui_reference.png` zeigt die vom Auftraggeber freigegebene gestalterische Richtung (Zen-Garten, Kirschblüten, Wasserfall, Laterne, Holzwürfel). `assets/zen_garden_scene.webp` ist der neue Hintergrund **ohne** eingebackene Buttons. UI und Würfel müssen als echte interaktive Godot-Controls/3D-Objekte implementiert bleiben; verwende den Referenz-Screenshot nie als klickbare Gesamtoberfläche.

**Spielregeln:** 6×3×3=54 Zellen. Nur gerade Viererlinien, die genau eine angrenzende Würfelkante überschreiten. Erlaubt 3+1 / 2+2 / 1+3; genau 108 Linien. 3er oder 4 auf einer einzelnen Fläche gewinnen nicht. Alle 24 Würfelrotationen müssen dieselben Linien ergeben. 1 Stein pro Halbzug. Prüfe die Fairness, aber behaupte keine perfekte Balance ohne Beweis.

**UX:** Erststart führt visuell die 3+1- und 2+2-Beispiele aus je zwei 3×3-Flächen vor, anschließender Bot-Einstieg auf Leicht. Achte auf korrektes Feldkoordinaten-Mapping, keine versehentlichen Steinsetzungen beim Drag, kein Tap-Event durch Menüs, funktionierende Buttons (insbesondere Neue Partie, Bestätigung, Zurück, Einstellungen).

**Build/QA:** Nutze `.github/workflows/android.yml`. Prüfe `python3 tests/test_108_rules.py`, danach `godot --headless --editor --import --quit`, `godot --headless --script tests/test_engine.gd` und die UI-Test-Suite `tests/test_ui.gd` (grafische Screenshots falls verfügbar). GitHub Actions muss die Debug-APK im Artefakt `ZenCube-3D-debug` bereitstellen. Prüfe auf einem Android-Emulator oder Gerät und dokumentiere, was real getestet wurde.

**Lieferung:** 1) getestete APK 2) Commit aller Fixes im Repository 3) kurze Liste geänderter Dateien 4) Screenshots der tatsächlich gerenderten Godot-Oberfläche 5) Ergebnis von Menü-, Gameplay-, Touch- und KI-Tests 6) offene Punkte ehrlich benennen. Falls Android-Build unmöglich: konkrete Fehlermeldungen und lauffähige Reparaturanleitung, keine Erfolgsmeldung vortäuschen.

**Reihenfolge:** Godot-Start/Tests → Funktionalität (Menüs) → Android-Build → visuelle Feinabstimmung anhand der freigegebenen Referenz → finale Test-APK. Arbeite so weit wie die verfügbaren Werkzeuge es zulassen selbstständig.
