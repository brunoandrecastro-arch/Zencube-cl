# ZenCube 3D – Changelog v3 Zen Garden

## Implementiert

- Neue, helle originale Zen-Sand-Hintergrundgrafik mit geharkten Linien und Steinen
- Cremige Karten, salbeigrüne Primärschaltflächen und warme Holz-/Terrakottatöne
- Willkommen/Tutorial mit sichtbaren 3+1- und 2+2-Beispielen
- Erster Standard-Spielstart gegen Zen-Bot auf Leicht
- Lokales Spiel weiterhin im Menü; zusätzlich freies Training
- Exakt 108 gültige Viererlinien (3+1, 2+2, 1+3)
- KI-Sieg-/Blockbewertung für vier Felder
- Gewinner-Markierung über vier auf der Oberfläche verbundene Felder
- Touch-Antippen nur bei gleicher Start-/Endzelle ohne Drag
- Menükonzept: Schnellstart, Gegen Bot, Lokal, Training, Einstellungen, Tutorial, Statistik
- Getrennte Siegstatistik nach Start-/Zweitspieler
- Spielstände aus alter Regelversion bewusst zurückgesetzt
- GDScript-Testskripte überarbeitet; unabhängiger Python-Test und Simulation durchgeführt

## Nicht bestätigt

- GDScript-Kompilierung / Godot-Laufzeit
- Funktion der Menüs per echter Android-Touchinteraktion
- Neue installierbare APK und tatsächlicher Android-Build

## Was die Spieltester zuerst prüfen sollen

1. Wird beim ersten Start statt einer lokalen 2-Spieler-Partie das Willkommensfenster geöffnet?
2. Zeigt es 3+1 und 2+2 verständlich an?
3. Funktioniert der Start gegen Zen-Bot · Leicht?
4. Kann man drehen, ohne eine Markierung zu setzen?
5. Funktionieren **Menü → Einstellungen → Zurück** und **Neue Partie**?
6. Stimmt die Siegprüfung bei 3+1, 2+2 und 1+3?
7. Werden keine Dreierreihen irrtümlich als Sieg anerkannt?
8. Sind alle Flächen optisch beige/braun, ohne alte Neonfarben?
