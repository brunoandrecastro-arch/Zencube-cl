class_name InputController
extends RefCounted
var fingers: Dictionary = {}
var origin: Vector2 = Vector2.ZERO
var press_cell: int = -1
var dragged := false
var mouse_down := false
var touch_device_seen := false
var renderer: CubeRenderer
var on_tap: Callable
func _init(view: CubeRenderer, callback: Callable) -> void:
    renderer = view
    on_tap = callback
func handle(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        touch_device_seen = true
        if event.pressed:
            fingers[event.index] = event.position
            if fingers.size() == 1:
                origin = event.position
                press_cell = renderer.pick(event.position)
                dragged = false
            else:
                dragged = true
        else:
            var was_single := fingers.size() == 1
            if was_single and not dragged and event.position.distance_to(origin) <= 12:
                var release_cell = renderer.pick(event.position)
                if press_cell >= 0 and release_cell == press_cell:
                    on_tap.call(release_cell)
            fingers.erase(event.index)
            if fingers.is_empty(): press_cell = -1
    elif event is InputEventScreenDrag:
        touch_device_seen = true
        if fingers.size() >= 2:
            var keys = fingers.keys()
            var d0 = fingers[keys[0]].distance_to(fingers[keys[1]])
            fingers[event.index] = event.position
            var d1 = fingers[keys[0]].distance_to(fingers[keys[1]])
            if d0 > 4 and d1 > 4: renderer.zoom(d0/d1)
            dragged = true
        elif fingers.size() == 1:
            fingers[event.index] = event.position
            if event.position.distance_to(origin) > 12: dragged = true
            if dragged: renderer.rotate_cube(event.relative)
    elif event is InputEventMouseButton:
        # Android synthesizes mouse actions from touch; never place two marks.
        if touch_device_seen or OS.get_name() == "Android": return
        if event.button_index == MOUSE_BUTTON_WHEEL_UP: renderer.zoom(0.93)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: renderer.zoom(1.07)
        elif event.button_index == MOUSE_BUTTON_LEFT:
            mouse_down = event.pressed
            if event.pressed:
                origin = event.position
                press_cell = renderer.pick(event.position)
                dragged = false
            elif not dragged and event.position.distance_to(origin) <= 12:
                var release_cell = renderer.pick(event.position)
                if press_cell >= 0 and release_cell == press_cell:
                    on_tap.call(release_cell)
    elif event is InputEventMouseMotion and mouse_down and not touch_device_seen:
        if event.position.distance_to(origin) > 12: dragged = true
        if dragged: renderer.rotate_cube(event.relative)
