from pathlib import Path

root = Path(__file__).resolve().parents[1]
assets = root / "assets" / "sky_garden"
required = (
    [assets / "pages" / f"page_{i:02d}.webp" for i in range(1, 31)]
    + [assets / "family" / f"{name}.webp" for name in ("aiko_tadanobu", "shin_tadanobu")]
    + [assets / "arenas" / f"{name}.webp" for name in ("aiko_tadanobu", "shin_tadanobu")]
    + [assets / "realm.webp"]
)
missing = [str(p.relative_to(root)) for p in required if not p.is_file()]
assert not missing, "Missing Sky Garden image assets:\n" + "\n".join(missing)
assert len(list(assets.rglob("*.webp"))) == 35, "Sky Garden must contain exactly 35 final WebP images"
for path in required:
    with path.open("rb") as file:
        assert file.read(4) == b"RIFF" and file.read(8)[4:] == b"WEBP", f"Invalid WebP: {path}"

model = (root / "story/ZenSkyGardenCampaign.gd").read_text()
reader = (root / "story/ZenSkyGardenReader.gd").read_text()
chron = (root / "story/ZenChronicles.gd").read_text()
controller = (root / "ui/GameController.gd").read_text()
assert 'user://zencube_sky_garden_epilogue_v1.json' in model
assert 'const GATES: Array[int] = [8, 18]' in model
assert 'const CONTINUE_PAGES: Array[int] = [9, 19]' in model
assert 'result.owners = [1,0]' in model, 'Kuze plays O, family plays X'
assert 'RulesEngine.new().victories(board.cells,2)' in model
assert 'if not SkyGarden.unlocked() and not SkyGarden.qa_mode()' in chron
assert 'func request_sky_garden_battle() -> void:' in chron
assert 'change_scene_to_file","res://Main.tscn"' in chron
assert 'SkyGardenClassicStoryCard' in chron and 'RealmCardSkyGarden' in chron
assert 'SkyGardenClassicWorldCard' in controller
assert 'func start_sky_garden_battle() -> void:' in controller
assert 'func _sky_tick() -> void:' in controller
assert 'func _sky_leave() -> void:' in controller
assert 'func _sky_result() -> void:' in controller
assert 'sky_active' in controller and 'SkyGarden.capture(sky_progress,board)' in controller
assert 'SkyGarden.story_stream()' in reader
print("PASS: Sky Garden 30-page reader, two portrait-led family games, 3 backgrounds, isolated 3x3 world and navigation")
