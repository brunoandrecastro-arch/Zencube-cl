extends "res://ui/ZenMasterPrototype.gd"
# Standalone Zen Master QA campaign: 4 realms, 16 bosses, four-in-a-row on 5x5.
# The original Play app, other modes, PR #3 and existing saves are never changed.
const Story = preload("res://core/ZenMasterCampaignData.gd")
const Catalog = preload("res://core/ZenMasterStageCatalog.gd")
const BossAI = preload("res://core/ZenMasterBossAI.gd")
const REALM_MUSIC: Array[String] = [
    "res://assets/realm_music/shadow_realm.ogg",
    "res://assets/realm_music/satori_realm.ogg",
    "res://assets/realm_music/celestial_realm.ogg",
    "res://assets/realm_music/ember_temple.ogg"
]
const SAVE: String = "user://zen_master_campaign_qa_v1.cfg"
const REALM_TEXTURES: Array[String] = [
    "res://assets/realms/shadow_realm.webp",
    "res://assets/realms/satori_realm.webp",
    "res://assets/realms/celestial_realm.webp",
    "res://assets/zen_world_heaven.webp"
]
var cleared: int = 0
var current_stage: int = 0
var qa_preview: bool = false
var stage_music: AudioStreamPlayer
var stage_backdrop: Sprite3D
var base_backdrop: Sprite3D
var hud_title: Label
var hud_status: Label
var hud_progress: Label
var story_layer: ColorRect
var story_card: PanelContainer
var dialog_head: Label
var dialog_text: Label
var dialog_quote: Label
var dialog_preview: TextureRect
var dialog_action: Button
var map_layer: ColorRect
var map_scroll: VBoxContainer
var active_dialog: String = ""

func _ready() -> void:
    super._ready()
    assert(Story.validate())
    assert(Catalog.validate())
    for child in get_children():
        if child is CanvasLayer:
            child.visible = false
        if child is Sprite3D and base_backdrop == null:
            base_backdrop = child
    _read_save()
    stage_music = AudioStreamPlayer.new()
    stage_music.volume_db = -17.0
    stage_music.name = "ZenMasterRealmMusic"
    add_child(stage_music)
    _make_campaign_ui()
    _choose_stage(Story.next_stage(cleared), true)

func _read_save() -> void:
    var config: ConfigFile = ConfigFile.new()
    if config.load(SAVE) == OK:
        cleared = clampi(int(config.get_value("progress", "cleared", 0)),0,Story.BOSSES.size())
        qa_preview = bool(config.get_value("options","qa_preview",false))

func _write_save() -> void:
    var config: ConfigFile = ConfigFile.new()
    config.set_value("progress","cleared",cleared)
    config.set_value("options","qa_preview",qa_preview)
    var error: Error = config.save(SAVE)
    if error != OK:
        push_warning("Zen Master QA campaign save error: " + str(error))

func _panel_style(color: Color, border_color: Color = Color("7c6b9d")) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = border_color
    style.set_border_width_all(1)
    style.set_corner_radius_all(13)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 11
    style.content_margin_bottom = 11
    return style

func _ui_label(text_value: String, font: int = 16, tint: Color = Color("f6eeda")) -> Label:
    var l: Label = Label.new()
    l.text = text_value
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size",font)
    l.add_theme_color_override("font_color",tint)
    return l

func _ui_button(caption: String, action: Callable) -> Button:
    var button: Button = Button.new()
    button.text = caption
    button.add_theme_font_size_override("font_size",15)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.pressed.connect(action)
    return button

