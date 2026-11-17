class_name ZenMasterCampaignData
extends RefCounted

# Independent QA campaign story. Four realms, four bosses each, no Play saves affected.
const REALMS: Array[Dictionary] = [
    {"id":"void_sanctuary","name":"Void Sanctuary","chapter":"Die Prüfung der Leere","intro":"Hinter den Eissplittern aus Satori entdeckt Kuze einen Tempel, in dem Namen und Angst verschwinden.","palette":"Dunkelviolett"},
    {"id":"moonlit_garden","name":"Moonlit Garden","chapter":"Die Prüfung der Erinnerung","intro":"Nachdem Kuze Stille ausgehalten hat, stellt der Mondgarten ihm die Frage, was er wirklich bewahren möchte.","palette":"Mondrosa"},
    {"id":"astral_monastery","name":"Astral Monastery","chapter":"Die Prüfung der Klarheit","intro":"Auf den Brücken zwischen den Sternen muss Kuze lernen, Muster zu sehen, ohne sie kontrollieren zu wollen.","palette":"Astralblau"},
    {"id":"origin_realm","name":"Origin Realm","chapter":"Die Prüfung des Selbst","intro":"Vor dem ersten Sonnenaufgang wartet keine weitere Welt, sondern die Wahrheit über Kuze selbst.","palette":"Goldweiß"},
]
const BOSSES: Array[Dictionary] = [
    {"id":"nameless_ronin","name":"The Nameless Ronin","subtitle":"Blade Without Memory","realm":0,"rank":0,"opening":"Kuze betritt das vergessene Dojo. Der Ronin hat seinen Namen geopfert, um nie wieder eine Niederlage zu spüren.","challenge":"Ein Name ist nur eine Fessel. Bist du bereit, deinen loszulassen?","victory":"Der Ronin steckt sein Schwert weg. Kuze erkennt: Identität entsteht nicht aus einem einzigen Sieg.","wisdom":"Eine Klinge ohne Namen kann dennoch ihren Weg finden.","difficulty":1},
    {"id":"weeping_oracle","name":"The Weeping Oracle","subtitle":"Seer of Drowned Doubt","realm":0,"rank":1,"opening":"Am See ungesagter Tränen zeigt eine Seherin Kuze das Gesicht seiner größten Reue in zerbrochenen Spiegeln.","challenge":"Du suchst Gewissheit. Doch was, wenn du dich selbst belügst?","victory":"Kuze akzeptiert die Vergangenheit, ohne sie neu schreiben zu müssen. Das Wasser wird ruhig.","wisdom":"Tränen zeigen nicht nur Schmerz, sondern auch Wahrheit.","difficulty":2},
    {"id":"void_executioner","name":"The Void Executioner","subtitle":"Keeper of the Chained Gate","realm":0,"rank":2,"opening":"Vor dem letzten Tor wartet ein gepanzerter Koloss, der allen Reisenden den Rückweg verwehrt.","challenge":"Hinter mir gibt es keine Rückkehr. Entscheide dich.","victory":"Kuze begreift, dass Mut nicht die Abwesenheit von Angst bedeutet, sondern Handeln trotz ihrer.","wisdom":"Wer die Schwelle betritt, verändert sich.","difficulty":3},
    {"id":"hollow_abbot","name":"The Hollow Abbot","subtitle":"Guardian of Holy Emptiness","realm":0,"rank":3,"opening":"Im schweigenden Heiligtum lehrt der Abt, dass Kuze die Stille weder fürchten noch besitzen darf.","challenge":"Leere ist nicht Nichts. Sie ist der Raum, in dem du dich erkennst.","victory":"Der zersprungene Heiligenschein fügt sich neu. Kuze erhält den Weg zum Mondgarten.","wisdom":"Die Stille war nie dein Feind.","difficulty":4},
    {"id":"silver_kitsune","name":"The Silver Kitsune","subtitle":"Keeper of Shifting Memories","realm":1,"rank":0,"opening":"Neun Fuchsfeuer führen Kuze durch Erinnerungen an Menschen, die er vermisst. Keine Erscheinung lügt – aber keine ist vollständig.","challenge":"Welche Erinnerung würdest du behalten, wenn nur eine bleiben dürfte?","victory":"Kuze versteht, dass Erinnerung kein Gefängnis sein muss.","wisdom":"Wahre Nähe braucht keinen festen Augenblick.","difficulty":4},
    {"id":"petal_dancer","name":"The Petal Dancer","subtitle":"Elegance in Motion","realm":1,"rank":1,"opening":"Auf dem Pavillon der fallenden Blüten fordert eine Tänzerin Kuze zum Spiel zwischen Schönheit und Gefahr.","challenge":"Jede Blüte fällt. Warum hältst du an ihr fest?","victory":"Der letzte Blütentanz endet, ohne dass Kuze ihn festhalten will.","wisdom":"Loslassen ist eine andere Form von Liebe.","difficulty":5},
    {"id":"moonless_knight","name":"The Moonless Knight","subtitle":"The Fallen Reflection","realm":1,"rank":2,"opening":"Unter dem schwarzen Mond wacht ein Ritter, der einst das Licht seines eigenen Schwurs verlor.","challenge":"Ich habe dem Licht gedient, bis ich meinen Schatten vergaß.","victory":"Kuze lernt, dass Dunkelheit nicht immer Schuld bedeutet.","wisdom":"Auch in der Nacht weist ein Schritt den Weg.","difficulty":6},
    {"id":"tsukihana","name":"Tsukihana, The Veiled Bloom","subtitle":"Blade of Beautiful Memory","realm":1,"rank":3,"opening":"Tsukihana öffnet den letzten Blütentempel und zeigt Kuze all das Schöne, das er nur durch Festhalten bewahren wollte.","challenge":"Du darfst lieben, ohne zu besitzen. Beweise es.","victory":"Die Blüten sinken sanft aufs Wasser; der Himmel öffnet den Weg zu den Sternen.","wisdom":"Schönheit bleibt, gerade weil sie vergeht.","difficulty":7},
    {"id":"comet_guardian","name":"The Comet Guardian","subtitle":"Strike of the Falling Sky","realm":2,"rank":0,"opening":"Auf einer schmalen Himmelsbrücke trifft Kuze einen Wächter, dessen Ungeduld wie ein Meteor einschlägt.","challenge":"Wer zögert, verliert den Himmel. Zeig deine Entschlossenheit.","victory":"Kuze lernt den Unterschied zwischen Entschlossenheit und Hast.","wisdom":"Der schnellste Weg ist nicht immer der klügste.","difficulty":9},
    {"id":"silent_astronomer","name":"The Silent Astronomer","subtitle":"Reader of Hidden Patterns","realm":2,"rank":1,"opening":"Ein stummer Sternkundiger dreht uralte Himmelsringe. Er scheint jeden Zug vorherzusehen.","challenge":"Sieh nicht nur den nächsten Zug. Sieh, was er verändert.","victory":"Kuze erkennt das Muster hinter den sichtbaren Sternen.","wisdom":"Geduld macht das Verborgene sichtbar.","difficulty":10},
    {"id":"seven_stars_keeper","name":"The Keeper of Seven Stars","subtitle":"Warden of the Celestial Threshold","realm":2,"rank":2,"opening":"Sieben Säulen leuchten auf; nur eine harmonische Reihe führt durch den Sternenhof.","challenge":"Sieben Sterne prüfen dich. Kann dein Geist still bleiben?","victory":"Kuze bringt die sieben Lichter in Einklang, ohne eines zu beherrschen.","wisdom":"Ordnung wächst aus Aufmerksamkeit.","difficulty":11},
    {"id":"star_bell_master","name":"The Star-Bell Master","subtitle":"Keeper of the Thousand Rings","realm":2,"rank":3,"opening":"Im Glockenturm schwingt der Klang von tausend Möglichkeiten. Der Meister erwartet Kuze ohne ein einziges Wort der Hast.","challenge":"Höre zuerst. Handle dann.","victory":"Mit dem letzten Gong löst sich der Sternenpfad zu einem Spiegel aus Morgenlicht.","wisdom":"Klarheit ist der Klang hinter der Stille.","difficulty":12},
    {"id":"forgotten_self","name":"The Forgotten Self","subtitle":"Echo Before Identity","realm":3,"rank":0,"opening":"Die Galerie vergessener Namen zeigt Kuze die Gestalten, die er hätte werden können. Eine davon steigt aus dem Spiegel.","challenge":"Du hast mich zurückgelassen. Bin ich darum weniger wirklich?","victory":"Kuze wählt keinen der Schatten. Er erlaubt ihnen, Teil seiner Geschichte zu bleiben.","wisdom":"Du bist mehr als deine ungelebten Wege.","difficulty":13},
    {"id":"eternal_judge","name":"The Eternal Judge","subtitle":"Scale of Final Truth","realm":3,"rank":1,"opening":"Der ewige Richter wiegt nicht Siege und Fehler, sondern die Bereitschaft, die Wahrheit anzunehmen.","challenge":"Dein Wert liegt nicht auf meiner Waage. Warum suchst du mein Urteil?","victory":"Die Waage zerfällt zu Licht. Kuze braucht kein fremdes Urteil mehr.","wisdom":"Wahrheit verlangt Mut, keine Erlaubnis.","difficulty":14},
    {"id":"mirror_of_kuze","name":"The Mirror of Kuze","subtitle":"Face of the Inner Enemy","realm":3,"rank":2,"opening":"Ein zweiter Kuze tritt aus dem Spiegel, genauso entschlossen, genauso verletzlich. Er kennt jeden seiner Tricks.","challenge":"Du hast jeden Feind besiegt. Hast du je dir selbst vergeben?","victory":"Der Spiegel-Kuze lächelt zum ersten Mal. Er löst sich nicht auf – er tritt in Kuzes Schatten zurück.","wisdom":"Dein stärkster Gegner wollte nur gehört werden.","difficulty":15},
    {"id":"first_witness","name":"The First Witness","subtitle":"Before Name, Before Form","realm":3,"rank":3,"opening":"Am ersten Morgen steht der Zeuge, der das Erwachen des Bewusstseins gesehen hat. Licht und Schatten sind hier eine einzige Quelle.","challenge":"Wenn niemand zusieht, wer bist du dann?","victory":"Kuze antwortet nicht mit einem Namen, sondern mit einem Schritt. Der erste Würfel erwacht. Ende von Kapitel I – der Zen Master ist bereit.","wisdom":"Erleuchtung ist kein Ende. Sie ist ein Anfang.","difficulty":16},
]

static func get_boss(index: int) -> Dictionary:
    if index < 0 or index >= BOSSES.size():
        return {}
    return BOSSES[index].duplicate(true)

static func is_unlocked(index: int, cleared: int) -> bool:
    return index >= 0 and index < BOSSES.size() and index <= clampi(cleared, 0, BOSSES.size())

static func next_stage(cleared: int) -> int:
    return mini(clampi(cleared, 0, BOSSES.size()), BOSSES.size()-1)

static func validate() -> bool:
    if REALMS.size() != 4 or BOSSES.size() != 16:
        return false
    var used: Dictionary = {}
    for i in range(BOSSES.size()):
        var b: Dictionary = BOSSES[i]
        if b["realm"] != int(i / 4) or b["rank"] != i % 4:
            return false
        if used.has(b["id"]) or ZenMasterStageCatalog.stage_for(b["id"]).is_empty():
            return false
        if b["opening"].is_empty() or b["challenge"].is_empty() or b["victory"].is_empty():
            return false
        used[b["id"]] = true
    return true
