extends CanvasLayer
## ZenCube 3D – 3x3 Chronicles reader. Does not change gameplay, bot or saves.
## Install as autoload 'ZenChronicles'. Godot 4.5 compatible.

const ASC = preload("res://core/ZenAscension.gd")
const STORY_FILE = "res://story/chronicles.json"
const SETTINGS_FILE = "res://story/settings.json"
const STORY_LANG_FILE = "res://story/localization.json"
const GOLD = Color(0.86, 0.72, 0.47)
const CREAM = Color(0.98, 0.94, 0.84)
const MUTED = Color(0.75, 0.78, 0.77)
# German is the authored source language; EN and PT-PT live in a separate JSON.
const UI_DE: Dictionary = {
    "library_tip": "Zen-Chroniken",
    "library_header": "ZEN-CHRONIKEN",
    "tagline": "Die Reise zum inneren Gleichgewicht",
    "summary": "5 Kapitel · je 4 Bilder · Zen-Garten (3×3)",
    "chapter_row": "Kapitel %d · %s",
    "read": "Lesen  ›",
    "locked": "🔒 Noch gesperrt",
    "unlock_hint": "Neue Kapitel folgen den bereits freigeschalteten Welten.",
    "reader_row": "%s · Kapitel %d",
    "previous": "‹ Zurück",
    "next": "Weiter ›",
    "chapters": "Kapitelübersicht",
    "swipe_help": "← Wischen →  ·  Story-Titel ändern keine Spielränge",
    "reward": "✦ Titel: ",
}

var _chapters: Array = []
var _story_languages: Dictionary = {}
var _active_language: String = "de"
var _root: Control
var _screen: ColorRect
var _quick_button: Button
var _active_chapter: int = -1
var _active_page: int = 0
var _page_image: TextureRect
var _page_text: RichTextLabel
var _page_counter: Label
var _prev_button: Button
var _next_button: Button
var _touch_start: Vector2 = Vector2.ZERO
var _preview_all: bool = false
var _show_quick: bool = true

func _ready() -> void:
    layer = 90
    _load_settings_and_chapters()
    _root = Control.new()
    _root.name = "ZenChroniclesRoot"
    _root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_root)
    _root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _quick_button = Button.new()
    _quick_button.text = "📖"
    _quick_button.tooltip_text = _t("library_tip")
    _quick_button.add_theme_font_size_override("font_size", 22)
    _quick_button.add_theme_stylebox_override("normal", _style(Color(0.12, 0.19, 0.21, 0.96), 22))
    _quick_button.add_theme_color_override("font_color", GOLD)
    _root.add_child(_quick_button)
    _quick_button.anchor_left = 0.0
    _quick_button.anchor_right = 0.0
    _quick_button.anchor_top = 1.0
    _quick_button.anchor_bottom = 1.0
    _quick_button.offset_left = 12
    _quick_button.offset_right = 70
    _quick_button.offset_top = -78
    _quick_button.offset_bottom = -20
    _quick_button.visible = _show_quick
    _quick_button.pressed.connect(open_library)

func _load_settings_and_chapters() -> void:
    var cfg: Variant = _read_json(SETTINGS_FILE)
    if cfg is Dictionary:
        _preview_all = bool(cfg.get("preview_all_chapters", false))
        _show_quick = bool(cfg.get("show_floating_button", true))
    var manifest: Variant = _read_json(STORY_FILE)
    if manifest is Dictionary:
        _chapters = manifest.get("chapters", [])
    if _chapters.size() != 5:
        push_warning("Zen-Chroniken: Erwartet 5 Kapitel, gefunden %d" % _chapters.size())
    var languages: Variant = _read_json(STORY_LANG_FILE)
    if languages is Dictionary:
        _story_languages = languages
    _sync_language()

func _sync_language() -> void:
    # Read the SAME persisted language setting used by GameController.
    # Recheck whenever the user opens the library: changing language in Settings
    # does not require a restart and never changes saved game progression.
    var saved: Dictionary = SaveManager.load_data()
    var cfg: Dictionary = saved.get("settings", {})
    var code: String = str(cfg.get("language", "de"))
    _active_language = code if code in ["de", "en", "pt"] else "de"
    if _quick_button != null:
        _quick_button.tooltip_text = _t("library_tip")

func _t(key: String) -> String:
    if _active_language != "de":
        var locale: Dictionary = _story_languages.get(_active_language, {})
        var ui_texts: Dictionary = locale.get("ui", {})
        if ui_texts.has(key):
            return str(ui_texts[key])
    return str(UI_DE.get(key, key))

func _chapter_field(chapter_index: int, key: String) -> String:
    var source: Dictionary = _chapters[chapter_index]
    if _active_language != "de":
        var locale: Dictionary = _story_languages.get(_active_language, {})
        var translated: Array = locale.get("chapters", [])
        if chapter_index < translated.size() and translated[chapter_index] is Dictionary:
            return str(translated[chapter_index].get(key, source.get(key, "")))
    return str(source.get(key, ""))

