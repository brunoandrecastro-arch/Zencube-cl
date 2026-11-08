# ZenCube 3D – Sprach- und Musikupdate (v5.1)

## Neu
- Einmaliger Sprachauswahldialog beim ersten Start: Deutsch / English, auch bei bereits installierten älteren Builds.
- Sprache jederzeit unter **Einstellungen / Settings → Sprache / Language** ändern.
- Sämtliche Buttons, Tutorialtexte, Spielmeldungen, Statistiken, Spielregeln und Würfelseiten sind auf Deutsch und Englisch verfügbar.
- Die Sprache bleibt nach App-Neustart erhalten; vorhandene Partie, Statistik und Spielregeln (108 Viererlinien) bleiben bestehen.
- Die bisherige 24-Sekunden-Zen-Ambient-Audiodatei war sehr leise (-33.6 dBFS RMS) und wurde darüber hinaus um -28 dB abgesenkt. Neu: WAV ca. -17.4 dBFS RMS, Wiedergabe -12 dB in der App.
- Für neue Installationen ist Zen-Musik anfangs eingeschaltet. Für bestehende Nutzer bleibt die gespeicherte Ein/Aus-Präferenz erhalten.
- In Einstellungen: **Musikprobe abspielen / Play music sample** (6 Sekunden, wenn Musik normalerweise ausgeschaltet ist).

## Tests
- `python tests/test_108_rules.py`: 108 Gewinnlinien, 24 Rotationen, 3.000 Simulationen erfolgreich.
- `python tests/test_language_audio.py`: 107 Übersetzungseinträge, keine Tab-Einrückung im Controller, WAV-Pegel und Steuerung erfolgreich.
- GitHub Actions erhält zusätzlich einen Godot-Headless-Test zum Sprachwechsel sowie Musikkontrollchecks.
- Ein echtes Anhören und die Touchbedienung auf Android sind nach Erzeugung der APK noch zu überprüfen.

## Installation
Das Update-ZIP enthält nur geänderte/zusätzliche Dateien. Im Hauptverzeichnis des bestehenden Git-Repositories entpacken und committen.
