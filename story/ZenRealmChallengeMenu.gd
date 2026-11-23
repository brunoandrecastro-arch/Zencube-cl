extends CanvasLayer
## ZenCube 2.0 Realm – only Challenges grant Campaign achievements.
const Campaign = preload("res://core/ZenRealmCampaign2.gd")
const Ui = preload("res://ui/ZenUiTestTheme.gd")
const ZenType = preload("res://ui/ZenRealm2Typography.gd")
var chapter: int = 0
var final_trial: bool = false
var locale: String = "en"
var panel: Control

func _chronicles() -> Node:
    # Avoid circular script preload resolution in Godot headless Android CI.
    return get_tree().root.get_node("ZenChronicles")

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
    var art_path: String = Campaign.SOURCE_ART[chapter]
    if chapter==1 and ResourceLoader.exists("res://assets/abyss_of_memories/gameplay.webp"):
        art_path = "res://assets/abyss_of_memories/gameplay.webp"
    scenery.texture = load(art_path) if ResourceLoader.exists(art_path) else null
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
    _label(content,"The Final Trial" if final_trial else "ZenCube 2.0 Realm",27,Ui.GOLD)
    _label(content,Campaign.REALM_NAMES[chapter],22,Ui.IVORY)
    var final_ready: bool = Campaign.final_boss_waiting(chapter)
    if final_ready:
        _label(content,t("Der letzte Wächter erwartet dich.","You have proven your strength and wisdom. The final guardian awaits.","O último guardião espera por ti."),17,Ui.GOLD)
    elif final_trial:
        _label(content,t("Du bist noch nicht bereit für den letzten Wächter. Schließe die verbleibenden Prüfungen dieses Realms ab.","You are not yet ready to face the final guardian. Complete the remaining trials of this realm.","Ainda não estás preparado para enfrentar o último guardião. Completa as provas restantes deste reino."),17,Ui.IVORY)
    _label(content,t("Automatisch durch 4×4-Partien gegen den Zen-Bot","Earned automatically in regular 4×4 matches against the Zen-Bot","Conquistados automaticamente em partidas 4×4 contra o Zen-Bot"),14,Ui.IVORY)
    var cleared: int = Campaign.completed_count(Campaign.load_progress(),chapter)
    var defeated: int = Campaign.bosses_won(chapter)
    _label(content,t("Bosse: %d/3  ·  Challenges: %d/3","Bosses: %d/3  ·  Challenges: %d/3","Chefes: %d/3  ·  desafios: %d/3") % [defeated,cleared],17,Ui.GOLD)
    for i in range(3):
        var done: bool = Campaign.challenge_done(chapter,i)
        var task_card := PanelContainer.new()
        task_card.add_theme_stylebox_override("panel",Ui.frame(Color("#244334",0.95) if done else Color("#28362f",0.96),15))
        content.add_child(task_card)
        var details := VBoxContainer.new()
        details.add_theme_constant_override("separation",6)
        task_card.add_child(details)
        _label(details,("✓  " if done else "◇  ") + Campaign.task_title(chapter,i,locale),18,Ui.GOLD)
        _label(details,Campaign.task_description(chapter,i,locale),14,Ui.IVORY)
    _label(content,t("Nicht antippen: Der Fortschritt wird automatisch gezählt.","These are milestones, not selectable puzzle battles.","São objetivos automáticos, não puzzles selecionáveis."),13,Color("#b6c9b9"))
    if final_ready:
        var final_button: Button = _button(content,t("⚔ Finalen Boss betreten","⚔ Enter Final Boss","⚔ Enfrentar o chefe final"),_enter_final_boss,true)
        final_button.name = "Campaign2EnterFinalBoss"
        final_button.add_theme_stylebox_override("normal",Ui.frame(Color("#b99657"),16))
        final_button.add_theme_color_override("font_color",Ui.NIGHT)
    elif cleared==3 and defeated<3:
        _button(content,t("Geschichte fortsetzen","Continue Story","Continuar história"),_back,true)
    _button(content,t("⚔ Gegen Zen-Bot spielen","⚔ Play Zen-Bot","⚔ Jogar contra o Zen-Bot"),_play_bot,not final_ready)
    if Campaign.ready(chapter):
        var complete_text: String = t("✓ Satori abgeschlossen — Fully Aware.","✓ Satori complete — Fully Aware.","✓ Satori concluído — Fully Aware.") if chapter==4 else t("✓ Alle Bosse und Challenges geschafft. Der nächste Realm ist frei!","✓ All bosses and challenges complete. Next realm unlocked!","✓ Todos os chefes e desafios concluídos. Novo reino desbloqueado!")
        _label(content,complete_text,16,Color("#c3f0bb"))
    elif Campaign.story_finished(chapter):
        _label(content,t("Für den nächsten Realm brauchst du 3 Bosssiege UND 3 Challenges.","The next realm requires 3 boss victories AND 3 challenges.","O próximo reino exige 3 vitórias contra chefes E 3 desafios."),14,Ui.IVORY)
    _button(content,t("‹ Zurück zum Manhwa","‹ Back to Manhwa","‹ Voltar ao Manhwa"),_back)
    _button(content,t("Zur Bibliothek","Library","Biblioteca"),_library)

func _enter_final_boss() -> void:
    _chronicles().call("request_final_guardian",chapter)

func _play_bot() -> void:
    _chronicles().call("close_campaign_challenges")
    _chronicles().call_deferred("request_campaign_practice",chapter)

func _back() -> void:
    _chronicles().call("close_campaign_challenges")
    if chapter==0: _chronicles().call_deferred("open_shadow_reader")
    elif chapter==1: _chronicles().call_deferred("open_abyss_reader")
    elif chapter==2: _chronicles().call_deferred("open_ember_reader")
    elif chapter==3: _chronicles().call_deferred("open_celestial_campaign_preview")
    else: _chronicles().call_deferred("open_satori_campaign_preview")

func _library() -> void:
    _chronicles().call("close_campaign_challenges")
    _chronicles().call_deferred("open_library")

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
        _back()
        get_viewport().set_input_as_handled()
