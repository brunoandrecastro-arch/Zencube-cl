extends CanvasLayer
## ZenCube 2.0 Realm – only Challenges grant Campaign achievements.
const Campaign = preload("res://core/ZenRealmCampaign2.gd")
const Ui = preload("res://ui/ZenUiTestTheme.gd")
const ZenType = preload("res://ui/ZenRealm2Typography.gd")
var chapter: int = 0
var locale: String = "en"
var panel: Control

func _ready() -> void:
    layer = 111
    locale = str(SaveManager.load_data().get("settings",{}).get("language","en"))
    if locale not in ["de","en","pt"]: locale = "en"
    _render()

func t(de: String,en: String,pt: String) -> String:
    return de if locale=="de" else (pt if locale=="pt" else en)

func _label(parent: Node, words: String, size: int, color: Color) -> Label:
    var label_node := Label.new()
    label_node.text = words
    label_node.add_theme_font_size_override("font_size",size)
    label_node.add_theme_color_override("font_color",color)
    label_node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    parent.add_child(label_node)
    label_node.add_theme_font_override("font",ZenType.heading() if size>=22 else ZenType.body())
    return label_node

func _button(parent: Node, words: String, callback: Callable, primary: bool = false) -> Button:
    var b := Button.new()
    b.text = words
    b.custom_minimum_size.y = 63
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_font_size_override("font_size",17)
    var face: Color = Color("#315b3d") if primary else Ui.GREEN
    b.add_theme_stylebox_override("normal",Ui.frame(face,16))
    b.add_theme_stylebox_override("hover",Ui.frame(Color("#437354"),16))
    b.add_theme_stylebox_override("pressed",Ui.frame(Color("#203c2d"),16))
    for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
        b.add_theme_color_override(key,Ui.IVORY)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.pressed.connect(callback)
    parent.add_child(b)
    return b

func _render() -> void:
    if is_instance_valid(panel): panel.queue_free()
    panel = ColorRect.new()
    panel.color = Ui.NIGHT
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    var challenge_theme: Theme = Theme.new()
    challenge_theme.default_font = ZenType.body()
    challenge_theme.default_font_size = 18
    panel.theme = challenge_theme
    add_child(panel)
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var scenery := TextureRect.new()
    scenery.texture = load(Campaign.SOURCE_ART[chapter]) if ResourceLoader.exists(Campaign.SOURCE_ART[chapter]) else null
    scenery.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    scenery.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    scenery.modulate = Color(0.50,0.55,0.63,0.40)
    scenery.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(scenery)
    scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var layer_panel := PanelContainer.new()
    layer_panel.add_theme_stylebox_override("panel",Ui.frame(Color("#14201a",0.94),22))
    layer_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer_panel.offset_left = 13
    layer_panel.offset_right = -13
    layer_panel.offset_top = 21
    layer_panel.offset_bottom = -24
    panel.add_child(layer_panel)
    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    layer_panel.add_child(scroll)
    var content := VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation",13)
    scroll.add_child(content)
    _label(content,"ZenCube 2.0 Realm",27,Ui.GOLD)
    _label(content,Campaign.REALM_NAMES[chapter],22,Ui.IVORY)
    _label(content,t("Realm-Challenges · nur hier gibt es Achievements","Realm challenges · achievements are earned here","Desafios do reino · conquistas apenas aqui"),14,Ui.IVORY)
    var data: Dictionary = Campaign.load_progress()
    var cleared: int = Campaign.completed_count(data,chapter)
    var defeated: int = Campaign.bosses_won(chapter)
    _label(content,t("Bosse: %d/3  ·  Challenges: %d/3","Bosses: %d/3  ·  Challenges: %d/3","Chefes: %d/3  ·  desafios: %d/3") % [defeated,cleared],17,Ui.GOLD)
    for i in range(3):
        var done: bool = bool(data.completed[chapter][i])
        var title: String = Campaign.task_title(chapter,i)
        var task: Button = _button(content,("✓  " if done else "◇  ") + title, _launch.bind(i))
        task.disabled = done
        _label(content,Campaign.task_description(chapter,i,locale),13,Color("#d7d5d0"))
    if Campaign.ready(chapter):
        _label(content,t("✓ Alle Bosse und Challenges geschafft. Der nächste Realm ist frei!","✓ All bosses and challenges complete. Next realm unlocked!","✓ Todos os chefes e desafios concluídos. Novo reino desbloqueado!"),16,Color("#c3f0bb"))
        _button(content,t("✦ Realm betreten","✦ Enter next realm","✦ Entrar no próximo reino"),_next_realm,true)
    elif Campaign.story_finished(chapter):
        _label(content,t("Für den nächsten Realm brauchst du 3 Bosssiege UND 3 Challenges.","The next realm requires 3 boss victories AND 3 challenges.","O próximo reino exige 3 vitórias contra chefes E 3 desafios."),14,Ui.IVORY)
    _button(content,t("‹ Zurück zum Manhwa","‹ Back to Manhwa","‹ Voltar ao Manhwa"),_back)
    _button(content,t("Zur Bibliothek","Library","Biblioteca"),_library)

func _launch(index: int) -> void:
    ZenChronicles.request_campaign_challenge(chapter,index)

func _back() -> void:
    ZenChronicles.close_campaign_challenges()
    if chapter==0: ZenChronicles.call_deferred("open_shadow_reader")
    else: ZenChronicles.call_deferred("open_abyss_reader")

func _library() -> void:
    ZenChronicles.close_campaign_challenges()
    ZenChronicles.call_deferred("open_library")

func _next_realm() -> void:
    ZenChronicles.request_campaign_breakthrough(chapter)

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
        _back()
        get_viewport().set_input_as_handled()
