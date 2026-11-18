extends CanvasLayer
## Independent, touch-first, 30-page Manhwa reader for Campaign 2.0.
## Uses the existing 4x4 Ascend scene only for boss battles.
const Abyss = preload("res://story/ZenAbyssCampaign.gd")
const Realm2 = preload("res://core/ZenRealmCampaign2.gd")
const GOLD := Color("#e1c79a")
const WHITE := Color("#f3e9e0")
const MUTE := Color("#b9c6d2")
const COPY: Dictionary = {
    "de":{"previous":"‹ Zurück","next":"Weiter ›","fight":"⚔ Bosskampf","finish":"✦ Kapitel abschließen","done":"Kapitel abgeschlossen","progress":"Seite %d / 30  ·  Bosse %d/3","missing":"Manhwa-Bilder fehlen in dieser Testversion.","tip":"Wischen zum Weiterlesen","locked":"Zen Ascend 4×4 muss zuerst freigeschaltet sein.","gate":"Besiege %s, um weiterzulesen.","home":"Zur Bibliothek"},
    "en":{"previous":"‹ Previous","next":"Next ›","fight":"⚔ Boss battle","finish":"✦ Finish chapter","done":"Chapter complete","progress":"Page %d / 30  ·  Bosses %d/3","missing":"Manhwa images are missing in this build.","tip":"Swipe to read","locked":"Unlock Zen Ascend 4×4 first.","gate":"Defeat %s to continue.","home":"Back to library"},
    "pt":{"previous":"‹ Voltar","next":"Seguinte ›","fight":"⚔ Chefe","finish":"✦ Concluir capítulo","done":"Capítulo concluído","progress":"Página %d / 30  ·  Chefes %d/3","missing":"Faltam as imagens do manhwa nesta versão.","tip":"Desliza para continuar","locked":"Desbloqueia Zen Ascend 4×4 primeiro.","gate":"Derrota %s para continuar.","home":"Voltar à biblioteca"}
}
var progress: Dictionary = {}
var locale: String = "en"
var reader: TextureRect
var counter: Label
var status: Label
var prev_button: Button
var next_button: Button
var challenge_button: Button
var sound: AudioStreamPlayer
var muted: Array[AudioStreamPlayer] = []
var start_touch: Vector2 = Vector2.ZERO

func _chronicles() -> Node:
    # Avoid circular script preload resolution in Godot headless Android CI.
    return get_tree().root.get_node("ZenChronicles")

func _ready() -> void:
    layer = 110
    progress = Abyss.load_progress()
    locale = str(SaveManager.load_data().get("settings",{}).get("language","en"))
    if not COPY.has(locale): locale = "en"
    _make_ui()
    _show_page()
    _start_audio()

func t(key: String) -> String:
    return str(COPY[locale].get(key,key))

func _button(value: String, parent: Node, fn: Callable) -> Button:
    var b := Button.new()
    b.text = value
    b.custom_minimum_size.y = 56
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size",18)
    b.add_theme_color_override("font_color",WHITE)
    b.pressed.connect(fn)
    parent.add_child(b)
    return b

func _make_ui() -> void:
    var canvas := ColorRect.new()
    canvas.name = "AbyssReader"
    canvas.color = Color("#0d1423")
    canvas.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(canvas)
    canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var margin := MarginContainer.new()
    canvas.add_child(margin)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left",12)
    margin.add_theme_constant_override("margin_right",12)
    margin.add_theme_constant_override("margin_top",29)
    margin.add_theme_constant_override("margin_bottom",22)
    var main := VBoxContainer.new()
    main.add_theme_constant_override("separation",8)
    margin.add_child(main)
    var bar := HBoxContainer.new()
    main.add_child(bar)
    _button("‹",bar,_return_library).custom_minimum_size.x = 45
    var heading := Label.new()
    heading.text = "🌑 Abyss of Memories"
    heading.add_theme_font_size_override("font_size",20)
    heading.add_theme_color_override("font_color",GOLD)
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    bar.add_child(heading)
    _button("✕",bar,_close).custom_minimum_size.x = 48
    counter = Label.new()
    counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    counter.add_theme_font_size_override("font_size",14)
    counter.add_theme_color_override("font_color",GOLD)
    main.add_child(counter)
    reader = TextureRect.new()
    reader.name = "AbyssManhwaPage"
    reader.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    reader.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    reader.custom_minimum_size.y = 250
    reader.size_flags_vertical = Control.SIZE_EXPAND_FILL
    reader.mouse_filter = Control.MOUSE_FILTER_IGNORE
    main.add_child(reader)
    status = Label.new()
    status.add_theme_color_override("font_color",MUTE)
    status.add_theme_font_size_override("font_size",14)
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status.custom_minimum_size.y = 42
    main.add_child(status)
    var controls := HBoxContainer.new()
    controls.add_theme_constant_override("separation",8)
    main.add_child(controls)
    prev_button = _button(t("previous"),controls,_turn.bind(-1))
    next_button = _button(t("next"),controls,_turn.bind(1))
    challenge_button = _button("🏆 Challenges · 0/3",main,_open_challenges)

