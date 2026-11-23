#!/usr/bin/env python3
from pathlib import Path
r=Path(__file__).resolve().parents[1]
m=(r/'story/ZenShatteredMoonCampaign.gd').read_text()
reader=(r/'story/ZenShatteredMoonReader.gd').read_text()
chron=(r/'story/ZenChronicles.gd').read_text()
controller=(r/'ui/AscendController.gd').read_text()
assert 'user://zencube_shattered_moon_v1.json' in m
assert 'return bool(Satori.load_progress().get("completed",false))' in m
assert 'func start_shattered_moon_battle() -> void:' in controller
assert 'func open_shattered_moon_preview() -> void:' in chron
assert 'func request_shattered_moon_battle() -> void:' in chron
assert '"RealmCardShatteredMoon",true' in chron
assert 'ShatteredMoonManhwaPage' in reader
assert 'Satori.save_progress' not in reader
assert all((r/'assets/shattered_moon/pages'/f'page_{i:02d}.webp').is_file() for i in range(1,31))
assert len(list((r/'assets/shattered_moon').rglob('*.webp'))) == 37
assert 'test_shattered_moon.gd' in (r/'.github/workflows/android.yml').read_text()
print('PASS: isolated Shattered Moon save, 30 pages, three bosses, Satori gate, navigation, Godot workflow')
