# ZenCube v4 – Abnahmecheckliste

## Nur mit echter App / APK abnehmen
- [ ] Erste Installation: Zen-Garten-Hintergrund sichtbar; echtes interaktives Würfelmodell; Bot-Start leicht als erste Wahl
- [ ] Tutorial: nebeneinanderliegende echte 3×3-Flächen, 3+1 und 2+2. Kein Sieg mit weniger als vier Steinen.
- [ ] Tippen auf Feld setzt **exakt einen** Stein.
- [ ] Fingerziehen dreht Würfel **ohne Steinsetzung**.
- [ ] Pinch zoomt; keine versehentlichen Züge.
- [ ] Menüs reagieren auf Android: Hauptmenü, Einstellungen, Fertig, neue Partie, Bestätigung, lokales Spiel, Tutorial.
- [ ] Nach Neue Partie: alle 54 Felder frei, Zug 1, Statistik unverändert, keine Gewinnmarkierungen.
- [ ] Bot Leicht spielt legale Züge und demonstriert Regeln; ggf. Schwierigkeit in Einstellungen ändern.
- [ ] 3+1, 2+2 und 1+3 gewinnen über direkt benachbarte Seiten (genau 108). 3er/gleiche Seite gewinnen nie.
- [ ] Android im Hochformat; visuelle Buttons lassen sich mit Daumen bedienen; kein unlesbarer Text.
- [ ] Zen-Musik sanft und deaktivierbar; App funktioniert offline.
- [ ] Ein vollständiges Spiel gegen Bot und ein lokales Spiel auf dem echten Gerät abschließen.

## CI
- Python `tests/test_108_rules.py` erfolgreich.
- Godot Projektimport, `test_engine.gd`, `test_ui.gd` erfolgreich.
- APK nach erfolgreichem Export signaturgeprüft und als Artefakt verfügbar.
- Echtes Gerätescreenshot mit `docs/approved_ui_reference.png` visuell abgleichen.

## Bekannte Risiken
- Das Designreferenzbild ist keine UI-Textur. Die echte appnahe Oberfläche ist eine Mischung aus generiertem Hintergrund, interaktiven Buttons und Echtzeit-3D. **Pixelgenaue Übereinstimmung nicht behaupten.**
- Die 108 Viererlinien wurden kombinatorisch geprüft; vollständige faire Spielstrategie ist nicht bewiesen.
- Headless-CI kann manche Multitouch-/Grafikprobleme auf echten Geräten nicht entdecken.
