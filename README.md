# ZenCube 3D – Zen Garden Edition · GitHub-Quellprojekt

Ein offlinefähiges Android-Strategiespiel auf der Oberfläche eines rotierbaren Würfels: **6 Seiten × 3×3 Felder = 54 Felder**. Gewinn mit **vier Steinen über zwei benachbarte Würfelseiten**: 3+1, 2+2 oder 1+3. Genau **108** eindeutige Gewinnlinien.

## Was enthalten ist

- Vollständiger Godot-4.5.1-GDScript-Quellcode: 3D-Würfel, UI, Spielregeln, Computergegner in drei Stufen, lokaler Zwei-Spieler-Modus, Tutorial, Statistik, Speichern, Einstellungen.
- Neue Zen-Garten-Hintergrundgrafik `assets/zen_garden_scene.webp`, warmer Holzwürfel, Terrakotta-/Salbei-/Sandflächen, responsive Godot-Buttons und ein eigenes kurzes Ambient-Audio (`assets/zen_ambient.wav`, optional/abschaltbar).
- Das vom Nutzer bestätigte Referenzbild unter `docs/approved_ui_reference.png` dient zur **visuellen Feinabstimmung**. Es ist nicht als inaktive UI-Fototextur verbaut.
- Erststart mit Willkommensdialog, 3+1-/2+2-Tutorial und **Bot auf Leicht**; nicht zunächst gegen Spieler 2.
- GitHub Actions: `.github/workflows/android.yml` erstellt nach erfolgreichem Test eine Debug-APK als GitHub-Artefakt.
- Testcode: 108 Linien, 24 Rotationen, Stichproben-Partien, Godot Engine, UI und Touch-Ereignissimulation.

## Status

**Dies ist ein GitHub-fertiges Quellprojekt, noch keine nachweislich auf Android getestete fertige APK.** In dieser Arbeitsumgebung ist kein Godot-Editor vorhanden. Ausgeführt wurde `python3 tests/test_108_rules.py` (erfolgreich); der Godot- und Android-Build muss über die beiliegende GitHub-Actions-Pipeline stattfinden. Die Oberfläche soll dem freigegebenen Bild entsprechen, ist aber noch nicht pixelgenau mit einem echten Geräte-Screenshot verifiziert.

## Start & Upload

Siehe **`GITHUB_HOCHLADEN.md`**. GitHub entpackt keine ZIP automatisch.

## Tests

```sh
python3 tests/test_108_rules.py
# Mit lokal installierter kompatibler Godot-Engine:
godot --headless --editor --import --quit
godot --headless --script tests/test_engine.gd
godot --headless --script tests/test_ui.gd
```

## Ordner

- `Main.tscn`, `project.godot`: Godot-Projekt
- `ui/`: GameController (interaktive Oberfläche), Würfelrenderer, Eingabesteuerung, Tutorial
- `core/`: Geometrie, 108 Gewinnlinien, Regeln, KI, Spielzustand, Speichern
- `assets/`: Zen-Garten-Szene und Musik
- `docs/approved_ui_reference.png`: vom Auftraggeber freigegebene UI-Gestaltungsreferenz, **nicht** statisch als App-Bildschirm verwendet
- `tests/`: Regressionstests
- `.github/workflows/android.yml`: Android CI
- `WORK_AUFTRAG.md`: direkter Auftrag an ChatGPT Work

## Lizenzen

Siehe `LICENSE`, `assets/ASSET_LICENSES.md`, `GODOT-LICENSE.txt` und `GODOT-THIRD-PARTY.txt`.
