# ZenCube 3D – Play Console Checkliste (11/2026)

## Bereits vorbereitet
- [x] App-ID `com.zencube.game` bleibt stabil
- [x] Version 1.0.0-rc1 / Version Code 20 im Projekt angelegt (bei früheren Play-Testuploads ggf. Code erhöhen)
- [x] Deutsche und englische Store-Texte und Versionshinweise
- [x] Minimalistisches Icon 512×512 RGBA und Android-Launcher-/Adaptive-Icons
- [x] Feature Graphic 1024×500 RGB
- [x] Fünf Originaltracks im Quellcode; Musikumschaltung
- [x] Fünf Bot-Stufen, 100 Challenges, 20 Skins, Welten, Zen Ascension und Offline-Modus bleiben erhalten
- [x] Separater Export-Preset `Android Play`: AAB, Gradle, minSdk26, targetSdk36 **konfiguriert, noch nicht gegen signiertes Bundle verifiziert**

## Vor dem Play-Upload zwingend offen
- [ ] GitHub-CI inklusive Godot-Tests für diesen Patch grün
- [ ] Migration / Export auf Godot 4.7.2 und Build-Template erfolgreich getestet (4.5.1-Debug-Pipeline allein reicht nicht)
- [ ] **Signiertes AAB** erzeugt und Ziel-API 36 am tatsächlichen Bundle geprüft
- [ ] Upload-Key privat sichern; **keine** keystore-Dateien oder Kennwörter einchecken
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