func _show_page() -> void:
    var p: int = clampi(int(progress.get("page",1)),1,Abyss.page_limit(progress))
    progress.page = p
    var path: String = Abyss.page_path(p)
    reader.texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
    var victories: int = 0
    for flag in progress.get("defeated",[]):
        if bool(flag): victories += 1
    counter.text = t("progress") % [p,victories]
    status.text = t("tip") if reader.texture != null else t("missing")
    prev_button.disabled = p == 1
    var challenge_count: int = Realm2.completed_count(Realm2.load_progress(),1)
    challenge_button.text = "🏆 Challenges · %d/3" % challenge_count
    if p == 30:
        var done_story: bool = bool(progress.get("completed",false))
        if done_story:
            next_button.text = ("✦ Abyss of Memories" if 1==0 else "✦ Ember Temple") if Realm2.ready(1) else "🔒 3 Bosse + 3 Challenges"
            status.text = "Bosse: %d/3 · Challenges: %d/3" % [Realm2.bosses_won(1),challenge_count]
        else:
            next_button.text = t("finish")
        next_button.disabled = false
        return
    var action: Dictionary = Abyss.next_action(progress)
    if action.get("type") == "battle":
        next_button.text = t("fight")
        status.text = t("gate") % Abyss.BOSS_NAMES[int(action.boss)]
    else:
        next_button.text = t("next")
    next_button.disabled = false

func _turn(direction: int) -> void:
    var p: int = int(progress.get("page",1))
    if direction < 0:
        if p > 1:
            progress.page = p-1
            Abyss.save_progress(progress)
            _show_page()
        return
    if p >= 30:
        if not bool(progress.get("completed",false)):
            if Abyss.finish_chapter(progress): _show_page()
        elif Realm2.ready(1):
            _close()
            _chronicles().call_deferred("request_campaign_breakthrough",1)
        else:
            status.text = "Bosse %d/3 · Challenges %d/3: Beides wird benötigt." % [
                Realm2.bosses_won(1),Realm2.completed_count(Realm2.load_progress(),1)]
        return
    var action: Dictionary = Abyss.next_action(progress)
    if action.get("type") == "battle":
        var saved: Dictionary = SaveManager.load_data()
        if not ZenAscend.unlocked(saved) and not Abyss.qa_mode():
            status.text = t("locked")
            return
        _chronicles().call("request_abyss_battle")
    elif action.get("type") == "page":
        progress.page = int(action.page)
        if Abyss.save_progress(progress): _show_page()

func _open_challenges() -> void:
    _close()
    _chronicles().call_deferred("open_campaign_challenges",1)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            start_touch = event.position
        else:
            var delta: Vector2 = event.position-start_touch
            if absf(delta.x) > 68 and absf(delta.x) > absf(delta.y)*1.4:
                _turn(1 if delta.x < 0 else -1)
                get_viewport().set_input_as_handled()
    elif event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_RIGHT: _turn(1)
        elif event.keycode == KEY_LEFT: _turn(-1)
        elif event.keycode == KEY_ESCAPE: _return_library()
        else: return
        get_viewport().set_input_as_handled()

func _start_audio() -> void:
    var scene: Node = get_tree().current_scene
    if scene != null:
        var props: Array = scene.get_property_list()
        for key in ["music_player","music_fade_player","world_music","realm_music_fade"]:
            var known: bool = false
            for prop in props:
                if str(prop.get("name","")) == key:
                    known = true
                    break
            if known:
                var node: Variant = scene.get(key)
                if node is AudioStreamPlayer:
                    var player: AudioStreamPlayer = node
                    if player.playing and not player.stream_paused:
                        player.stream_paused = true
                        muted.append(player)
    var saved: Dictionary = SaveManager.load_data()
    if bool(saved.get("settings",{}).get("music",false)):
        var stream: AudioStream = Abyss.story_stream()
        if stream != null:
            sound = AudioStreamPlayer.new()
            sound.stream = stream
            sound.volume_db = -3.0
            add_child(sound)
            sound.play()

func _exit_tree() -> void:
    if is_instance_valid(sound): sound.stop()
    for player in muted:
        if is_instance_valid(player): player.stream_paused = false
    muted.clear()

func _return_library() -> void:
    _close()
    _chronicles().call_deferred("open_library")

func _close() -> void:
    _chronicles().call("close_abyss_reader")
