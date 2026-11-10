extends SceneTree
var failures: int = 0
func check(ok: bool, info: String) -> void:
	if not ok:
		failures += 1
		printerr("MATERIALS 9.6 FAIL: " + info)
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
	check(game.renderer.tiles.size() == 54, "54 cube tiles")
	check(game.rules.lines.size() == 108, "108 rules")
	check(ZenCollection.MATERIALS.size() == 20, "20 material families")
	check(game.renderer.surface_textures.size() == 20, "all material textures loaded")
	for i in range(20):
		game.renderer.apply_skin(i)
		game.renderer.paint(game.board, false)
		var mat: StandardMaterial3D = game.renderer.tiles[0].material_override as StandardMaterial3D
		check(mat != null and mat.albedo_texture != null, "textured skin %d" % i)
		if i == 9 or i == 18:
			check(mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "glass skin %d" % i)
	game.open_store()
	check(game.popup != null, "shop opens")
	check(game.board.move_count() == 0, "gameplay unchanged")
	game.queue_free()
	await process_frame
	print("MATERIALS 9.6 FAILURES=", failures)
	quit(0 if failures == 0 else 1)