func _make_campaign_ui() -> void:
    var canvas: CanvasLayer = CanvasLayer.new()
    canvas.layer = 3
    add_child(canvas)
    var root_ui: Control = Control.new()
    root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(root_ui)

    var top: PanelContainer = PanelContainer.new()
    top.set_anchors_preset(Control.PRESET_TOP_WIDE)
    top.offset_left = 10
    top.offset_right = -10
    top.offset_top = 12
    top.offset_bottom = 158
    top.add_theme_stylebox_override("panel",_panel_style(Color("16132adf"),Color("b9a4db")))
    root_ui.add_child(top)
    var tcol: VBoxContainer = VBoxContainer.new()
    tcol.add_theme_constant_override("separation",4)
    top.add_child(tcol)
    hud_title = _ui_label("ZEN MASTER · 5×5",18,Color("f3dca7"))
    tcol.add_child(hud_title)
    hud_progress = _ui_label("4 Gewinnt · 0/16",13,Color("c8cce8"))
    tcol.add_child(hud_progress)
    hud_status = _ui_label("Du bist am Zug (X)",14)
    tcol.add_child(hud_status)
    var nav: HBoxContainer = HBoxContainer.new()
    tcol.add_child(nav)
    nav.add_child(_ui_button("Bosse",_open_map))
    nav.add_child(_ui_button("Story",_show_intro))
    nav.add_child(_ui_button("Neu",_restart_stage))
    nav.add_child(_ui_button("QA +1",_qa_next))

    var bottom: PanelContainer = PanelContainer.new()
    bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    bottom.offset_left = 16
    bottom.offset_right = -16
    bottom.offset_top = -82
    bottom.offset_bottom = -12
    bottom.add_theme_stylebox_override("panel",_panel_style(Color("16132aca")))
    root_ui.add_child(bottom)
    var hint: Label = _ui_label("4 GEWINNT · 5×5 × 6 Seiten\nDrehen · Zoomen · Tippen",14,Color("eadfbf"))
    bottom.add_child(hint)

    stage_backdrop = Sprite3D.new()
    stage_backdrop.name = "UniqueBossArena"
    stage_backdrop.pixel_size = 0.0158
    stage_backdrop.shaded = false
    stage_backdrop.position = Vector3(0,0,-9.62)
    stage_backdrop.modulate = Color(1,1,1,0.74)
    add_child(stage_backdrop)

    story_layer = ColorRect.new()
    story_layer.color = Color(0.025,0.018,0.058,0.88)
    story_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    story_layer.mouse_filter = Control.MOUSE_FILTER_STOP
    root_ui.add_child(story_layer)
    story_card = PanelContainer.new()
    story_card.anchor_left = 0.055
    story_card.anchor_right = 0.945
    story_card.anchor_top = 0.115
    story_card.anchor_bottom = 0.865
    story_card.add_theme_stylebox_override("panel",_panel_style(Color("1a1734"),Color("c6a8db")))
    story_layer.add_child(story_card)
    var story_col: VBoxContainer = VBoxContainer.new()
    story_col.add_theme_constant_override("separation",8)
    story_card.add_child(story_col)
    dialog_head = _ui_label("",20,Color("f9e5bb"))
    story_col.add_child(dialog_head)
    dialog_preview = TextureRect.new()
    dialog_preview.custom_minimum_size = Vector2(0,198)
    dialog_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
    dialog_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    dialog_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    story_col.add_child(dialog_preview)
    dialog_text = _ui_label("",15,Color("f6f1e9"))
    dialog_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
    story_col.add_child(dialog_text)
    dialog_quote = _ui_label("",14,Color("d6c0f2"))
    story_col.add_child(dialog_quote)
    dialog_action = _ui_button("Kampf starten",_dialog_advance)
    story_col.add_child(dialog_action)
    story_layer.visible = false

    map_layer = ColorRect.new()
    map_layer.color = Color(0.025,0.018,0.058,0.95)
    map_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    map_layer.mouse_filter = Control.MOUSE_FILTER_STOP
    root_ui.add_child(map_layer)
    var map_panel: PanelContainer = PanelContainer.new()
    map_panel.anchor_left = 0.04
    map_panel.anchor_right = 0.96
    map_panel.anchor_top = 0.055
    map_panel.anchor_bottom = 0.95
    map_panel.add_theme_stylebox_override("panel",_panel_style(Color("201b3a"),Color("bcb0db")))
    map_layer.add_child(map_panel)
    var map_col: VBoxContainer = VBoxContainer.new()
    map_col.add_theme_constant_override("separation",8)
    map_panel.add_child(map_col)
    map_col.add_child(_ui_label("ZEN MASTER · 16 BOSS-KÄMPFE",18,Color("f6dfa5")))
    map_col.add_child(_ui_label("Vier Realms · 4 Gewinnt · Kuze-Chronik",13))
    var toggle: CheckButton = CheckButton.new()
    toggle.text = "QA: alle Arenen freigeben (nur Testversion)"
    toggle.add_theme_font_size_override("font_size",13)
    toggle.button_pressed = qa_preview
    toggle.toggled.connect(_toggle_qa)
    map_col.add_child(toggle)
    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    map_col.add_child(scroll)
    map_scroll = VBoxContainer.new()
    map_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    map_scroll.add_theme_constant_override("separation",5)
    scroll.add_child(map_scroll)
    map_col.add_child(_ui_button("Satori-Eisbruch erneut testen",_return_to_satori))
    map_col.add_child(_ui_button("Zurück zum Würfel",_close_map))
    map_layer.visible = false

