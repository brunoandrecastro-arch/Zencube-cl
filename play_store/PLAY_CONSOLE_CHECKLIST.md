# ZenCube 3D – Play Console Checkliste (11/2026)

## Bereits vorbereitet
- [x] Play-Exportprofil mit `com.zencube.game.play`, Version `2.3`, Versionscode `23`
- [x] Build ohne Signatur über **Actions → Google Play unsigned AAB** oder `bash scripts/build_play_aab.sh`
- [x] Deutsche und englische Store-Texte und Versionshinweise
- [x] Minimalistisches Icon 512×512 RGBA und Android-Launcher-/Adaptive-Icons
- [x] Feature Graphic 1024×500 RGB
- [x] Fünf Originaltracks im Quellcode; Musikumschaltung
- [x] Fünf Bot-Stufen, 100 Challenges, 20 Skins, Welten, Zen Ascension und Offline-Modus bleiben erhalten
- [x] Separates Exportprofil `Android Play` mit Godot 4.5.1, Gradle, minSdk 26 und targetSdk 36

## Geschlossener Test

Der vorhandene Alpha-Track in Google Play gehört zu `com.zencube.game.play`. Sein letzter veröffentlichter Versionscode ist `4` (Version `2.2`). Das Exportprofil **Android Play** verwendet die Paket-ID dieses Eintrags. Der Debug-Build verwendet `com.zencube.game`.

- [x] Paket-ID des bestehenden Alpha-Tracks im Play-Exportprofil hinterlegt
- [ ] Höchsten in der Play Console hinterlegten Versionscode prüfen und `version/code` bei Bedarf erhöhen
- [ ] Auf dem eigenen Rechner das AAB mit dem aktiven Upload-Schlüssel signieren, siehe [Lokale Signierung](#lokale-signierung)
- [ ] Im bestehenden Track **Testen und veröffentlichen → Test → Geschlossener Test → Alpha → Neuen Release erstellen** das signierte AAB hochladen, Versionshinweise einfügen und den Release zur Prüfung einreichen
- [ ] Auf Android über Google Play von `2.2` aktualisieren und Spielstand, Spracheinstellung sowie Shop-Besitz nach dem Update prüfen

## Lokale Signierung

Den SHA-256-Fingerabdruck des öffentlichen **Upload-Zertifikats** in der Play Console unter **Mit Google Play geschützt → Play App-Signatur verwalten** kopieren. Lokal in PowerShell mit installiertem JDK und [bundletool 1.18.3](https://github.com/google/bundletool/releases/tag/1.18.3) ausführen. Die Beispielpfade, den Alias und den Fingerabdruck durch die eigenen Werte ersetzen.

```powershell
.\scripts\Sign-PlayBundle.ps1 -Bundle .\build\ZenCube-3D-unsigned.aab `
  -Keystore 'C:\Pfad\zum\upload-keystore.jks' -Alias 'DEIN_ALIAS' `
  -Bundletool 'C:\Pfad\zu\bundletool-all-1.18.3.jar' `
  -ExpectedUploadSha256 'SHA256_AUS_PLAY_CONSOLE' -LastPlayVersionCode 4
```

`jarsigner` fragt das Kennwort lokal ab. Das Skript prüft Paket-ID, Versionscode und das tatsächlich genutzte Zertifikat und erzeugt `ZenCube-3D-signed.aab` neben der Eingabedatei. Keystore und Kennwort bleiben auf dem eigenen Rechner.

## Voraussetzungen für einen lokalen Build

Linux mit Python 3.11 oder neuer, OpenJDK 17, Godot 4.5.1 Stable und dessen offiziellen Exportvorlagen. Im Android SDK werden Platform 36, Platform-Tools, Build-Tools 35.0.0 und 36.0.0 sowie NDK 28.1.13356709 benötigt. `JAVA_HOME`, `ANDROID_HOME`, `GODOT` (falls nicht im `PATH`) und `BUNDLETOOL_JAR` setzen. Danach `bash scripts/build_play_aab.sh` aus dem Projekt ausführen.

## Für einen späteren Produktionsrelease
- [ ] GitHub-CI inklusive Godot-Tests für diesen Patch grün
- [ ] Echte Handy-Screenshots aus finalem Build aufnehmen (mindestens zwei, erforderliche Formate prüfen)
- [ ] Datenschutzentwurf prüfen, Support-E-Mail festlegen, Datenschutzseite öffentlich per HTTPS bereitstellen
- [ ] Play Console: Data safety, Altersfreigabe/Content Rating, Zielgruppe, App-Zugriff, Werbung, öffentliche Kontaktangaben ausfüllen
- [ ] Play Console: prüfen, ob persönliches Entwicklerkonto die 12-Tester/14-Tage-Regel erfüllen muss
- [ ] Tester einladen, Testfeedback und Crashes auswerten
- [ ] Veröffentlichung **erst nach ausdrücklicher Freigabe**

## Release-Dateien
- `zencube_store_icon_512.png` (512×512)
- `zencube_feature_1024x500.png` (1024×500)
- `STORE_LISTING_EN_DE.md`, `RELEASE_NOTES_EN_DE.md`, `PRIVACY_POLICY_DRAFT_EN_DE.md`

## Hinweis zu Echtgeld und Multiplayer
Der interne Shop nutzt ausschließlich erspielte Blätter; Online-Multiplayer ist nicht in 1.0 enthalten. Nicht als Play-Funktion beschreiben.
