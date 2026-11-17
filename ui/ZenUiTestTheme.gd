extends RefCounted
## UI Test: Sakura / deep-jade / gold treatment based on the approved concept.
## All controls remain native and interactive; the preview is an actual
## CubeRenderer showing a real 2+2 victory from WinLineGenerator.
const GOLD: Color = Color("#ddb166")
const IVORY: Color = Color("#f8e8c6")
const GREEN: Color = Color("#183c29")
const NIGHT: Color = Color("#14201a")

static func frame(color: Color, radius: int = 20, border: int = 2) -> StyleBoxFlat:
    var panel := StyleBoxFlat.new()
    panel.bg_color = color
    panel.border_color = GOLD
    panel.set_border_width_all(border)
    panel.set_corner_radius_all(radius)
    panel.content_margin_left = 12.0
    panel.content_margin_right = 12.0
    panel.content_margin_top = 8.0
    panel.content_margin_bottom = 8.0
    panel.shadow_color = Color("#070c09", 0.40)
    panel.shadow_size = 6
    panel.shadow_offset = Vector2(0, 3)
    return panel

static func install_main_theme(theme: Theme) -> void:
    theme.set_stylebox("normal", "Button", frame(GREEN, 18))
    theme.set_stylebox("hover", "Button", frame(Color("#285439"), 18))
    theme.set_stylebox("pressed", "Button", frame(Color("#345a3c"), 18))
    theme.set_stylebox("focus", "Button", frame(Color("#285439"), 18))
    theme.set_stylebox("disabled", "Button", frame(Color("#494f3e"), 18))
    for kind in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        theme.set_color(kind, "Button", IVORY)
    theme.set_color("font_disabled_color", "Button", Color("#c2b7a0"))

# Settings-specific controls: native OptionButtons and LineEdits inherit
# font colors from their own theme types, NOT from the regular Button style.
# Without these overrides, Android shows dark text against dark jade.
static func settings_field(edit: LineEdit) -> void:
    edit.custom_minimum_size.y = 54.0
    edit.add_theme_stylebox_override("normal",frame(Color("#fff6e5"),14,2))
    edit.add_theme_stylebox_override("focus",frame(Color("#fffdf2"),14,2))
    edit.add_theme_stylebox_override("read_only",frame(Color("#e6e1d7"),14,2))
    edit.add_theme_color_override("font_color",Color("#263a2e"))
    edit.add_theme_color_override("font_selected_color",Color("#fff9e9"))
    edit.add_theme_color_override("font_placeholder_color",Color("#6b6559"))
    edit.add_theme_color_override("font_uneditable_color",Color("#5b645b"))
    edit.add_theme_color_override("caret_color",Color("#8f632e"))
    edit.add_theme_color_override("selection_color",Color("#315b3d"))
    edit.add_theme_font_size_override("font_size",18)

static func settings_picker(entry: OptionButton) -> void:
    entry.custom_minimum_size.y = 54.0
    entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    entry.add_theme_stylebox_override("normal",frame(GREEN,17))
    entry.add_theme_stylebox_override("hover",frame(Color("#28543b"),17))
    entry.add_theme_stylebox_override("pressed",frame(Color("#345a3c"),17))
    entry.add_theme_stylebox_override("focus",frame(GREEN,17))
    entry.add_theme_stylebox_override("disabled",frame(Color("#455648"),17))
    for name in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
        entry.add_theme_color_override(name,IVORY)
    entry.add_theme_color_override("font_disabled_color",Color("#e2d6bb"))
    entry.add_theme_font_size_override("font_size",18)
    # The dropdown menu itself needs contrast, not only the closed picker.
    var pop: PopupMenu = entry.get_popup()
    var popup_theme: Theme = Theme.new()
    popup_theme.set_stylebox("panel","PopupMenu",frame(Color("#183c29"),12))
    popup_theme.set_stylebox("hover","PopupMenu",frame(Color("#315a3c"),9,1))
    popup_theme.set_color("font_color","PopupMenu",IVORY)
    popup_theme.set_color("font_hover_color","PopupMenu",Color("#fff9e8"))
    popup_theme.set_color("font_disabled_color","PopupMenu",Color("#dccaaa"))
    popup_theme.set_color("font_separator_color","PopupMenu",GOLD)
    pop.theme = popup_theme

static func settings_switch(toggle: CheckButton) -> void:
    toggle.custom_minimum_size.y = 54.0
    toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    toggle.add_theme_stylebox_override("normal",frame(Color("#31553a"),15))
    toggle.add_theme_stylebox_override("hover",frame(Color("#3d6445"),15))
    toggle.add_theme_stylebox_override("pressed",frame(Color("#34543b"),15))
    toggle.add_theme_stylebox_override("focus",frame(Color("#31553a"),15))
    toggle.add_theme_stylebox_override("disabled",frame(Color("#455648"),15))
    for name in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
        toggle.add_theme_color_override(name,IVORY)
    toggle.add_theme_color_override("font_disabled_color",Color("#e3d6bd"))
    toggle.add_theme_font_size_override("font_size",17)

