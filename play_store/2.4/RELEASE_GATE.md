# ZenCube 3D 2.4 · Freigabestand

Ausgangsstand: `5b40565e12d61eff7c3cccefad5d7cfd751a743e`, erfolgreicher UI-Test-Run `44152357357`.
Dieser Stand enthält zehn Commits nach dem unveränderten Tag `zencube-3d-2.0-final`.
Play-Branch: `release/play-2.4-2026-11-17`. PR #3 und #5 bleiben Entwürfe.

## Build

- Exakt Godot 4.5.1; vorhandenes Exportprofil **Android Play**; `--export-release`.
- Bestehende Paketkennung `com.zencube.game.play`, App-Name **ZenCube 3D**.
- Version **2.4**, vorläufiger versionCode **24**. Der Prüfbericht vom 16.11. bestätigt Alpha 2.3 mit Code 23. Der aktuelle Höchstwert über alle Play-Tracks und hochgeladenen Bundles ist vor dem Signieren erneut zu prüfen. Falls bereits Code 24 oder höher verwendet wurde: Profil erhöhen und das AAB neu bauen.
- Android 7.0 / API 24 bleibt unterstützt; Target API 36; ARM64 und x86_64; OpenGL ES 3.0. Die irrtümlich aus dem UI-Branch übernommene Mindest-API 26 wurde korrigiert.
- Der Export ist absichtlich **unsigniert**. Kein vorhandener privater Upload-Schlüssel wurde angefordert oder verarbeitet. Es wird kein neuer Upload-Schlüssel erzeugt.
- Normale Freischaltung: Zen-Meister oder bereits bestehender Kauf für 850 erspielbare Zen-Blätter. Keine Test-Freischaltung; weitere Realms benötigen die regulären Aufgaben und Story-Bosse.

## Vor Signierung und Upload offen

1. In der bestehenden Play Console den **höchsten verwendeten versionCode** im App Bundle Explorer über alle Tracks prüfen. Er muss kleiner sein als der Code dieses AAB.
2. Den SHA-256-Fingerabdruck unter **Upload-Zertifikat** ablesen. Es muss das nach dem Reset am 12.11.2026 bestätigte Zertifikat sein. Nicht mit dem App-Signaturzertifikat verwechseln.
3. Das AAB lokal mit genau diesem vorhandenen Upload-Schlüssel signieren. Das vorhandene `scripts/Sign-PlayBundle.ps1` verlangt beide Werte, prüft Manifest, Release-Modus, Signatur und Zertifikatsfingerabdruck und fragt das Passwort nur lokal über `jarsigner` ab.
4. Ein echtes Update von Play Alpha 2.3 auf den neuen Build mit bestehendem Spielstand prüfen: Sprache, Namen, Classic-Partie, Challenges, Rang, Shop-Besitz und Wallet. Die Play-App dazu **nicht deinstallieren**. Eine separate UI-Test-App hat einen getrennten Datenspeicher.
5. Android-Geräteprüfung für Touch-Scrollen, Dropdowns, Bildschirmtastatur, Portrait-Zuschnitt, Audio und Framerate. Automatische Godot-Tests ersetzen diese Geräteprüfung nicht.

Die automatische Browser-Zugriffsprüfung blockierte in dieser Sitzung den Aufruf der Play Console wegen einer abweichend bewerteten Domain. Deshalb sind der aktuelle Bundle-Explorer, das registrierte Upload-Zertifikat und das Speichern der Store-Texte in der Console nicht bestätigt.

## Lokale Signierung auf Windows

JDK und bundletool bereithalten. Werte aus der aktuellen Console verwenden; keine Passwörter in den Befehl schreiben:

```powershell
.\Sign-PlayBundle.ps1 -Bundle .\ZenCube-3D-2.4-unsigned.aab `
  -Keystore 'C:\Pfad\zum\BESTAETIGTEN-upload-keystore.jks' `
  -Alias 'DEIN_ALIAS' -Bundletool 'C:\Pfad\zu\bundletool-all-1.18.3.jar' `
  -ExpectedUploadSha256 'UPLOAD_SHA256_AUS_DER_CONSOLE' `
  -LastPlayVersionCode HOECHSTER_AKTUELL_VERWENDETER_CODE
```

Bei einem bereits verwendeten Code oder abweichendem Zertifikat stoppt das Skript. Nicht die Prüfungen entfernen. Private Schlüssel und Passwörter bleiben auf dem eigenen Gerät.

## Store

Die Texte in diesem Ordner sind fertige **Datei-Entwürfe** für DE, EN und PT-PT. Titel exakt **ZenCube 3D**; Kurzbeschreibungen unter 80, Volltexte unter 4.000 Zeichen. Die Locale-Dateien sind getrennt abgelegt. Es wurde nichts in der Console gespeichert, zur Prüfung eingereicht oder veröffentlicht.

Die neue Beschreibung bewirbt Funktionen der Version 2.4. Da der Store-Eintrag gemeinsam für alle Tracks gilt, darf dieser Entwurf nicht vor der dazugehörigen App-Version veröffentlicht werden. Bestehende Kontaktangaben, Datenschutzerklärung und Store-Grafiken wurden nicht geändert.

## Prüfen

```bash
GODOT=/pfad/zu/Godot_v4.5.1-stable_linux.x86_64 python3 scripts/run_release_checks.py
bash scripts/build_play_aab.sh
```

Der Play-Workflow läuft auf diesem separaten Release-Branch. Er prüft alle vorhandenen CI-Regressionsskripte unabhängig von UI-Test-Branchbedingungen sowie die Alpha-Spielstand-Kompatibilität. Anschließend prüft er das reale AAB mit bundletool, Manifest, 16-KB-Ausrichtung der nativen Bibliotheken, Bildern, Rohdaten und allen zwölf Boss-Tracks.

Offene Geräte- und Console-Prüfungen sind **Freigabeblocker**, bis ihr Ergebnis dokumentiert ist. Das AAB ist ein technisch prüfbarer Release-Kandidat; es ist noch kein freigegebener Google-Play-Release.