func _page_field(chapter_index: int, page_index: int, key: String) -> String:
    var source_chapter: Dictionary = _chapters[chapter_index]
    var source_pages: Array = source_chapter.get("pages", [])
    var source_page: Dictionary = source_pages[page_index]
    if _active_language != "de":
        var locale: Dictionary = _story_languages.get(_active_language, {})
        var translated: Array = locale.get("chapters", [])
        if chapter_index < translated.size() and translated[chapter_index] is Dictionary:
            var pages: Array = translated[chapter_index].get("pages", [])
            if page_index < pages.size() and pages[page_index] is Dictionary:
                return str(pages[page_index].get(key, source_page.get(key, "")))
    return str(source_page.get(key, ""))

func _format_quote(value: String) -> String:
    # Some older German quote fields contain extra closing quotation marks.
    # Strip them safely without altering the original manuscript.
    var clean: String = value.strip_edges()
    while clean.begins_with("„") or clean.begins_with("“") or clean.begins_with("\""):
        clean = clean.substr(1).strip_edges()
    while clean.ends_with("“") or clean.ends_with("”") or clean.ends_with("\""):
        clean = clean.substr(0, clean.length() - 1).strip_edges()
    if _active_language == "en":
        return "“" + clean + "”"
    return "„" + clean + "“"

func _read_json(path: String) -> Variant:
    if not FileAccess.file_exists(path):
        push_warning("Zen-Chroniken: Datei fehlt: " + path)
        return null
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return null
    var data: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    return data

func _style(bg: Color, rounding: int = 16) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.border_color = GOLD
    s.set_border_width_all(2)
    s.set_corner_radius_all(rounding)
    s.set_content_margin_all(9)
    return s

func _make_label(value: String, parent: Node, size: int = 18, tint: Color = CREAM) -> Label:
    var l := Label.new()
    l.text = value
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", tint)
    parent.add_child(l)
    return l

func _make_button(value: String, parent: Node, callback: Callable) -> Button:
    var b := Button.new()
    b.text = value
    b.focus_mode = Control.FOCUS_NONE
    b.custom_minimum_size.y = 48
    b.add_theme_font_size_override("font_size", 16)
    b.add_theme_stylebox_override("normal", _style(Color(0.18, 0.25, 0.26), 12))
    b.add_theme_stylebox_override("pressed", _style(Color(0.30, 0.36, 0.31), 12))
    b.add_theme_stylebox_override("hover", _style(Color(0.24, 0.32, 0.32), 12))
    b.add_theme_color_override("font_color", CREAM)
    b.add_theme_color_override("font_disabled_color", MUTED)
    parent.add_child(b)
    b.pressed.connect(callback)
    return b

func _make_screen() -> VBoxContainer:
    if _screen != null:
        _screen.queue_free()
        _screen = null
    _screen = ColorRect.new()
    _screen.color = Color(0.06, 0.11, 0.15, 0.99)
    _screen.mouse_filter = Control.MOUSE_FILTER_STOP
    _root.add_child(_screen)
    _screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    if _quick_button != null:
        _quick_button.hide()
    var margins := MarginContainer.new()
    _screen.add_child(margins)
    margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margins.add_theme_constant_override("margin_left", 13)
    margins.add_theme_constant_override("margin_right", 13)
    margins.add_theme_constant_override("margin_top", 18)
    margins.add_theme_constant_override("margin_bottom", 18)
    var outer := VBoxContainer.new()
    margins.add_child(outer)
    outer.add_theme_constant_override("separation", 10)
    return outer

func _chapter_accessible(i: int) -> bool:
    if i == 0 or _preview_all:
        return true
    # Same world lock rule as the existing in-game "Welten" screen.
    var saved: Dictionary = SaveManager.load_data()
    return ASC.world_unlocked(saved, i)

func open_library() -> void:
    _sync_language()
    _active_chapter = -1
    var outer := _make_screen()
    var head := HBoxContainer.new()
    outer.add_child(head)
    var heading := _make_label(_t("library_header"), head, 24, GOLD)
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _make_button("✕", head, close_chronicles)
    _make_label(_t("tagline"), outer, 15, MUTED)
    _make_label(_t("summary"), outer, 13, MUTED)
    var line := HSeparator.new()
    outer.add_child(line)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    outer.add_child(scroll)
    var cards := VBoxContainer.new()
    cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cards.add_theme_constant_override("separation", 12)
    scroll.add_child(cards)
    for i in range(_chapters.size()):
        var entry: Dictionary = _chapters[i]
        var unlocked: bool = _chapter_accessible(i)
        var card := PanelContainer.new()
        card.add_theme_stylebox_override("panel", _style(Color(0.12, 0.18, 0.20), 14))
        cards.add_child(card)
        var content := VBoxContainer.new()
        card.add_child(content)
        _make_label(_t("chapter_row") % [i + 1, _chapter_field(i, "world")], content, 18, GOLD)
        _make_label(_chapter_field(i, "title"), content, 14, MUTED)
        var play := _make_button(_t("read") if unlocked else _t("locked"), content, open_chapter.bind(i))
        play.disabled = not unlocked
    _make_label(_t("unlock_hint"), outer, 12, MUTED)