func _refresh_hud() -> void:
    if hud_title == null:
        return
    var boss: Dictionary = Story.BOSSES[current_stage]
    var realm: Dictionary = Story.REALMS[boss["realm"]]
    hud_title.text = "%s · %s" % [realm["name"],boss["name"]]
    hud_progress.text = "Boss %d/16 · Siege %d/16 · 4 GEWINNT" % [current_stage+1,cleared]
    if winner == 1:
        hud_status.text = "Sieg! Du hast %s besiegt." % boss["name"]
    elif winner == 2:
        hud_status.text = "Boss gewinnt – versuch es erneut."
    elif winner == 3:
        hud_status.text = "Unentschieden – neuer Versuch"
    elif turn == 1:
        hud_status.text = "Du bist am Zug (X)"
    else:
        hud_status.text = "%s denkt nach …" % boss["name"]

func _set_status() -> void:
    super._set_status()
    _refresh_hud()

func _visual_path(stage: Dictionary, portrait: bool) -> String:
    # Prefer separately supplied painted WebP art. Existing vector art remains
    # a safe playable fallback while the two art bundles are reviewed/imported.
    var boss_id: String = str(stage["boss"])
    var candidate: String
    var fallback: String
    if portrait:
        candidate = "res://assets/zen_master/hires/bosses/%s.webp" % boss_id
        fallback = str(stage["portrait"])
    else:
        candidate = "res://assets/zen_master/hires/arenas/%s/%s.webp" % [stage["realm"], boss_id]
        fallback = str(stage["art"])
    return candidate if ResourceLoader.exists(candidate) else fallback

func _choose_stage(index: int, intro: bool = true) -> void:
    if not (index >= 0 and index < Story.BOSSES.size()):
        return
    if not (Story.is_unlocked(index,cleared) or qa_preview):
        return
    current_stage = index
    var boss: Dictionary = Story.BOSSES[index]
    var stage: Dictionary = Catalog.stage_for(boss["id"])
    assert(not stage.is_empty())
    var arena_texture: Texture2D = load(_visual_path(stage,false)) as Texture2D
    if arena_texture == null:
        push_error("Boss arena missing: " + stage["art"])
        return
    stage_backdrop.texture = arena_texture
    var realm_number: int = int(boss["realm"])
    if base_backdrop != null:
        base_backdrop.texture = load(REALM_TEXTURES[realm_number]) as Texture2D
        base_backdrop.modulate = [Color("706b9b99"),Color("a881a799"),Color("7a9ba899"),Color("b99c8a99")][realm_number]
        base_backdrop.pixel_size = 0.014
    stage_backdrop.modulate = [Color("dfc6ffbd"),Color("ffdcf4c1"),Color("c8ebffbe"),Color("ffeed3c4")][realm_number]
    var new_music: AudioStream = load(REALM_MUSIC[realm_number]) as AudioStream
    if new_music != stage_music.stream:
        stage_music.stop()
        stage_music.stream = new_music
        if stage_music.stream is AudioStreamOggVorbis:
            stage_music.stream.loop = true
        if stage_music.stream != null:
            stage_music.play()
    _restart(true)
    _refresh_hud()
    story_layer.visible = false
    map_layer.visible = false
    if intro:
        _show_intro()

func _show_intro() -> void:
    var boss: Dictionary = Story.BOSSES[current_stage]
    var realm: Dictionary = Story.REALMS[boss["realm"]]
    var arena: Dictionary = Catalog.stage_for(boss["id"])
    active_dialog = "intro"
    dialog_head.text = ("%s\n%s" % [realm["name"],boss["name"]])
    dialog_preview.texture = load(_visual_path(Catalog.stage_for(boss["id"]),true)) as Texture2D
    var beginning: String = ""
    if boss["rank"] == 0:
        beginning = realm["intro"] + "\n\n"
    dialog_text.text = beginning + boss["opening"] + "\n\nArena: " + arena["arena"]
    dialog_quote.text = "„%s“" % boss["challenge"]
    dialog_action.text = "Kampf starten · 4 gewinnt"
    story_layer.visible = true

