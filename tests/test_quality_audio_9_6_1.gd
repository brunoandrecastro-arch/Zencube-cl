extends SceneTree
# Godot runtime smoke checks: paginated shop, texture pipeline and 3 audio tracks.
var failures: int = 0
func check(ok: bool, reason: String) -> void:
	if not ok:
		failures += 1
		printerr("ZEN 9.6.1 FAIL: ", reason)
func swatches(node: Node) -> int:
	var total: int = 0
	if node is ColorRect and node.custom_minimum_size == Vector2(28,28):
		total += 1
	for child in node.get_children():
		total += swatches(child)
	return total
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var packed: PackedScene = load("res://Main.tscn") as PackedScene
	check(packed != null, "main scene")
	if packed == null:
		quit(1)
		return
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	check(game.renderer.tiles.size() == 54, "54 real selectable cells")
	check(game.rules.lines.size() == 108, "108 winning lines")
	check(ZenCollection.SKINS.size() == 20, "20 retained skins")
	for i in range(20):
		var tex: Texture2D = game.renderer.surface_textures[i]
		check(tex != null and tex.get_width()==1024 and tex.get_height()==1024,"1024 material %d" % i)
	game.shop_page = 0
	game.open_store()
	check(swatches(game.popup) == 15, "first shop page has five skins")
	var first_scroll: ScrollContainer = game.popup.get_child(0) as ScrollContainer
	check(first_scroll != null and first_scroll.scroll_deadzone == 12, "touch-friendly scroll")
	game.change_shop_page(1)
	check(game.shop_page == 1 and swatches(game.popup) == 15,"next skin page")
	game.change_shop_page(15)
	check(game.shop_page == 3 and swatches(game.popup) == 15,"last skin page")
	game.change_shop_page(-15)
	check(game.shop_page == 0,"return to first page")
	var prior_game = game.board.snapshot()
	for track in range(3):
		var pcm: AudioStreamWAV = game.make_zen_music_stream(track)
		check(pcm != null and pcm.data.size() > 500000,"audio track %d" % track)
	check(game.board.snapshot() == prior_game,"shop and music never change the game")
	game.queue_free()
	await process_frame
	print("ZEN 9.6.1 CHECKS: failures=",failures)
	quit(0 if failures == 0 else 1)
