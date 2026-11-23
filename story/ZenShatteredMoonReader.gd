extends CanvasLayer
## Campaign 2.0: independent Shattered Moon 30-page manhwa reader.
## Pages are gated by three genuine best-of-three 4x4 boss battles.
const Moon = preload("res://story/ZenShatteredMoonCampaign.gd")
const Realm2 = preload("res://core/ZenRealmCampaign2.gd")
const GOLD := Color("#f5dea8")
const WHITE := Color("#f8efde")
const MUTE := Color("#c5c9ce")
const COPY: Dictionary = {
    "de":{"previous":"‹ Zurück","next":"Weiter ›","fight":"⚔ Prüfung: %s","finish":"✦ Das Kapitel abschließen","done":"‹ Zur Bibliothek","progress":"Seite %d / 30 · Boss-Prüfungen %d/3","missing":"Shattered-Moon-Bild fehlt.","tip":"Wischen zum Weiterlesen","locked":"Schließe zuerst Satori Realm ab.","gate":"Besiege %s, um weiterzulesen.","trials":"✦ Story-Prüfungen · %d/3"},
    "en":{"previous":"‹ Previous","next":"Next ›","fight":"⚔ Trial: %s","finish":"✦ Finish the chapter","done":"‹ Back to library","progress":"Page %d / 30 · Boss trials %d/3","missing":"Missing Shattered Moon artwork.","tip":"Swipe to read","locked":"Complete Satori Realm first.","gate":"Defeat %s to continue.","trials":"✦ Story trials · %d/3"},
    "pt":{"previous":"‹ Voltar","next":"Seguinte ›","fight":"⚔ Prova: %s","finish":"✦ Concluir o capítulo","done":"‹ Voltar à biblioteca","progress":"Página %d / 30 · Provas %d/3","missing":"Falta uma imagem de Shattered Moon.","tip":"Desliza para continuar","locked":"Conclui primeiro Satori Realm.","gate":"Derrota %s para continuares.","trials":"✦ Provas da história · %d/3"}
}
var progress: Dictionary = {}
var locale: String = "en"
var reader: TextureRect
var counter: Label
var status: Label
var previous: Button
var next_button: Button
var challenge_button: Button
var soundtrack: AudioStreamPlayer
var start_touch: Vector2 = Vector2.ZERO

func _chronicles() -> Node:
    return get_tree().root.get_node("ZenChronicles")

func _ready() -> void:
    layer = 110
    progress = Moon.load_progress()
    locale = str(SaveManager.load_data().get("settings",{}).get("language","en"))
    if not COPY.has(locale): locale = "en"
    _build()
    _display()
    _start_audio()

func t(key: String) -> String:
    return str(COPY[locale].get(key,key))

func _button(caption: String, parent: Node, callback: Callable) -> Button:
    var item: Button = Button.new()
    item.text = caption
    item.custom_minimum_size.y = 54
    item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    item.add_theme_font_size_override("font_size",17)
    item.add_theme_color_override("font_color",WHITE)
    item.pressed.connect(callback)
    parent.add_child(item)
    return item

func _build() -> void:
    var canvas: ColorRect = ColorRect.new()
    canvas.name = "ShatteredMoonReader"
    canvas.color = Color("#1c2330")
    canvas.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(canvas)
    canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var margin: MarginContainer = MarginContainer.new()
    canvas.add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,12)
    margin.add_theme_constant_override("margin_top",28)
    margin.add_theme_constant_override("margin_bottom",22)
    var column: VBoxContainer = VBoxContainer.new()
    column.add_theme_constant_override("separation",8)
    margin.add_child(column)
    var header: HBoxContainer = HBoxContainer.new()
    column.add_child(header)
    _button("‹",header,_return_library).custom_minimum_size.x = 48
    var label: Label = Label.new()
    label.text = "🌙 Shattered Moon · The Last Crossing"
    label.add_theme_color_override("font_color",GOLD)
    label.add_theme_font_size_override("font_size",17)
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    header.add_child(label)
    _button("✕",header,_close).custom_minimum_size.x = 48
    counter = Label.new()
    counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    counter.add_theme_font_size_override("font_size",14)
    counter.add_theme_color_override("font_color",GOLD)
    column.add_child(counter)
    reader = TextureRect.new()
    reader.name = "ShatteredMoonManhwaPage"
    reader.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    reader.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    reader.custom_minimum_size.y = 245
    reader.size_flags_vertical = Control.SIZE_EXPAND_FILL
    reader.mouse_filter = Control.MOUSE_FILTER_IGNORE
    column.add_child(reader)
    status = Label.new()
    status.add_theme_color_override("font_color",MUTE)
    status.add_theme_font_size_override("font_size",14)
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status.custom_minimum_size.y = 42
    column.add_child(status)
    var navigation: HBoxContainer = HBoxContainer.new()
    navigation.add_theme_constant_override("separation",8)
    column.add_child(navigation)
    previous = _button(t("previous"),navigation,_turn.bind(-1))
    next_button = _button(t("next"),navigation,_turn.bind(1))
    challenge_button = _button(t("trials") % 0,column,_open_challenges)

