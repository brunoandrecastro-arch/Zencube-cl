extends SceneTree
# The only changes in this experimental balance are personalities for stages 0..2.
# Later Realm levels and player progression must remain untouched.
const Story = preload("res://story/ZenRealmChronicles.gd")
const Bot = preload("res://core/ZenAscendRealmBot.gd")
var failures: int = 0

func verify(ok: bool, title: String) -> void:
    if not ok:
        failures += 1
        printerr("SHADOW UI TEST FAIL: ", title)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    seed(27011)
    var lines: Array = ZenAscend.generate_lines()
    verify(lines.size() == 204, "4x4 geometry unchanged")
    for stage in range(12):
        verify(Story.boss_level(stage) == [1,2,3,4][int(stage/3)], "Realm difficulty still fixed at stage %d" % stage)

    var empty: Array = []
    empty.resize(96)
    empty.fill(0)
    for stage in range(3):
        var before: Array = empty.duplicate()
        var cell: int = Story.choose_move(empty,lines,stage)
        verify(cell >= 0 and cell < 96, "Shadow boss %d opens legally" % stage)
        verify(empty == before, "Shadow boss %d does not mutate position" % stage)

    # The Nebelwächter and Schleiermönch always stop an immediate loss.
    var threat: Array = lines[0]
    var position: Array = empty.duplicate()
    for i in range(3):
        position[int(threat[i])] = 1
    var last: int = int(threat[3])
    for stage in [0,2]:
        for sample in range(5):
            verify(Story.choose_move(position,lines,stage,int(threat[2])) == last,
                "defensive Shadow boss %d blocks the forced four-in-a-row" % stage)
    # The Spiegel-Novize now blocks more consistently, without losing his
    # mirror personality. Fixed RNG seed keeps this runtime check reproducible.
    var guard_count: int = 0
    for sample in range(100):
        if Story.choose_move(position,lines,1,int(threat[2])) == last:
            guard_count += 1
    verify(guard_count >= 85, "Mirror Novice blocks an urgent threat in most encounters: %d/100" % guard_count)

    # The realm-wide bot remains the original Medium; its rates are
    # intentionally not altered for normal Shadow Realm matches.
    verify(Bot.WIN_CHANCE[1] == 0.94, "base Medium win chance is untouched")
    verify(Bot.BLOCK_CHANCE[1] == 0.78, "base Medium block chance is untouched")
    print("SHADOW UI TEST: failures=%d, mirror_blocks=%d/100" % [failures,guard_count])
    quit(0 if failures == 0 else 1)