func open_chapter(i: int) -> void:
    _sync_language()
    if i < 0 or i >= _chapters.size():
        return
    if not _chapter_accessible(i):
        return
    _active_chapter = i
    _active_page = 0
    var entry: Dictionary = _chapters[i]
    var outer := _make_screen()
    var top := HBoxContainer.new()
    outer.add_child(top)
    _make_button("‹", top, open_library)
    var head := _make_label(_t("reader_row") % [_chapter_field(i, "world"), i + 1], top, 20, GOLD)
    head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _make_button("✕", top, close_chronicles)
    _make_label(_chapter_field(i, "title"), outer, 15, MUTED)
    _page_image = TextureRect.new()
    _page_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _page_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _page_image.custom_minimum_size.y = 240
    _page_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _page_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    outer.add_child(_page_image)
    var caption_box := PanelContainer.new()
    caption_box.add_theme_stylebox_override("panel", _style(Color(0.13, 0.19, 0.20), 12))
    outer.add_child(caption_box)
    _page_text = RichTextLabel.new()
    _page_text.bbcode_enabled = false
    _page_text.custom_minimum_size.y = 158
    _page_text.scroll_active = true
    _page_text.add_theme_font_size_override("normal_font_size", 16)
    _page_text.add_theme_color_override("default_color", CREAM)
    caption_box.add_child(_page_text)
    var nav := HBoxContainer.new()
    outer.add_child(nav)
    nav.add_theme_constant_override("separation", 7)
    _prev_button = _make_button(_t("previous"), nav, _turn_page.bind(-1))
    _prev_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _page_counter = _make_label("1 / 4", nav, 16, GOLD)
    _page_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _page_counter.custom_minimum_size.x = 68
    _next_button = _make_button(_t("next"), nav, _turn_page.bind(1))
    _next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _make_label(_t("swipe_help"), outer, 11, MUTED)
    _update_page()

func _update_page() -> void:
    if _active_chapter < 0 or _active_chapter >= _chapters.size():
        return
    var ch: Dictionary = _chapters[_active_chapter]
    var pages: Array = ch.get("pages", [])
    if pages.is_empty():
        return
    _active_page = clampi(_active_page, 0, pages.size() - 1)
    var p: Dictionary = pages[_active_page]
    var art_path: String = str(p.get("image", ""))
    _page_image.texture = load(art_path) if ResourceLoader.exists(art_path) else null
    var quote: String = _page_field(_active_chapter, _active_page, "quote")
    var text_content: String = _page_field(_active_chapter, _active_page, "title") + "\n\n" + _page_field(_active_chapter, _active_page, "body")
    if not quote.is_empty():
        text_content += "\n\n" + _format_quote(quote)
    if _active_page == pages.size() - 1:
        text_content += "\n\n" + _t("reward") + _chapter_field(_active_chapter, "reward")
    _page_text.text = text_content
    _page_text.scroll_to_line(0)
    _page_counter.text = "%d / %d" % [_active_page + 1, pages.size()]
    _prev_button.disabled = _active_page == 0
    _next_button.text = _t("chapters") if _active_page == pages.size() - 1 else _t("next")

func _turn_page(dir: int) -> void:
    if _active_chapter < 0:
        return
    var pages: Array = _chapters[_active_chapter].get("pages", [])
    var next: int = _active_page + dir
    if next >= pages.size():
        open_library()
        return
    _active_page = clampi(next, 0, pages.size()-1)
    _update_page()

func close_chronicles() -> void:
    _active_chapter = -1
    if _screen != null:
        _screen.queue_free()
        _screen = null
    if _quick_button != null:
        _quick_button.visible = _show_quick

func _input(event: InputEvent) -> void:
    if _screen == null:
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            _touch_start = event.position
        elif _active_chapter >= 0:
            var delta: Vector2 = event.position - _touch_start
            if absf(delta.x) > 70.0 and absf(delta.x) > absf(delta.y) * 1.3:
                _turn_page(1 if delta.x < 0 else -1)
                get_viewport().set_input_as_handled()
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            if _active_chapter >= 0:
                open_library()
            else:
                close_chronicles()
            get_viewport().set_input_as_handled()
        elif _active_chapter >= 0 and event.keycode == KEY_RIGHT:
            _turn_page(1)
            get_viewport().set_input_as_handled()
        elif _active_chapter >= 0 and event.keycode == KEY_LEFT:
            _turn_page(-1)
            get_viewport().set_input_as_handled()