func _display() -> void:
    var page: int = clampi(int(progress.get("page",1)),1,Moon.page_limit(progress))
    progress.page = page
    var path: String = Moon.page_path(page)
    reader.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
    var won_count: int = 0
    for value in progress.get("defeated",[]):
        if bool(value): won_count += 1
    counter.text = t("progress") % [page,won_count]
    previous.disabled = page <= 1
    var cleared: int = won_count
    challenge_button.text = t("trials") % cleared
    challenge_button.disabled = false
    status.text = t("tip") if reader.texture != null else t("missing")
    if page == 30:
        next_button.text = t("done") if bool(progress.get("completed",false)) else t("finish")
        status.text = "THE LAST CROSSING."
        return
    var step: Dictionary = Moon.next_action(progress)
    if step.get("type") == "battle":
        var name: String = Moon.BOSS_NAMES[int(step.boss)]
        next_button.text = t("fight") % name
        status.text = t("gate") % name
    else:
        next_button.text = t("next")

func _turn(direction: int) -> void:
    var page: int = int(progress.get("page",1))
    if direction < 0:
        if page > 1:
            progress.page = page-1
            if Moon.save_progress(progress): _display()
        return
    if page >= 30:
        if not bool(progress.get("completed",false)):
            if not Moon.finish_chapter(progress): return
            _close()
            _chronicles().call("shattered_moon_story_completed")
        else:
            _return_library()
        return
    var step: Dictionary = Moon.next_action(progress)
    if step.get("type") == "battle":
        if not Moon.unlocked() and not Moon.qa_mode():
            status.text = t("locked")
            return
        _chronicles().call("request_shattered_moon_battle")
    elif step.get("type") == "page":
        progress.page = int(step.page)
        if Moon.save_progress(progress): _display()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            start_touch = event.position
        else:
            var movement: Vector2 = event.position - start_touch
            if absf(movement.x) > 68 and absf(movement.x) > absf(movement.y)*1.4:
                if movement.x < 0 and int(progress.get("page",1))==30: return
                _turn(1 if movement.x < 0 else -1)
                get_viewport().set_input_as_handled()
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_LEFT: _turn(-1)
        elif event.keycode == KEY_RIGHT and int(progress.get("page",1)) < 30: _turn(1)
        elif event.keycode == KEY_ESCAPE: _return_library()
        else: return
        get_viewport().set_input_as_handled()

func _start_audio() -> void:
    _chronicles().call("claim_story_audio",self)
    var settings: Dictionary = SaveManager.load_data().get("settings",{})
    if bool(settings.get("music",false)):
        var music: AudioStream = Moon.story_stream()
        if music != null:
            soundtrack = AudioStreamPlayer.new()
            soundtrack.stream = music
            soundtrack.volume_db = -3.0
            add_child(soundtrack)
            soundtrack.play()

func stop_story_audio() -> void:
    if is_instance_valid(soundtrack): soundtrack.stop()

func _exit_tree() -> void:
    stop_story_audio()
    var nav: Node = get_tree().root.get_node_or_null("ZenChronicles")
    if is_instance_valid(nav): nav.call("release_story_audio",self)

func _open_challenges() -> void:
    var defeated: Array = progress.get("defeated",[])
    var total: int = 0
    for flag in defeated:
        if bool(flag): total += 1
    status.text = (t("trials") % total) + " · Echo Keeper · Silent Ferryman · Moon Warden"

func _return_library() -> void:
    _close()
    _chronicles().call_deferred("open_library")

func _close() -> void:
    _chronicles().call("close_ember_reader")
