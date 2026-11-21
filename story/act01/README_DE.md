# Zen Chronicles – Akt I: Zen-Meister als Abschlussboss

Dieses Paket enthält die zwölf fertigen Originalseiten von Akt I, die vom Nutzer gelieferte Charakterreferenz und die konkrete Zuordnung für einen spielbaren Abschlusskampf. Es ist ein Vorbereitungspaket; es enthält keinen bereits eingebauten oder getesteten App-Patch und keine neu erzeugten Bossillustrationen.

## Ablauf

1. Seiten 01–11 lesen. Die auf Seite 11 dargestellte Niederlage bleibt das erste Lehrduell gegen den Meister.
2. Vor Seite 12 unterbrechen. Boss-Dialog: “Before you go, one more game. Show me what you have learned.”
3. Einen echten klassischen 3×3-Kampf gegen “The Zen Master” starten. Ein Sieg genügt. Die Schwierigkeit bleibt leicht und wohlwollend; kein Zeitlimit.
4. Bei Niederlage oder Remis freundlich denselben Gegner erneut anbieten. Frühere Seiten und Fortschritt bleiben erhalten. Seite 12 bleibt gesperrt.
5. Erst nach tatsächlichem Spielersieg den Dialog “Well played, Kuze. Take the cube home. Return tomorrow.” zeigen.
6. Danach Seite 12 mit der glücklichen Heimkehr, Aiko und dem Versprechen an Shin öffnen. Der folgende Akt gehört zum Bamboo Path.

Das erste Lehrduell und die anschließende spielbare Prüfung sind zwei verschiedene Partien. Der im Comic gezeigte Sieg des Meisters ist kein festgeschriebener Ausgang für den echten Bosskampf.

## Darstellung

Der Meister bleibt der freundliche ältere Lehrer aus Akt I: kahle Kopfkrone, weiße Seitenhaare, weiße Brauen, langer schmaler weißer Bart, sandfarbener Kimono und braunes Obergewand. Die Referenz wurde unverändert übernommen. Sie zeigt Kuze und den Meister gemeinsam und ist kein neu erstelltes hochauflösendes Einzelporträt.

Für die spätere Arena die vertraute warme Tempelhalle mit offenem Zen-Garten verwenden. Kein vorgezeichneter Würfel im Arena-Hintergrund, keine weiteren Figuren, keine dunkle Verwandlung und keine 4×4-Elemente.

## Technische Zuordnung

Die Datei `zen_master_trial.json` beschreibt die Seiten-Sperre, Dialoge, Schwierigkeit und Speicherregeln. Sie muss beim Einbau ausdrücklich mit dem neuen Akt-I-Manhwa-Reader und dem vorhandenen klassischen 3×3-Spiel verknüpft werden. Sie wird vom aktuellen Spielcode nicht automatisch geladen.

Verwende einen eigenen Speicherbezeichner für diesen neuen Akt. Bestehende Classic-, bisherige Kampagnen- und 4×4-Spielstände nicht überschreiben. Sieg und eventuelle Belohnung einmalig speichern. Nach App-Neustart vor oder während der Prüfung korrekt fortsetzen.

## Noch offen

- Anschluss an den neuen Akt-I-Reader und an das echte 3×3-Spiel.
- Prüfung auf Android: Lesesperre, Spielersieg, Niederlage, Remis, Wiederholung und Wiederaufnahme.
- Neues Einzelporträt und eigenständige Arena. Die Bildgenerierung war beim Erstellen dieses Pakets durch das Tageslimit blockiert; als Rücksetzzeit wurde 20.11.2026, ca. 17:52 Uhr deutscher Zeit gemeldet.

An Repository, Godot-Projekt, App und Google Play wurden für dieses Vorbereitungspaket keine Änderungen vorgenommen.
