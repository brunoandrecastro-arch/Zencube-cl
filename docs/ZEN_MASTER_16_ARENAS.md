# Zen Master 5×5 – Eigene Boss-Arenen (verbindliche Bildregeln)

**Verbindliche Vorgabe:** Jeder der 16 Kämpfe bekommt ein *eigenes Hintergrundbild*; ein Realm-Bild, das bei vier Bossen einfach wiederverwendet wird, ist **nicht ausreichend**. Ein Boss-Porträt ersetzt **niemals** den Kampfhintergrund. Alle Bilder müssen zur Farbwelt, Geschichte und Architektur des jeweiligen Realms passen.

Die Produktionspfade sind in `core/ZenMasterStageCatalog.gd` festgeschrieben. **Wichtig:** Diese Pfade sind aktuell Reservierungen – die 16 individuellen Hintergrunddateien sind noch **nicht** im Repository importiert. Die bisher gezeigten Realm-Poster sind Konzeptgrafiken, keine fertigen eigenständigen Arena-Assets. Die geplante Kampagne darf erst als visuell fertig gelten, wenn `ZenMasterStageCatalog.all_arena_art_imported()` wahr wird und jeder Hintergrund auf Android sichtbar getestet wurde.

| Realm | Boss | Eigenständige Arena | Look / Dramaturgie |
| --- | --- | --- | --- |
| Void Sanctuary | The Nameless Ronin | **The Forgotten Dojo** | Verlassenes Dojo, zerbrochenes Torii, violetter Nebel |
| Void Sanctuary | The Weeping Oracle | **Lake of Unspoken Tears** | Überfluteter Schrein, Spiegel und schwarze Tränen |
| Void Sanctuary | The Void Executioner | **The Chained Gate** | Dunkles Festungstor, Ketten und Abgrund |
| Void Sanctuary | **The Hollow Abbot** | **Sanctum of Holy Emptiness** | Schwebende Sutren, zerbrochener Heiligenschein, stiller Tempel |
| Moonlit Garden | The Silver Kitsune | **Nine-Tail Lantern Grove** | Mondbeschienener Bambushain und Fuchsfeuer |
| Moonlit Garden | The Petal Dancer | **Petalfall Pavilion** | Offener Blütenpavillon mit tanzenden Kirschblüten |
| Moonlit Garden | The Moonless Knight | **Garden of the Eclipsed Moon** | Verlassene Brücke unter schwarzem Mond |
| Moonlit Garden | **Tsukihana** | **Temple of the Last Blossom** | Mondwasserfall und Blütenthron |
| Astral Monastery | The Comet Guardian | **Falling-Star Causeway** | Sternschnuppen über schmaler Himmelsbrücke |
| Astral Monastery | The Silent Astronomer | **Observatory of Hidden Patterns** | Sternwarte mit riesigem Astrolabium |
| Astral Monastery | The Keeper of Seven Stars | **Seven-Star Trial** | Sieben leuchtende Säulen im Kosmos |
| Astral Monastery | **The Star-Bell Master** | **Belfry of a Thousand Rings** | Goldenes Glockenkloster und Sternenmandala |
| Origin Realm | The Forgotten Self | **Gallery of Lost Names** | Galerie verwitterter Erinnerungs- und Spiegelbilder |
| Origin Realm | The Eternal Judge | **Tribunal of First Light** | Lichthof mit kosmischer Waage |
| Origin Realm | The Mirror of Kuze | **Hall of Two Selves** | Endlose Spiegelhalle – Licht gegen Schatten |
| Origin Realm | **The First Witness** | **Before the First Dawn** | Ursprungskubus am Übergang zwischen Licht und Finsternis |

## Export- und UX-Regeln

- Jedes Kampfbild kommt in einem **boss-spezifischen** `.webp`-Pfad und wird individuell abgenommen.
- Für Android: Hochformat, wichtige architektonische Motive im zentralen Sichtfeld; Würfel und X/O bleiben kontraststark und vor dem Bild gut lesbar.
- Hintergrund helligkeitsreduziert/abgedunkelt hinter dem 3D-Würfel, damit die Spielzüge im Vordergrund bleiben.
- Eigenes Boss-Porträt im Intro; eigener Hintergrund im tatsächlichen Match; individuelle Besiegten-Grafik bzw. -Animation für den Übergang.
- Finale Arena pro Realm deutlich monumentaler als die drei davor; Übergang zum nächsten Realm mit eigener Licht-/Glassplitter-Farbgebung.
- **Weiterhin 4 GEWINNT auf 5×5**, auch bei Bosskämpfen (348 korrekte Linien); kein Boss darf die Viererregel verändern.
- Keine neue Google-Play-Veröffentlichung, kein Main-Merge, kein Eingriff in PR #3. Experiment nur auf `prototype/zen-master-5x5`.

Die 16 Arenen sind derzeit **designseitig benannt und im Code referenziert, nicht fertig illustriert und nicht in der Test-APK aktiv**.
