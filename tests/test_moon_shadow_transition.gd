extends SceneTree
# Exercise the real Godot 3D transformation and prove one-time checkpoints
# without changing a player's Classic, Rank, Shop or Realm saves.
const Intro = preload("res://ui/ZenCubeAwakening.gd")
const State = preload("res://story/ZenFractureState.gd")
var failures: int = 0

func check(ok: bool, description: String) -> void:
    if not ok:
        failures += 1
        printerr("MOON→SHADOW FAIL: "+description)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var path: String = State.PATH
    var saved_bytes: PackedByteArray = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
    var saved_existed: bool = FileAccess.file_exists(path)
    if saved_existed: DirAccess.remove_absolute(path)
    check(not State.portal_seen() and not State.awakening_seen(),"first run has no cinematic flags")
    check(State.mark_portal(),"save first portal checkpoint")
    check(State.portal_seen() and not State.awakening_seen(),"stage 1 and stage 2 remain independent")
    check(State.mark_awakening(),"save second awakening checkpoint")
    check(State.portal_seen() and State.awakening_seen(),"both stages persisted after restart")
    check(State.mark_awakening(),"repeated save is idempotent")
    var first: CanvasLayer = Intro.new()
    root.add_child(first)
    first.call("present",0,"en")
    await process_frame
    var cube_old: Node3D = first.get("_cube3")
    var cube_new: Node3D = first.get("_cube4")
    check(is_instance_valid(cube_old) and is_instance_valid(cube_new),"both real 3D cube grids created")
    check(cube_old.visible and not cube_new.visible,"Moon Garden retains 3x3 before Shadow page 1")
    check(cube_new.get_child_count()>cube_old.get_child_count(),"4x4 model has more physical grid lines")
    var counts: Array[int] = [0,0]
    first.finished.connect(func(): counts[0]+=1)
    first.call("_finish")
    await process_frame
    check(counts[0]==1,"first stage ends once")
    var second: CanvasLayer = Intro.new()
    root.add_child(second)
    second.call("present",1,"de")
    await process_frame
    second.set("_time",3.6)
    second.call("_process",0.0)
    var transformed: Node3D = second.get("_cube4")
    check(transformed.visible and not (second.get("_cube3") as Node3D).visible,"3x3 transforms to visible 4x4")
    second.finished.connect(func(): counts[1]+=1)
    second.call("_finish")
    await process_frame
    check(counts[1]==1,"second stage ends once")
    if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
    if saved_existed:
        var output: FileAccess = FileAccess.open(path,FileAccess.WRITE)
        output.store_buffer(saved_bytes)
        output.close()
    print("MOON SHADOW TRANSITION FAILURES=",failures)
    quit(0 if failures==0 else 1)