func _dialog_advance() -> void:
    story_layer.visible = false
    match active_dialog:
        "win":
            if cleared >= Story.BOSSES.size():
                _open_map()
            elif current_stage < cleared and current_stage < Story.BOSSES.size()-1:
                _choose_stage(current_stage + 1,true)
            else:
                _open_map()
        "loss":
            _restart_stage()
        _:
            pass

func _show_result(won: bool) -> void:
    if not is_inside_tree():
        return
    var boss: Dictionary = Story.BOSSES[current_stage]
    active_dialog = "win" if won else "loss"
    dialog_head.text = ("SIEG · " if won else "NIEDERLAGE · ") + boss["name"]
    dialog_preview.texture = load(_visual_path(Catalog.stage_for(boss["id"]),true)) as Texture2D
    if won:
        dialog_text.text = boss["victory"] + ("\n\nNeuer Realm freigeschaltet!" if boss["rank"] == 3 and cleared < 16 else "")
        dialog_quote.text = "„%s“" % boss["wisdom"]
        dialog_action.text = "Zum nächsten Boss" if cleared < 16 else "Chronik abgeschlossen"
    else:
        dialog_text.text = "Kuze wird zurückgeworfen, aber sein Weg ist noch nicht zu Ende. Betrachte die vier Gewinnlinien und versuche eine neue Strategie."
        dialog_quote.text = "„%s“" % boss["challenge"]
        dialog_action.text = "Erneut kämpfen"
    story_layer.visible = true

func _play_move(cell: int) -> void:
    var before: int = winner
    super._play_move(cell)
    _refresh_hud()
    if before == 0 and winner != 0:
        if winner == 1:
            cleared = maxi(cleared,current_stage+1)
            _write_save()
        var was_win: bool = winner == 1
        get_tree().create_timer(0.85).timeout.connect(func() -> void:
            if is_inside_tree() and winner != 0:
                _show_result(was_win)
        )

func _bot_turn() -> void:
    if winner != 0 or not versus_bot or turn != 2:
        return
    var pick: int = BossAI.choose(cells,lines,current_stage)
    if pick >= 0:
        _play_move(pick)

func _restart_stage() -> void:
    if current_stage >= 0:
        _restart(true)
        _refresh_hud()
    story_layer.visible = false
    map_layer.visible = false

func _rebuild_map() -> void:
    for child in map_scroll.get_children():
        child.queue_free()
    for r in range(Story.REALMS.size()):
        var realm: Dictionary = Story.REALMS[r]
        var caption: Label = _ui_label("✦ %s ✦" % realm["name"],17,Color("e6d2ff"))
        map_scroll.add_child(caption)
        for pos in range(4):
            var i: int = r*4+pos
            var boss: Dictionary = Story.BOSSES[i]
            var accessible: bool = Story.is_unlocked(i,cleared) or qa_preview
            var passed: bool = i < cleared
            var label_text: String = ("%s " % ("✓" if passed else ("▸" if accessible else "🔒"))) + boss["name"]
            var b: Button = _ui_button(label_text,_select_map_stage.bind(i))
            b.disabled = not accessible
            b.custom_minimum_size = Vector2(0,39)
            map_scroll.add_child(b)

func _select_map_stage(index: int) -> void:
    if Story.is_unlocked(index,cleared) or qa_preview:
        _choose_stage(index,true)

func _open_map() -> void:
    story_layer.visible = false
    _rebuild_map()
    map_layer.visible = true

func _close_map() -> void:
    map_layer.visible = false

func _toggle_qa(enabled: bool) -> void:
    qa_preview = enabled
    _write_save()
    _rebuild_map()

func _qa_next() -> void:
    # Deliberately only in the *separate* QA package, never the shipping game.
    var target: int = (current_stage+1) % Story.BOSSES.size()
    var originally: bool = qa_preview
    qa_preview = true
    _choose_stage(target,true)
    qa_preview = originally
