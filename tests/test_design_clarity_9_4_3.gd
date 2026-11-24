extends SceneTree
const Moon = preload("res://story/ZenShatteredMoonCampaign.gd")
const SkyGarden = preload("res://story/ZenSkyGardenCampaign.gd")
# Dynamic checks complement the 9.4.3 static visual/text assertions.
var failures: int = 0
func check(ok: bool, info: String) -> void:
    if not ok:
        failures += 1
        printerr("WORLD CLARITY FAIL: " + info)
func has_text(node: Node, phrase: String) -> bool:
    if node is Label and str(node.text).contains(phrase):
        return true
    for child in node.get_children():
        if has_text(child, phrase):
            return true
    return false
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var scene: PackedScene = load("res://Main.tscn") as PackedScene
    check(scene != null,"Main scene")
    if scene == null:
        quit(1)
        return
    var game = scene.instantiate()
    root.add_child(game)
    await process_frame
    game.data = SaveManager.defaults()
    game.data.settings.language = "de"
    ZenAscension.ensure(game.data)
    game.refresh()
    check(game.renderer.tiles.size() == 54,"54 real selectable cube cells")
    check(game.viewport.size == Vector2i(960,960),"higher-resolution real cube render")
    var ui_surface: TextureRect = null
    for n in game.ui.find_children("*", "TextureRect", true, false):
        var candidate: TextureRect = n as TextureRect
        if candidate != null and candidate.texture == game.viewport.get_texture():
            ui_surface = candidate
            break
    check(ui_surface != null, "real 960px cube rendered into UI texture")
    for tex in ZenAscension.WORLD_TEXTURES:
        check(tex.get_size() == Vector2(1440,2560),"HD backdrop")
    var moon_existed: bool = FileAccess.file_exists(Moon.SAVE)
    var moon_backup: PackedByteArray = FileAccess.get_file_as_bytes(Moon.SAVE) if moon_existed else PackedByteArray()
    var moon_progress: Dictionary = Moon.defaults()
    check(Moon.save_progress(moon_progress),"isolated incomplete Moon fixture")
    game.open_worlds()
    check(has_text(game.popup,"Freischaltung: 3 Siege gegen Leicht"),"German bamboo unlock hint")
    check(not has_text(game.popup,"3 Siege in Folge gegen Meister"),"hidden Sky Garden does not leak its rank hint")
    check(game.popup.find_child("SkyGardenClassicWorldCard",true,false)==null,"hidden Sky Garden story card")
    moon_progress.defeated = [true,true,true]
    moon_progress.page = 30
    check(Moon.finish_chapter(moon_progress),"complete isolated Moon fixture")
    check(SkyGarden.unlocked(),"Sky Garden story gate opens")
    game.open_worlds()
    check(has_text(game.popup,"3 Siege in Folge gegen Meister"),"German streak unlock hint after reveal")
    check(game.popup.find_child("SkyGardenClassicWorldCard",true,false)!=null,"revealed Sky Garden story card")
    check(has_text(game.popup,"Welten ändern nur das Aussehen"),"worlds are cosmetic")
    game.data.settings.language = "en"
    game.open_worlds()
    check(has_text(game.popup,"Unlock: 3 wins against Easy"),"English unlock hint")
    game.data.settings.language = "pt"
    game.open_worlds()
    check(has_text(game.popup,"Desbloquear: 3 vitórias contra"),"Portuguese unlock hint")
    game.close_modal()
    if moon_existed:
        var backup_file := FileAccess.open(Moon.SAVE,FileAccess.WRITE)
        backup_file.store_buffer(moon_backup)
        backup_file.close()
    elif FileAccess.file_exists(Moon.SAVE):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(Moon.SAVE))
    game.queue_free()
    await process_frame
    print("ZEN 9.4.3 WORLD CLARITY FAILURES=",failures)
    quit(0 if failures==0 else 1)
