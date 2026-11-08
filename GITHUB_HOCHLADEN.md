# ZenCube auf GitHub laden und APK bauen

## WICHTIG: Eine ZIP auf GitHub hochladen genügt nicht

GitHub **entpackt keine hochgeladene ZIP**. Du musst sie zuerst entpacken und anschließend **alle Dateien und Ordner aus dem ZIP-Stammverzeichnis** ins Repository legen, einschließlich `.github/workflows/android.yml`. Am einfachsten geht das mit Termux oder GitHub Desktop.

## Auf dem Samsung mit Termux (empfohlen)

1. Neues, **leeres** GitHub-Repository `ZenCube-3D` im Browser anlegen (ohne automatisch erstelltes README).
2. `ZenCube_3D_GitHub_Ready.zip` in den Download-Ordner speichern.
3. Termux starten:

```sh
termux-setup-storage
pkg install -y git unzip python
mkdir -p ~/zencube-github
cd ~/zencube-github
unzip -o ~/storage/downloads/ZenCube_3D_GitHub_Ready.zip
python tests/test_108_rules.py
git init
git add .
git commit -m "ZenCube 3D Zen Garden: game, UI, rules and Android CI"
git branch -M main
git remote add origin https://github.com/DEIN_GITHUB_NAME/ZenCube-3D.git
git push -u origin main
```

Ersetze `DEIN_GITHUB_NAME` durch deinen GitHub-Namen. GitHub verlangt für HTTPS-Push eine gültige Anmeldung (z. B. einen Personal Access Token, nicht dein GitHub-Kontopasswort). Die PIN bzw. den Token niemals im Chat oder Repository veröffentlichen.

## GitHub-Actions-Test-APK

1. In deinem Repository **Actions** öffnen.
2. Workflow **Android debug APK** auswählen.
3. **Run workflow** anklicken, Branch `main`.
4. Den Build-Log prüfen: Projektimport, Regeltests, Engine-/UI-Tests und Export.
5. Nach grünem Lauf unter **Artifacts** `ZenCube-3D-debug` herunterladen. Darin liegt `ZenCube-3D.apk`.

**Wichtig:** Ein grüner Build bestätigt nicht automatisch, dass alle Touchgesten auf einem echten Handy funktionieren. Diese müssen separat getestet werden. Die Debug-APK wird bei jedem CI-Lauf mit einem neuen Debug-Schlüssel signiert; bei Installationskonflikten zunächst die alte APK deinstallieren (vorher Spielstände sichern). Die APK ist kein Google-Play-Release.

## Mit ChatGPT Work

Nutze die Datei `WORK_AUFTRAG.md` im Root des Repositories. Work soll den tatsächlichen CI-Build anstoßen, Fehler beheben, die APK erzeugen und **das visuelle Ergebnis mit `docs/approved_ui_reference.png` vergleichen**.

## Lokaler Test ohne Godot

```sh
python3 tests/test_108_rules.py
```

Alle Godot-Tests und der Android-Build benötigen zusätzlich die passende Engine.
