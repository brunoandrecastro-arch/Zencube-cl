extends CanvasLayer
## Vertical Sky Garden reader with two gated 3x3 family games.
const Sky = preload("res://story/ZenSkyGardenCampaign.gd")
const GOLD := Color("#f0d99b")
const WHITE := Color("#fdf5e2")
const MUTE := Color("#d3dacb")
const COPY: Dictionary = {
    "en":{"back":"‹ Back","next":"Next ›","play":"▶ Play with %s","finish":"✦ Complete the journey","done":"‹ Return to library","hint":"Swipe to read","gate":"Play with %s to continue the story.","locked":"Complete Shattered Moon first.","missing":"Sky Garden artwork is missing.","progress":"Page %d / 30 · Family games %d/2"},
    "de":{"back":"‹ Zurück","next":"Weiter ›","play":"▶ Mit %s spielen","finish":"✦ Reise abschließen","done":"‹ Zur Bibliothek","hint":"Zum Weiterlesen wischen","gate":"Spiele mit %s, um weiterzulesen.","locked":"Beende zuerst Shattered Moon.","missing":"Sky-Garden-Bild fehlt.","progress":"Seite %d / 30 · Familienpartien %d/2"},
    "pt":{"back":"‹ Voltar","next":"Seguinte ›","play":"▶ Jogar com %s","finish":"✦ Concluir a jornada","done":"‹ Voltar à biblioteca","hint":"Desliza para ler","gate":"Joga com %s para continuar.","locked":"Conclui primeiro Shattered Moon.","missing":"Falta a imagem de Sky Garden.","progress":"Página %d / 30 · Jogos em família %d/2"}
}
var progress: Dictionary
var locale: String = "en"
var reader: TextureRect
var counter: Label
var note: Label
var previous: Button
var next_button: Button
var soundtrack: AudioStreamPlayer
var touch_start: Vector2

func _chronicles() -> Node:
    return get_tree().root.get_node("ZenChronicles")

func _ready() -> void:
    layer = 110
    progress = Sky.load_progress()
    locale = str(SaveManager.load_data().get("settings",{}).get("language","en"))
    if not COPY.has(locale): locale = "en"
    _build()
    _display()
    _audio()

func t(key: String) -> String:
    return str(COPY[locale].get(key,key))

func _button(caption: String, parent: Node, callback: Callable) -> Button:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size.y = 54
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size",17)
    button.add_theme_color_override("font_color",WHITE)
    button.pressed.connect(callback)
    parent.add_child(button)
    return button

func _build() -> void:
    var canvas := ColorRect.new()
    canvas.name = "SkyGardenReader"
    canvas.color = Color("#1c2b25")
    canvas.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(canvas)
    canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var margins := MarginContainer.new()
    canvas.add_child(margins)
    margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left","right"]: margins.add_theme_constant_override("margin_"+side,12)
    margins.add_theme_constant_override("margin_top",28)
    margins.add_theme_constant_override("margin_bottom",22)
    var stack := VBoxContainer.new()
    margins.add_child(stack)
    stack.add_theme_constant_override("separation",8)
    var header := HBoxContainer.new()
    stack.add_child(header)
    _button("‹",header,_back).custom_minimum_size.x = 48
    var headline := Label.new()
    headline.text = "🌸 Sky Garden · The Return to Peace"
    headline.add_theme_font_size_override("font_size",16)
    headline.add_theme_color_override("font_color",GOLD)
    headline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    headline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    header.add_child(headline)
    _button("✕",header,_close).custom_minimum_size.x = 48
    counter = Label.new()
    counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    counter.add_theme_font_size_override("font_size",14)
    counter.add_theme_color_override("font_color",GOLD)
    stack.add_child(counter)
    reader = TextureRect.new()
    reader.name = "SkyGardenManhwaPage"
    reader.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    reader.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    reader.custom_minimum_size.y = 240
    reader.size_flags_vertical = Control.SIZE_EXPAND_FILL
    reader.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_child(reader)
    note = Label.new()
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.add_theme_font_size_override("font_size",14)
    note.add_theme_color_override("font_color",MUTE)
    note.custom_minimum_size.y = 42
    stack.add_child(note)
    var nav := HBoxContainer.new()
    nav.add_theme_constant_override("separation",8)
    stack.add_child(nav)
    previous = _button(t("back"),nav,_turn.bind(-1))
    next_button = _button(t("next"),nav,_turn.bind(1))

func _display() -> void:
    var page: int = clampi(int(progress.get("page",1)),1,Sky.page_limit(progress))
    progress.page = page
    var image_path: String = Sky.page_path(page)
    reader.texture = load(image_path) as Texture2D if ResourceLoader.exists(image_path) else null
    var games: int = int(bool(progress.won[0])) + int(bool(progress.won[1]))
    counter.text = t("progress") % [page,games]
    previous.disabled = page <= 1
    note.text = t("hint") if reader.texture != null else t("missing")
    if page==30:
        next_button.text = t("done") if bool(progress.get("completed",false)) else t("finish")
        note.text = "ZEN CHRONICLES — A JOURNEY COMPLETE"
        return
    var action: Dictionary = Sky.next_action(progress)
    if str(action.get("type",""))=="game":
        var opponent: String = Sky.NAMES[int(action.family)]
        next_button.text = t("play") % opponent
        note.text = t("gate") % opponent
    else:
        next_button.text = t("next")

func _turn(dir: int) -> void:
    var page: int = int(progress.get("page",1))
    if dir < 0:
        if page>1:
            progress.page = page-1
            if Sky.save_progress(progress): _display()
        return
    if page >= 30:
        if not bool(progress.get("completed",false)):
            if not Sky.finish(progress): return
            _close()
            _chronicles().call_deferred("sky_garden_story_completed")
        else:
            _back()
        return
    var action: Dictionary = Sky.next_action(progress)
    if str(action.get("type",""))=="game":
        if not Sky.unlocked() and not Sky.qa_mode():
            note.text = t("locked")
            return
        _chronicles().call("request_sky_garden_battle")
    elif str(action.get("type",""))=="page":
        progress.page = int(action.page)
        if Sky.save_progress(progress): _display()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_start = event.position
        else:
            var delta: Vector2 = event.position - touch_start
            if absf(delta.x)>68 and absf(delta.x)>absf(delta.y)*1.4:
                if delta.x<0 and int(progress.get("page",1))==30: return
                _turn(1 if delta.x<0 else -1)
                get_viewport().set_input_as_handled()
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode==KEY_LEFT: _turn(-1)
        elif event.keycode==KEY_RIGHT and int(progress.get("page",1))<30: _turn(1)
        elif event.keycode==KEY_ESCAPE: _back()
        else: return
        get_viewport().set_input_as_handled()

func _audio() -> void:
    _chronicles().call("claim_story_audio",self)
    var settings: Dictionary = SaveManager.load_data().get("settings",{})
    if bool(settings.get("music",false)):
        var music: AudioStream = Sky.story_stream()
        if music != null:
            soundtrack = AudioStreamPlayer.new()
            soundtrack.stream = music
            soundtrack.volume_db = -4.0
            add_child(soundtrack)
            soundtrack.play()

func stop_story_audio() -> void:
    if is_instance_valid(soundtrack): soundtrack.stop()

func _exit_tree() -> void:
    stop_story_audio()
    var nav: Node = get_tree().root.get_node_or_null("ZenChronicles")
    if is_instance_valid(nav): nav.call("release_story_audio",self)

func _back() -> void:
    _close()
    _chronicles().call_deferred("open_library")

func _close() -> void:
    _chronicles().call("close_sky_garden_reader")