static func caption(parent: Node, message: String, size: int, color: Color, center: bool = true) -> Label:
    var text := Label.new()
    text.text = message
    text.add_theme_font_size_override("font_size", size)
    text.add_theme_color_override("font_color", color)
    text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
    text.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(text)
    return text

static func _language_button(parent: Node, caption_text: String, action: Callable) -> Button:
    var entry := Button.new()
    entry.text = caption_text
    entry.name = "UiTestLanguage" + caption_text.substr(0, 2)
    entry.custom_minimum_size.y = 57.0
    entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    entry.focus_mode = Control.FOCUS_NONE
    entry.add_theme_font_size_override("font_size", 22)
    entry.add_theme_stylebox_override("normal", frame(GREEN, 24, 2))
    entry.add_theme_stylebox_override("hover", frame(Color("#2b5637"), 24, 2))
    entry.add_theme_stylebox_override("pressed", frame(Color("#344e32"), 24, 2))
    for kind in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        entry.add_theme_color_override(kind, IVORY)
    entry.pressed.connect(action)
    parent.add_child(entry)
    return entry

static func winning_example() -> Array:
    # A valid two-by-two line across the FRONT and RIGHT cube faces,
    # drawn from the game's real 108 winning lines, never invented geometry.
    var lines: Array = RulesEngine.new().lines
    for line in lines:
        if line.size() != 4: continue
        if CubeGeometry.face(int(line[0])) == 0 and CubeGeometry.face(int(line[1])) == 0 and CubeGeometry.face(int(line[2])) == 3 and CubeGeometry.face(int(line[3])) == 3:
            return line.duplicate()
    # Defensive fallback: still show a legal 2+2 line, not a false victory.
    for i in range(1, lines.size(), 3):
        return lines[i].duplicate()
    return []

static func _make_preview(parent: Node) -> void:
    var frame_panel := PanelContainer.new()
    frame_panel.name = "UiTestCubeFrame"
    frame_panel.add_theme_stylebox_override("panel", frame(Color("#263322", 0.85), 21))
    parent.add_child(frame_panel)

    var stage := Control.new()
    stage.name = "UiTestPreviewStage"
    stage.custom_minimum_size = Vector2(0, 282)
    frame_panel.add_child(stage)
    var backdrop := TextureRect.new()
    backdrop.texture = load("res://assets/zen_garden_scene.webp")
    backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    backdrop.modulate = Color("#b7a987", 0.74)
    stage.add_child(backdrop)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var preview_view := SubViewport.new()
    preview_view.name = "UiTestCubeViewport"
    preview_view.size = Vector2i(640, 640)
    preview_view.transparent_bg = true
    preview_view.own_world_3d = true
    preview_view.msaa_3d = Viewport.MSAA_4X
    preview_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    stage.add_child(preview_view)

    var preview_cube := CubeRenderer.new()
    preview_cube.name = "UiTestCubeRenderer"
    preview_view.add_child(preview_cube)
    preview_cube.apply_skin(0) # Real free 'Klassischer Zen' stone material.
    var demo := BoardModel.new()
    var win: Array = winning_example()
    if win.size() == 4:
        for cell in win:
            demo.cells[int(cell)] = 2 # Real blue/teal O markers.
        demo.win_lines = [win]
        demo.winner = 2
        # Only a few decorative X; never overwrite the four winning O.
        for cell in [0, 2, 6, 8, 11, 14]:
            if not win.has(cell): demo.cells[cell] = 1
    stage.set_meta("winning_line", win)
    preview_cube.paint(demo, false)
    preview_cube.focus_faces([0, 3])
    preview_cube.camera.position.z = 8.3

    var surface := TextureRect.new()
    surface.name = "UiTestRealCubeView"
    surface.texture = preview_view.get_texture()
    surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    surface.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stage.add_child(surface)
    surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func show_language_selection(popup: PanelContainer, box: VBoxContainer, on_language: Callable) -> void:
    popup.name = "UiTestLanguageOverlay"
    popup.add_theme_stylebox_override("panel", frame(Color("#101914", 0.93), 27, 3))
    popup.offset_left = 13
    popup.offset_right = -13
    popup.offset_top = 13
    popup.offset_bottom = -13
    box.add_theme_constant_override("separation", 10)

    var header: Label = box.get_child(0) as Label
    header.text = "ZenCube 3D"
    header.name = "UiTestTitle"
    header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    header.add_theme_font_size_override("font_size", 37)
    header.add_theme_color_override("font_color", GOLD)
    var old_back: Button = box.get_child(1) as Button
    old_back.hide()

    caption(box, "— A Calm Strategy Puzzle —", 16, IVORY)
    var subheading := caption(box, "Deutsch  ·  English  ·  Português", 15, GOLD)
    subheading.name = "UiTestLanguagesHeading"
    _language_button(box, "🇩🇪  Deutsch", on_language.bind("de"))
    _language_button(box, "🇬🇧  English", on_language.bind("en"))
    _language_button(box, "🇵🇹  Português", on_language.bind("pt"))
    _make_preview(box)
    var victory := caption(box, "勝利  |  VIER IN EINER REIHE", 16, GOLD)
    victory.name = "UiTestVictoryCaption"
    caption(box, "Vier Zeichen über die Kante – 2 + 2", 14, IVORY)
