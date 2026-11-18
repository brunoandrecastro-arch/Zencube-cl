extends SceneTree
## Campaign 2.0 headless smoke and save-isolation test.
const Abyss = preload("res://story/ZenAbyssCampaign.gd")
const Skins = preload("res://core/ZenAbyssSkins.gd")
const Reader = preload("res://story/ZenAbyssReader.gd")
var failures: int = 0
var backups: Dictionary = {}

func check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        printerr("ABYSS TEST FAIL: ",reason)

func _initialize() -> void:
    call_deferred("run")

func _backup(path: String) -> void:
    if FileAccess.file_exists(path):
        backups[path] = FileAccess.get_file_as_bytes(path)

func _restore() -> void:
    for path in [Abyss.SAVE,SaveManager.PATH]:
        if backups.has(path):
            var file := FileAccess.open(path,FileAccess.WRITE)
            if file != null:
                file.store_buffer(backups[path])
                file.close()
        elif FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func run() -> void:
    _backup(Abyss.SAVE)
    _backup(SaveManager.PATH)
    check(Abyss.BOSS_IDS.size()==3,"three unique bosses")
    check(Abyss.GATES==[6,15,25],"bosses appear on pages 6, 15 and 25")
    check(Abyss.CONTINUE_PAGES==[7,16,26],"post-victory pages correct")
    check(Abyss.BOT_LEVELS==[1,2,3],"Medium Hard Master progression")
    check(Abyss.page_path(1).ends_with("page_01.webp"),"first page path")
    check(Abyss.page_path(30).ends_with("page_30.webp"),"last page path")
    check(Abyss.page_path(31)=="","no page beyond story")
    check(Skins.PROFILES.size()==4,"four Abyss-only cube materials")
    for i in range(4):
        var material: ImageTexture = Skins.make_surface(i)
        check(material != null and material.get_width()==160,"procedural skin "+str(i))
    var lines: Array = ZenAscend.generate_lines()
    check(lines.size()==204,"use original 204 native 4x4 winning lines")
    var empty: Array = []
    empty.resize(96)
    empty.fill(0)
    for boss in range(3):
        var move: int = Abyss.choose_move(empty,lines,boss)
        check(move>=0 and move<96,"legal native bot opening "+str(boss))
    var state: Dictionary = Abyss.defaults()
    check(Abyss.save_progress(state),"new independent save writes")
    check(Abyss.page_limit(state)==6,"first boss cannot be skipped")
    for boss in range(3):
        state.page = Abyss.GATES[boss]
        check(Abyss.next_action(state).get("type")=="battle","gate "+str(boss))
        var first: Dictionary = Abyss.begin_battle(state,boss)
        check(first.cells.size()==96,"native 96-cell board "+str(boss))
        check(first.turn in [1,2],"legal first player "+str(boss))
        check(Abyss.save_progress(state),"save active match "+str(boss))
        var loaded: Dictionary = Abyss.load_progress()
        check(not loaded.game.is_empty(),"resume previous battle "+str(boss))
        state.game = {}
        var retry: Dictionary = Abyss.begin_battle(state,boss)
        check(retry.turn != first.turn,"alternate starter on retry "+str(boss))
        check(Abyss.record_victory(state,boss),"record a real engine-approved victory "+str(boss))
        check(int(state.page)==Abyss.CONTINUE_PAGES[boss],"new page unlocked "+str(boss))
        check(Abyss.load_progress().page==Abyss.CONTINUE_PAGES[boss],"victory survives restart "+str(boss))
    check(Abyss.page_limit(state)==30,"all 30 pages unlocked after third win")
    state.page = 30
    check(Abyss.finish_chapter(state),"finish after page 30")
    check(Abyss.load_progress().completed,"ending persists")
    var scene: PackedScene = load("res://Ascend.tscn")
    check(scene != null,"unchanged native 4x4 scene can be loaded")
    var script: Script = Reader
    check(script != null,"native Manhwa reader script imports")
    var has_media: bool = FileAccess.file_exists(Abyss.page_path(1))
    if has_media:
        for p in range(1,31):
            check(ResourceLoader.exists(Abyss.page_path(p)),"every story picture "+str(p))
        for b in range(3):
            check(ResourceLoader.exists(Abyss.boss_art(b)),"HD boss art "+str(b))
            check(Abyss.boss_stream(b)!=null,"original boss soundtrack "+str(b))
        check(Abyss.story_stream()!=null,"story background soundtrack")
    else:
        print("ABYSS MEDIA PENDING: upload both ZIPs for complete Android build")
    _restore()
    print("ABYSS CAMPAIGN TEST FAILURES=",failures)
    quit(0 if failures==0 else 1)
