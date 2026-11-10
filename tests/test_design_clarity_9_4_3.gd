extends SceneTree
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
    for tex in ZenAscension.WORLD_TEXTURES:
        check(tex.get_size() == Vector2i(1440,2560),"HD backdrop")
    game.open_worlds()
    check(has_text(game.popup,"Freischaltung: 3 Siege gegen Leicht"),"German bamboo unlock hint")
    check(has_text(game.popup,"3 Siege in Folge gegen Meister"),"German streak unlock hint")
    check(has_text(game.popup,"Welten ändern nur das Aussehen"),"worlds are cosmetic")
    game.data.settings.language = "en"
    game.open_worlds()
    check(has_text(game.popup,"Unlock: 3 wins against Easy"),"English unlock hint")
    game.data.settings.language = "pt"
    game.open_worlds()
    check(has_text(game.popup,"Desbloquear: 3 vitórias contra"),"Portuguese unlock hint")
    game.close_modal()
    game.queue_free()
    await process_frame
    print("ZEN 9.4.3 WORLD CLARITY FAILURES=",failures)
    quit(0 if failures==0 else 1)
