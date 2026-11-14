extends SceneTree
# Godot-level checks for persistent wallet, real material presets and playable audio.
var failed: int = 0
func check(ok: bool, label_text: String) -> void:
    if not ok:
        failed += 1
        printerr("ZEN COLLECTION FAIL: " + label_text)
func count_cards(node: Node) -> int:
    var total: int = 0
    if node is ColorRect and node.custom_minimum_size == Vector2(28, 28):
        total += 1
    for child in node.get_children():
        total += count_cards(child)
    return total
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    check(ZenCollection.SKINS.size() == 20, "20 real cube skins")
    check(ZenCollection.BOT_REWARDS == [8,15,25,40,65], "rewards rise with difficulty")
    var wallet: Dictionary = SaveManager.defaults()
    ZenCollection.ensure(wallet)
    check(wallet.economy.owned == [0] and int(wallet.economy.leaves) == 0, "initial default skin and zero leaves")
    wallet.stats.ai_wins = [2,1,0,0,0]
    var historical: Dictionary = {"1":true, "21":true, "100":true}
    check(ZenCollection.migrate_previous_rewards(wallet,historical)==87, "migrate old victories and solved puzzles once")
    check(ZenCollection.migrate_previous_rewards(wallet,historical)==0, "migration cannot double-reward")
    check(ZenCollection.reward_bot(wallet,4)==65, "grandmaster reward")
    check(ZenCollection.reward_bot(wallet,0)==8, "easy reward")
    check(ZenCollection.reward_loss(wallet)==1, "one leaf on defeat")
    check(ZenCollection.reward_challenge(wallet,5)==40, "grandmaster puzzle reward")
    var balance: int = int(wallet.economy.leaves)
    check(not ZenCollection.buy(wallet,19), "expensive skin cannot be bought without funds")
    check(int(wallet.economy.leaves)==balance,"failed purchase does not change balance")
    check(ZenCollection.buy(wallet,1), "cherry wood purchase")
    check(not ZenCollection.buy(wallet,1), "no double purchase")
    check(ZenCollection.equip(wallet,1), "equip paid skin")
    check(not ZenCollection.equip(wallet,18), "cannot equip locked skin")
    check(int(wallet.economy.equipped)==1, "selected skin remains set")
    var serialized: Dictionary = JSON.parse_string(JSON.stringify(wallet))
    ZenCollection.ensure(serialized)
    check(int(serialized.economy.equipped)==1 and serialized.economy.owned.has(1), "wallet survives save/load serialization")
    var scene: PackedScene = load("res://Main.tscn") as PackedScene
    check(scene != null, "main scene")
    if scene != null:
        var game = scene.instantiate()
        root.add_child(game)
        await process_frame
        check(game.renderer.tiles.size()==54 and game.rules.lines.size()==108,"real 54 cells and 108 lines unchanged")
        game.data = SaveManager.defaults()
        game.data.settings.language = "de"
        ZenAscension.ensure(game.data)
        ZenCollection.ensure(game.data)
        game.data.economy.leaves = 1000
        game.renderer.apply_skin(8)
        game.renderer.paint(game.board,false)
        check(game.renderer.skin_id==8,"real renderer switches to marble skin")
        check(game.renderer.tiles[0].material_override.albedo_color == Color(str(ZenCollection.SKINS[8].faces[0])), "real material changes to marble")
        game.renderer.apply_skin(0)
        game.renderer.paint(game.board,false)
        check(game.renderer.skin_id==0,"original skin remains selectable")
        game.open_store()
        check(game.popup!=null,"shop opens")
        if game.popup != null:
            check(count_cards(game.popup)==15,"shop first page has five cards with three swatches each")
        for track in range(3):
            var stream: AudioStreamWAV = game.make_zen_music_stream(track)
            check(stream!=null and stream.data.size()>300000,"music track %d loads" % track)
        game.select_music_track(2)
        check(int(game.data.settings.music_track)==2,"music selection stored")
        game.queue_free()
        await process_frame
    print("ZEN COLLECTION 9.5 FAILURES=",failed)
    quit(0 if failed==0 else 1)
