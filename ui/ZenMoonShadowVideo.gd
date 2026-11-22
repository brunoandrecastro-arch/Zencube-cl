extends CanvasLayer
## Optional prerendered 3x3 -> 4x4 Act IV epilogue. The original native
## two-part ceremony remains a fallback if the video is not installed.
signal finished

const VIDEO_PATH := "res://assets/video/moon_shadow_3x3_to_4x4.ogv"
var _video: VideoStreamPlayer
var _closed: bool = false

static func media_ready() -> bool:
    return ResourceLoader.exists(VIDEO_PATH)

func present(language: String = "en") -> void:
    layer = 160
    process_mode = Node.PROCESS_MODE_ALWAYS
    var screen: Control = Control.new()
    screen.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(screen)
    screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var backdrop: ColorRect = ColorRect.new()
    backdrop.color = Color("#090510")
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    screen.add_child(backdrop)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    _video = VideoStreamPlayer.new()
    _video.name = "MoonShadow3x3To4x4"
    _video.expand = true
    _video.loop = false
    _video.autoplay = false
    _video.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _video.stream = load(VIDEO_PATH) as VideoStream
    _video.volume_db = -80.0 if not bool(SaveManager.load_data().get("settings", {}).get("sound", true)) else 0.0
    screen.add_child(_video)
    _video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _video.finished.connect(_finish)

    var skip: Button = Button.new()
    skip.name = "SkipMoonShadowVideo"
    skip.text = "Überspringen ›" if language == "de" else ("Saltar ›" if language == "pt" else "Skip ›")
    screen.add_child(skip)
    skip.anchor_left = 0.68
    skip.anchor_right = 0.96
    skip.anchor_top = 0.94
    skip.anchor_bottom = 0.995
    skip.offset_top = 0
    skip.offset_bottom = 0
    skip.pressed.connect(_finish)

    _video.play()
    # Also recover gracefully from devices unable to play the file.
    get_tree().create_timer(12.0, true, false, true).timeout.connect(_finish)

func _finish() -> void:
    if _closed:
        return
    _closed = true
    if is_instance_valid(_video):
        _video.stop()
    finished.emit()
    queue_free()
