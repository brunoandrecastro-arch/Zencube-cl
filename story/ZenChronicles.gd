extends CanvasLayer
## ZenCube 3D – 3x3 Chronicles reader. Does not change gameplay, bot or saves.
## Install as autoload 'ZenChronicles'. Godot 4.5 compatible.

const STORY_FILE = "res://story/chronicles.json"
const SETTINGS_FILE = "res://story/settings.json"
const STORY_LANG_FILE = "res://story/localization.json"
const GOLD = Color(0.86, 0.72, 0.47)
const CREAM = Color(0.98, 0.94, 0.84)
const MUTED = Color(0.75, 0.78, 0.77)
const Campaign = preload("res://story/ZenCampaign.gd")
const ActOne = preload("res://story/ZenActOne.gd")
const ActTwo = preload("res://story/ZenActTwo.gd")
const ActThree = preload("res://story/ZenActThree.gd")
const ActFour = preload("res://story/ZenActFour.gd")
const FractureState = preload("res://story/ZenFractureState.gd")
const Awakening = preload("res://ui/ZenCubeAwakening.gd")
var _library_tab: int = 0
var _prequel_act: int = 1
var _prequel_model: Script = ActOne
const RealmStory = preload("res://story/ZenRealmChronicles.gd")
const AbyssReader = preload("res://story/ZenAbyssReader.gd")
const ShadowReader = preload("res://story/ZenShadowReader.gd")
const EmberReader = preload("res://story/ZenEmberReader.gd")
const CelestialReader = preload("res://story/ZenCelestialReader.gd")
const ZenType = preload("res://ui/ZenRealm2Typography.gd")
const Realm2 = preload("res://core/ZenRealmCampaign2.gd")
const ChallengeMenu = preload("res://story/ZenRealmChallengeMenu.gd")
const Portal2 = preload("res://ui/ZenRealmTravelCeremony.gd")
const Realms = preload("res://core/ZenAscendRealms.gd")
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
var _screen_name := ""
var _campaign_board_active := false
var _realm_story_requested: bool = false
var _realm_story_from_realms: bool = false
var _realm_chapter_scroll: ScrollContainer
var _realm_chapter_dragging: bool = false
var _abyss_reader: CanvasLayer
var _abyss_launch_requested: bool = false
var _shadow_reader: CanvasLayer
var _shadow_launch_requested: bool = false
var _ember_reader: CanvasLayer
var _ember_launch_requested: bool = false
var _celestial_launch_requested: bool = false
var _campaign_menu: CanvasLayer
var _campaign_challenge_requested: Dictionary = {}
var _campaign_practice_requested: int = -1
var _story_audio_owner: Node
var _breakthrough_active: bool = false
var _act_one_progress: Dictionary = {}
var _act_one_back_owned := false
var _act_one_previous_back := true

func _ready() -> void:
    layer = 90
    _load_settings_and_chapters()
    _root = Control.new()
    _root.name = "ZenChroniclesRoot"
    var chronicle_theme: Theme = Theme.new()
    chronicle_theme.default_font = ZenType.body()
    chronicle_theme.default_font_size = 18
    _root.theme = chronicle_theme
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
    _realm_chapter_scroll = null
    _realm_chapter_dragging = false
    if _screen != null:
        _screen.hide()
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
    # Keep navigation below the Android cutout/status-bar safe region.
    # The game viewport may already be letterboxed; cap the additional inset
    # so tall phones retain enough space for the chapter list and action.
    var top_margin: int = 18
    if OS.get_name() == "Android":
        var safe: Rect2i = DisplayServer.get_display_safe_area()
        var window: Vector2i = DisplayServer.window_get_size()
        if window.y > 0 and safe.position.y > 0:
            top_margin = maxi(28, mini(58, roundi(float(safe.position.y) * get_viewport().get_visible_rect().size.y / float(window.y)) + 12))
        else:
            top_margin = 28
    margins.add_theme_constant_override("margin_top", top_margin)
    margins.add_theme_constant_override("margin_bottom", 18)
    var outer := VBoxContainer.new()
    margins.add_child(outer)
    outer.add_theme_constant_override("separation", 10)
    return outer

func _chapter_accessible(i: int) -> bool:
    if i == 0 or _preview_all:
        return true
    # Same world lock rule as the existing in-game "Welten" screen.
    var ascension := load("res://core/ZenAscension.gd") as GDScript
    var saved: Dictionary = SaveManager.load_data()
    return ascension.world_unlocked(saved, i)

func campaign_ui(de: String,en: String,pt: String) -> String:
    return de if _active_language=="de" else (pt if _active_language=="pt" else en)

func _select_library_tab(index: int) -> void:
    _library_tab = clampi(index,0,1)
    open_library()

func _library_card(parent: Node, title: String, image_path: String, hint: String, allowed: bool, complete: bool, entry: Callable, tag: String, show_lock_info: bool = false) -> void:
    var panel: PanelContainer = PanelContainer.new()
    panel.name = tag
    var background: StyleBoxFlat = _style(Color("#182d33"),16)
    background.border_color = Color("#a58b5e") if allowed else Color("#555661")
    background.set_border_width_all(2)
    panel.add_theme_stylebox_override("panel",background)
    parent.add_child(panel)
    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override("separation",12)
    panel.add_child(row)
    var preview: TextureRect = TextureRect.new()
    preview.custom_minimum_size = Vector2(90,128)
    preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if ResourceLoader.exists(image_path): preview.texture = load(image_path) as Texture2D
    row.add_child(preview)
    var stack: VBoxContainer = VBoxContainer.new()
    stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stack.add_theme_constant_override("separation",5)
    row.add_child(stack)
    var headline: Label = _make_label(title,stack,17,CREAM)
    headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _make_label(hint,stack,13,Color("#d5c19b") if allowed else MUTED)
    var label_text: String = campaign_ui("Geschichte lesen ›","Continue Story ›","Continuar história ›") if allowed else (campaign_ui("Freischaltbedingungen","Unlock requirements","Como desbloquear") if show_lock_info else campaign_ui("Gesperrt","Locked","Bloqueado"))
    if complete: label_text = campaign_ui("Erneut lesen ›","Read again ›","Ler novamente ›")
    var button: Button = _make_button(label_text,stack,entry)
    button.disabled = not allowed and not show_lock_info
    button.custom_minimum_size.y = 40
    button.name = tag+"Button"

func _library_story_cards(parent: VBoxContainer) -> void:
    _make_label(campaign_ui("Kuzes Weg · 3×3","Kuze's Path · 3×3","O Caminho de Kuze · 3×3"),parent,18,GOLD)
    var active_game: Node = get_tree().current_scene
    var playable: bool = active_game != null and active_game.has_method("start_act_one_trial")
    if not playable:
        _make_label(campaign_ui("Wechsle zum klassischen 3×3, um diese Geschichte zu spielen.","Return to Classic 3×3 to play this story.","Regressa ao Clássico 3×3 para jogar esta história."),parent,14,MUTED)
    var classic: Dictionary = SaveManager.load_data()
    _library_card(parent,"ACT I · The Roots of Peace","res://story/act01/pages/zen_chronicles_ch01_act01_01.png","Zen Garden",playable,bool(ActOne.load_progress().complete),open_act_one,"ActOneCard")
    var second_allowed: bool = ActTwo.unlocked(classic) and ActTwo.media_ready() and playable
    var second_hint: String = "Bamboo Path · "+campaign_ui("Leicht %d/3","Easy %d/3","Fácil %d/3") % ActTwo.easy_wins(classic)
    if not bool(ActOne.load_progress().complete): second_hint += " · "+campaign_ui("Akt I abschließen","Finish Act I","Concluir Ato I")
    _library_card(parent,"ACT II · The Art of Balance",ActTwo.page_path(1),second_hint,second_allowed,bool(ActTwo.load_progress().complete),open_act_two,"ActTwoCard")
    var third_allowed: bool = ActThree.unlocked(classic) and ActThree.media_ready() and playable
    var third_hint: String = "Mountain Temple · "+campaign_ui("Mittel %d/5","Medium %d/5","Médio %d/5") % ActThree.medium_wins(classic)
    if not bool(ActTwo.load_progress().complete): third_hint += " · "+campaign_ui("Akt II abschließen","Finish Act II","Concluir Ato II")
    _library_card(parent,"ACT III · The Beautiful Imperfection",ActThree.page_path(1),third_hint,third_allowed,bool(ActThree.load_progress().complete),open_act_three,"ActThreeCard")
    var fourth_allowed: bool = ActFour.unlocked(classic) and ActFour.media_ready() and playable
    var fourth_hint: String = "Moon Garden · "+campaign_ui("Schwer %d/7","Hard %d/7","Difícil %d/7") % ActFour.hard_wins(classic)
    if not bool(ActThree.load_progress().complete): fourth_hint += " · "+campaign_ui("Akt III abschließen","Finish Act III","Concluir Ato III")
    _library_card(parent,"ACT IV · The Day Everything Broke",ActFour.page_path(1),fourth_hint,fourth_allowed,bool(ActFour.load_progress().complete),open_act_four,"ActFourCard")
    _make_label(campaign_ui("Sky Garden · Epilog nach Abschluss aller Realms","Sky Garden · Epilogue after all Realms","Sky Garden · Epílogo após todos os Reinos"),parent,14,MUTED)

func _library_realm_cards(parent: VBoxContainer) -> void:
    _make_label(campaign_ui("Zen Ascend · 4×4","Zen Ascend · 4×4","Zen Ascend · 4×4"),parent,18,GOLD)
    var openers: Array[Callable] = [open_shadow_reader,open_abyss_reader,open_ember_campaign_preview,open_celestial_campaign_preview,open_satori_campaign_preview]
    var titles: Array[String] = ["🌘 Shadow Realm","🌊 Abyss of Memories","🔥 Ember Temple","☁️ Celestial Realm","☀️ Satori Realm"]
    var unlock_hints: Array[String] = ["Zen Ascend 4×4","Shadow 3/3 + 3/3","Abyss 3/3 + 3/3","Ember 3/3 + 3/3","Celestial 3/3 + 3/3"]
    for i in range(5):
        var permitted: bool = Realm2.unlocked(i)
        var finished: bool = Realm2.story_finished(i)
        var hint: String = campaign_ui("Bosse %d/3 · Herausforderungen %d/3","Bosses %d/3 · Challenges %d/3","Chefes %d/3 · Desafios %d/3") % [Realm2.bosses_won(i),Realm2.completed_count(Realm2.load_progress(),i)] if permitted else campaign_ui("Freischalten: ","Unlock: ","Desbloquear: ")+unlock_hints[i]
        _library_card(parent,titles[i],Realm2.SOURCE_ART[i],hint,permitted,finished,openers[i],"RealmCard%d" % i,true)

func open_library() -> void:
    _act_one_release_back()
    _realm_story_from_realms = false
    _sync_language()
    _active_chapter = -1
    _screen_name = "library"
    var outer: VBoxContainer = _make_screen()
    var head: HBoxContainer = HBoxContainer.new()
    outer.add_child(head)
    var heading: Label = _make_label("ZEN CHRONICLES",head,24,GOLD)
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _make_button("✕",head,close_chronicles)
    var tabs: HBoxContainer = HBoxContainer.new()
    tabs.add_theme_constant_override("separation",8)
    outer.add_child(tabs)
    var story_tab: Button = _make_button("Story · 3×3",tabs,_select_library_tab.bind(0))
    story_tab.name = "ZenChroniclesTab3"
    story_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var realm_tab: Button = _make_button("Realms · 4×4",tabs,_select_library_tab.bind(1))
    realm_tab.name = "ZenChroniclesTab4"
    realm_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var active_tab: Button = story_tab if _library_tab==0 else realm_tab
    active_tab.add_theme_stylebox_override("normal",_style(Color("#5c4930"),12))
    active_tab.add_theme_color_override("font_color",Color("#ffe2a3"))
    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    outer.add_child(scroll)
    var cards: VBoxContainer = VBoxContainer.new()
    cards.name = "ZenChroniclesCards"
    cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cards.add_theme_constant_override("separation",12)
    scroll.add_child(cards)
    if _library_tab==0: _library_story_cards(cards)
    else: _library_realm_cards(cards)

func open_comic_library() -> void:
    _sync_language()
    _active_chapter = -1
    _screen_name = "comics"
    var outer := _make_screen()
    var head := HBoxContainer.new()
    outer.add_child(head)
    _make_button("‹", head, open_library)
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
    _screen_name = "reader"
    var outer := _make_screen()
    var top := HBoxContainer.new()
    outer.add_child(top)
    _make_button("‹", top, open_comic_library)
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
        open_comic_library()
        return
    _active_page = clampi(next, 0, pages.size()-1)
    _update_page()

func close_chronicles() -> void:
    _act_one_release_back()
    _realm_story_from_realms = false
    _active_chapter = -1
    _screen_name = ""
    if _screen != null:
        _screen.hide()
        _screen.queue_free()
        _screen = null
    if _quick_button != null:
        _quick_button.visible = _show_quick and not _campaign_board_active

func set_campaign_board_active(active: bool) -> void:
    _campaign_board_active = active
    _quick_button.visible = _show_quick and not active and _screen == null

func is_open() -> bool:
    return _screen != null or is_instance_valid(_abyss_reader) or is_instance_valid(_shadow_reader) or is_instance_valid(_ember_reader) or is_instance_valid(_campaign_menu)

func _input(event: InputEvent) -> void:
    if _screen == null:
        return
    if _screen_name.begins_with("act-one"):
        _act_one_input(event)
        return
    # Godot's nested PanelContainers/TextureRects can intercept touch
    # gestures before ScrollContainer on Android. Drive this ONE chapter list
    # from native drag deltas; never change the campaign reader or 3D cube.
    if _screen_name == "realm-story" and is_instance_valid(_realm_chapter_scroll):
        if event is InputEventScreenTouch:
            if event.pressed:
                _realm_chapter_dragging = _realm_chapter_scroll.get_global_rect().has_point(event.position)
            else:
                _realm_chapter_dragging = false
        elif event is InputEventScreenDrag and _realm_chapter_dragging:
            _realm_chapter_scroll.scroll_vertical = maxi(0, _realm_chapter_scroll.scroll_vertical - roundi(event.relative.y))
            get_viewport().set_input_as_handled()
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
            match _screen_name:
                "reader":
                    open_comic_library()
                "comics", "campaign":
                    open_library()
                "realm-story":
                    _back_from_realm_story()
                _:
                    close_chronicles()
            get_viewport().set_input_as_handled()
        elif _active_chapter >= 0 and event.keycode == KEY_RIGHT:
            _turn_page(1)
            get_viewport().set_input_as_handled()
        elif _active_chapter >= 0 and event.keycode == KEY_LEFT:
            _turn_page(-1)
            get_viewport().set_input_as_handled()

func open_campaign_overview() -> void:
    _sync_language()
    _active_chapter = -1
    _screen_name = "campaign"
    var progress := Campaign.load_progress()
    var stage: int = progress.stage
    var current_chapter: int = Campaign.CHAPTER_FOR_STAGE[stage]
    var outer := _make_screen()
    _screen.color = Color("#14171a")
    var nav := HBoxContainer.new()
    nav.custom_minimum_size.y = 58
    nav.add_theme_constant_override("separation", 10)
    outer.add_child(nav)
    _make_button("‹", nav, open_library).custom_minimum_size.x = 48
    var title := _make_label(Campaign.text_for(_active_language, "title"), nav, 27, GOLD)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _make_button("✕", nav, close_chronicles).custom_minimum_size.x = 48

    var content := _campaign_scroll(outer)
    # The old fixed atlas crop cut Kuze's head off on taller Android screens.
    # Show the complete text-free hero illustration in every language.
    var hero := Campaign.artwork(Campaign.PROLOGUE_ART, 178)
    hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    content.add_child(hero)
    _make_label(Campaign.text_for(_active_language, "campaign_desc"), content, 16, CREAM)
    var action := "start_campaign" if not bool(progress.prologue_seen) else "continue_campaign"
    if stage == Campaign.EPILOGUE:
        action = "open_epilogue"
    for chapter in range(Campaign.CHAPTER_ART.size()):
        var card := PanelContainer.new()
        var border := _style(Color("#262421"), 13)
        border.border_color = GOLD if chapter == current_chapter else Color("#6a5741")
        border.set_border_width_all(1)
        card.add_theme_stylebox_override("panel", border)
        content.add_child(card)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 13)
        card.add_child(row)
        var thumb := Campaign.artwork(Campaign.CHAPTER_ART[chapter], 68, Rect2(0, 0, 640, 390))
        thumb.custom_minimum_size.x = 128
        row.add_child(thumb)
        var column := VBoxContainer.new()
        column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        column.alignment = BoxContainer.ALIGNMENT_CENTER
        column.add_theme_constant_override("separation", 2)
        row.add_child(column)
        var state := "locked"
        if chapter < current_chapter or stage >= Campaign.EPILOGUE:
            state = "completed"
        elif chapter == current_chapter:
            state = "current"
        var chapter_label := Campaign.text_for(_active_language, "chapter_label") % (chapter + 1)
        _make_label(chapter_label + " · " + Campaign.text_for(_active_language, state), column, 13, GOLD)
        _make_label(Campaign.text_for(_active_language, "chapter_%d" % chapter), column, 20)
        _make_label(Campaign.text_for(_active_language, "theme_%d" % chapter), column, 14, MUTED)
    _campaign_primary(Campaign.text_for(_active_language, action), outer, _launch_campaign)

func _campaign_scroll(parent: VBoxContainer) -> VBoxContainer:
    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.scroll_deadzone = 12
    parent.add_child(scroll)
    var content := VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 9)
    scroll.add_child(content)
    return content

func _campaign_primary(value: String, parent: Node, callback: Callable) -> void:
    var action := _make_button(value, parent, callback)
    action.custom_minimum_size.y = 54
    action.add_theme_font_size_override("font_size", 18)
    action.add_theme_stylebox_override("normal", _style(Color("#73392d"), 13))
    action.add_theme_stylebox_override("hover", _style(Color("#8d4738"), 13))
    action.add_theme_stylebox_override("pressed", _style(Color("#592d26"), 13))

func _launch_campaign() -> void:
    var game: Node = get_tree().current_scene
    if game != null and game.has_method("start_zen_campaign"):
        game.call("start_zen_campaign")

# Realm Chronicles – optional 4x4 chapter campaign, never affects the existing
# 3x3 campaign or Webcomic. The actual gameplay takes place in Ascend.tscn.
func open_realm_story_overview(from_realms: bool = false) -> void:
    _realm_story_from_realms = from_realms
    _sync_language()
    _active_chapter = -1
    _screen_name = "realm-story"
    var saved: Dictionary = SaveManager.load_data()
    var progress: Dictionary = RealmStory.load_progress()
    var stage: int = int(progress.stage)
    var outer: VBoxContainer = _make_screen()
    _screen.color = Color("#151b25")
    var navigation: HBoxContainer = HBoxContainer.new()
    navigation.custom_minimum_size.y = 56
    outer.add_child(navigation)
    _make_button("‹", navigation, _back_from_realm_story).custom_minimum_size.x = 48
    var title: Label = _make_label(RealmStory.text_for(_active_language,"story"), navigation, 24, GOLD)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _make_button("✕", navigation, close_chronicles).custom_minimum_size.x = 48
    var body: VBoxContainer = _campaign_scroll(outer)
    _realm_chapter_scroll = body.get_parent() as ScrollContainer
    _realm_chapter_scroll.name = "RealmChroniclesChapterScroll"
    _realm_chapter_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
    body.mouse_filter = Control.MOUSE_FILTER_PASS
    _make_label(RealmStory.text_for(_active_language,"intro"), body, 15, CREAM)
    for chapter in range(4):
        var completed: bool = stage >= (chapter+1)*3
        var allowed: bool = stage >= chapter*3 and RealmStory.can_enter(saved,chapter*3)
        var panel: PanelContainer = PanelContainer.new()
        var box_style: StyleBoxFlat = _style(Color("#252c35") if chapter % 2 == 0 else Color("#382c29"), 14)
        box_style.border_color = GOLD if int(stage / 3) == chapter else Color("#76624a")
        box_style.set_border_width_all(1)
        panel.add_theme_stylebox_override("panel", box_style)
        panel.mouse_filter = Control.MOUSE_FILTER_PASS
        body.add_child(panel)
        var section: VBoxContainer = VBoxContainer.new()
        section.mouse_filter = Control.MOUSE_FILTER_PASS
        section.add_theme_constant_override("separation",7)
        panel.add_child(section)
        var key: String = ["shadow","ember","celestial","satori"][chapter]
        _make_label(RealmStory.text_for(_active_language,key), section, 19, GOLD)
        var picture: TextureRect = Campaign.artwork(RealmStory.CHAPTER_ART[chapter],105)
        picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
        section.add_child(picture)
        _make_label(RealmStory.text_for(_active_language,key+"_sub"),section,13,MUTED)
        var challenge_wins: int = Realms.count(saved,chapter)
        var boss_wins: int = Realms.completed_story_bosses(chapter)
        var noun: String = "Story-Bosse" if _active_language == "de" else "Chefes" if _active_language == "pt" else "Story bosses"
        _make_label("✦ %d/8 Challenges  ·  ⚔ %d/3 %s" % [challenge_wins,boss_wins,noun],section,13,GOLD)
        var progress_label: String = RealmStory.text_for(_active_language,"completed" if completed else ("current" if allowed else "locked"))
        _make_label(progress_label,section,13,GOLD if allowed or completed else MUTED)
        if not allowed and not completed:
            var lock_key: String = ["gate_mode","gate","gate_celestial","gate_satori"][chapter]
            _make_label(RealmStory.text_for(_active_language,lock_key),section,12,MUTED)
        if RealmStory.qa_mode() and chapter > 0:
            var qa_key: String = ["","qa_ember","qa_celestial","qa_satori"][chapter]
            var qa_button: Button = _make_button(RealmStory.text_for(_active_language,qa_key),section,_launch_chapter_qa.bind(chapter*RealmStory.CHAPTER_SIZE))
            qa_button.add_theme_stylebox_override("normal",_style(Color("#693524") if chapter == 1 else Color("#36586a") if chapter == 2 else Color("#625079"),13))
    if stage >= RealmStory.LAST_STAGE:
        _make_label(RealmStory.text_for(_active_language,"realm_story_completed"),outer,15,CREAM)
    elif RealmStory.can_enter(saved,stage):
        _campaign_primary(RealmStory.text_for(_active_language,"continue"),outer,_launch_realm_story)
    else:
        _make_label(RealmStory.text_for(_active_language,"challenge_unlock"),outer,13,MUTED)

# A Realm-menu entry returns to the four 4x4 Realm cards; the existing
# Chronicles library entry still returns to the library as before.
func _back_from_realm_story() -> void:
    if not _realm_story_from_realms:
        open_library()
        return
    close_chronicles()
    var active_scene: Node = get_tree().current_scene
    if active_scene != null and active_scene.scene_file_path == "res://Ascend.tscn" and active_scene.has_method("show_realms"):
        active_scene.call_deferred("show_realms")

func _launch_realm_story() -> void:
    # Do not discard an unfinished ordinary Ascend match.
    var active_scene: Node = get_tree().current_scene
    if active_scene != null and active_scene.scene_file_path == "res://Ascend.tscn" and active_scene.has_method("move_count"):
        if int(active_scene.call("move_count")) > 0 and int(active_scene.get("result")) == 0:
            var warning: VBoxContainer = _make_screen()
            _screen_name = "realm-story"
            _make_label(RealmStory.text_for(_active_language,"finish_active"),warning,18,CREAM)
            _make_button(RealmStory.text_for(_active_language,"back"),warning,open_realm_story_overview)
            return
    var saved: Dictionary = SaveManager.load_data()
    var progress: Dictionary = RealmStory.load_progress()
    if not RealmStory.can_enter(saved,int(progress.stage)):
        open_realm_story_overview(_realm_story_from_realms)
        return
    # One-use handoff avoids touching the 4x4 Classic/Ascend save data.
    _realm_story_requested = true
    close_chronicles()
    get_tree().call_deferred("change_scene_to_file","res://Ascend.tscn")

# Test-APK only: preview specific chapters while preserving normal 4x4
# progression, economy, scores, and an unfinished regular Ascend match.
# Only this separately signed package sets the QA project setting.
func _launch_chapter_qa(target_stage: int) -> void:
    if not RealmStory.qa_mode() or target_stage not in [3,6,9]: return
    var active_scene: Node = get_tree().current_scene
    if active_scene != null and active_scene.scene_file_path == "res://Ascend.tscn" and active_scene.has_method("move_count"):
        if int(active_scene.call("move_count")) > 0 and int(active_scene.get("result")) == 0:
            var warning: VBoxContainer = _make_screen()
            _screen_name = "realm-story"
            _make_label(RealmStory.text_for(_active_language,"finish_active"),warning,18,CREAM)
            _make_button(RealmStory.text_for(_active_language,"back"),warning,open_realm_story_overview)
            return
    var progress: Dictionary = RealmStory.load_progress()
    if int(progress.stage) < target_stage or int(progress.stage) >= target_stage+RealmStory.CHAPTER_SIZE:
        progress.stage = target_stage
        progress.game = {}
        if not RealmStory.save_progress(progress):
            push_warning("Realm Chronicles: could not start QA preview")
            return
    _launch_realm_story()

# Kept for older scripts and callers from the Chapter 2 test build.
func _launch_ember_qa() -> void:
    _launch_chapter_qa(3)

func consume_realm_story_launch() -> bool:
    var result: bool = _realm_story_requested
    _realm_story_requested = false
    return result

# An isolated reader, not a fifth normal 4x4 realm, with its own progress.
func campaign_audio_exclusive() -> bool:
    return _breakthrough_active or is_instance_valid(_story_audio_owner)

func _suspend_scene_music() -> void:
    var scene: Node = get_tree().current_scene
    if is_instance_valid(scene) and scene.has_method("suspend_campaign_music"):
        scene.call("suspend_campaign_music")

func claim_story_audio(owner: Node) -> void:
    if is_instance_valid(_story_audio_owner) and _story_audio_owner!=owner:
        _story_audio_owner.call("stop_story_audio")
    _story_audio_owner = owner
    _suspend_scene_music()

func release_story_audio(owner: Node) -> void:
    if _story_audio_owner!=owner: return
    _story_audio_owner = null
    call_deferred("_resume_scene_music_if_free")

func _resume_scene_music_if_free() -> void:
    if campaign_audio_exclusive() or _shadow_launch_requested or _abyss_launch_requested or _ember_launch_requested or _celestial_launch_requested: return
    var scene: Node = get_tree().current_scene
    if is_instance_valid(scene) and scene.has_method("resume_campaign_music"):
        scene.call("resume_campaign_music")

func request_final_guardian(chapter: int) -> void:
    if not Realm2.final_boss_waiting(chapter): return
    var scene: Node = get_tree().current_scene
    if is_instance_valid(scene) and scene.has_method("move_count") and int(scene.call("move_count"))>0 and int(scene.get("result"))==0: return
    close_campaign_challenges()
    if chapter==0: request_shadow_battle()
    elif chapter==1: request_abyss_battle()
    elif chapter==2: request_ember_battle()
    else: request_celestial_battle()

func open_abyss_reader() -> void:
    if not Realm2.unlocked(1):
        _campaign_locked_screen(1)
        return
    close_campaign_challenges()
    if is_instance_valid(_shadow_reader): close_shadow_reader()
    if is_instance_valid(_ember_reader): close_ember_reader()
    if is_instance_valid(_abyss_reader): close_abyss_reader()
    if _screen != null: close_chronicles()
    _abyss_reader = AbyssReader.new()
    _root.add_child(_abyss_reader)
    if _quick_button != null: _quick_button.hide()

func close_abyss_reader() -> void:
    if is_instance_valid(_abyss_reader):
        var old: CanvasLayer = _abyss_reader
        _abyss_reader = null
        old.call("stop_story_audio")
        release_story_audio(old)
        old.queue_free()
    if _quick_button != null and _screen == null:
        _quick_button.visible = _show_quick and not _campaign_board_active

func request_abyss_battle() -> void:
    _abyss_launch_requested = true
    close_abyss_reader()
    var current: Node = get_tree().current_scene
    if current != null and current.scene_file_path == "res://Ascend.tscn" and current.has_method("start_abyss_battle"):
        _abyss_launch_requested = false
        current.call_deferred("start_abyss_battle")
    else:
        get_tree().call_deferred("change_scene_to_file","res://Ascend.tscn")

func consume_abyss_launch() -> bool:
    var flag: bool = _abyss_launch_requested
    _abyss_launch_requested = false
    return flag

# Campaign 2.0 – Shadow Realm chapter, isolated from the existing 12
# Realm Chronicles bosses and independent of the Abyss chapter save.
func open_shadow_reader() -> void:
    if not Realm2.unlocked(0):
        _campaign_locked_screen(0)
        return
    close_campaign_challenges()
    if is_instance_valid(_abyss_reader): close_abyss_reader()
    if is_instance_valid(_shadow_reader): close_shadow_reader()
    if is_instance_valid(_ember_reader): close_ember_reader()
    if _screen != null: close_chronicles()
    _shadow_reader = ShadowReader.new()
    _root.add_child(_shadow_reader)
    if _quick_button != null: _quick_button.hide()

func close_shadow_reader() -> void:
    if is_instance_valid(_shadow_reader):
        var old: CanvasLayer = _shadow_reader
        _shadow_reader = null
        old.call("stop_story_audio")
        release_story_audio(old)
        old.queue_free()
    if _quick_button != null and _screen == null:
        _quick_button.visible = _show_quick and not _campaign_board_active

func request_shadow_battle() -> void:
    _shadow_launch_requested = true
    close_shadow_reader()
    var current: Node = get_tree().current_scene
    if current != null and current.scene_file_path == "res://Ascend.tscn" and current.has_method("start_shadow_battle"):
        _shadow_launch_requested = false
        current.call_deferred("start_shadow_battle")
    else:
        get_tree().call_deferred("change_scene_to_file","res://Ascend.tscn")

func consume_shadow_launch() -> bool:
    var flag: bool = _shadow_launch_requested
    _shadow_launch_requested = false
    return flag

func open_ember_reader() -> void:
    if not Realm2.unlocked(2):
        _campaign_locked_screen(2)
        return
    close_campaign_challenges()
    if is_instance_valid(_abyss_reader): close_abyss_reader()
    if is_instance_valid(_shadow_reader): close_shadow_reader()
    if is_instance_valid(_ember_reader): close_ember_reader()
    if _screen != null: close_chronicles()
    _ember_reader = EmberReader.new()
    _root.add_child(_ember_reader)
    if _quick_button != null: _quick_button.hide()

func close_ember_reader() -> void:
    if is_instance_valid(_ember_reader):
        var old: CanvasLayer = _ember_reader
        _ember_reader = null
        old.call("stop_story_audio")
        release_story_audio(old)
        old.queue_free()
    if _quick_button != null and _screen == null:
        _quick_button.visible = _show_quick and not _campaign_board_active

func request_ember_battle() -> void:
    _ember_launch_requested = true
    close_ember_reader()
    var current: Node = get_tree().current_scene
    if current != null and current.scene_file_path == "res://Ascend.tscn" and current.has_method("start_ember_battle"):
        _ember_launch_requested = false
        current.call_deferred("start_ember_battle")
    else:
        get_tree().call_deferred("change_scene_to_file","res://Ascend.tscn")

func consume_ember_launch() -> bool:
    var flag: bool = _ember_launch_requested
    _ember_launch_requested = false
    return flag

# ----- ZenCube 2.0 Realm – stage-aware campaign navigation -----
func _campaign_locked_screen(chapter: int) -> void:
    close_campaign_challenges()
    if is_instance_valid(_shadow_reader): close_shadow_reader()
    if is_instance_valid(_ember_reader): close_ember_reader()
    if is_instance_valid(_abyss_reader): close_abyss_reader()
    _sync_language()
    _screen_name = "realm-2-locked"
    var outer: VBoxContainer = _make_screen()
    _make_label("🔒  " + Realm2.REALM_NAMES[clampi(chapter,0,4)],outer,23,GOLD)
    if not Realm2.base_unlocked():
        _make_label(campaign_ui("Zen Ascend 4×4 muss zunächst regulär freigeschaltet werden.",
            "First unlock Zen Ascend 4×4 through normal progression.",
            "Desbloqueia primeiro o Zen Ascend 4×4 na progressão normal."),outer,17,CREAM)
    else:
        var prev: int = clampi(chapter-1,0,3)
        _make_label(campaign_ui("Bosse %d/3 + Challenges %d/3",
            "Bosses %d/3 + Challenges %d/3","Chefes %d/3 + Desafios %d/3") % [
            Realm2.bosses_won(prev),Realm2.completed_count(Realm2.load_progress(),prev)],outer,19,CREAM)
        _make_label(campaign_ui("Bosskämpfe und reguläre 4×4-Challenges sind beide erforderlich.",
            "Both story bosses and regular 4×4 challenges are required.",
            "São necessários os chefes da história e os desafios 4×4 normais."),outer,15,CREAM)
        if Realm2.unlocked(prev):
            _make_button("✦ Realm-Challenges",outer,open_campaign_challenges.bind(prev))
    _make_button(campaign_ui("‹ Zur Bibliothek","‹ Library","‹ Biblioteca"),outer,open_library)

func open_campaign_challenges(chapter: int, final_trial: bool = false) -> void:
    if chapter not in [0,1,2,3] or not Realm2.unlocked(chapter):
        _campaign_locked_screen(chapter)
        return
    if is_instance_valid(_shadow_reader): close_shadow_reader()
    if is_instance_valid(_ember_reader): close_ember_reader()
    if is_instance_valid(_abyss_reader): close_abyss_reader()
    if _screen != null: close_chronicles()
    close_campaign_challenges()
    _campaign_menu = ChallengeMenu.new()
    _campaign_menu.chapter = chapter
    _campaign_menu.final_trial = final_trial
    _root.add_child(_campaign_menu)
    if _quick_button != null: _quick_button.hide()

func close_campaign_challenges() -> void:
    if is_instance_valid(_campaign_menu):
        var old: CanvasLayer = _campaign_menu
        _campaign_menu = null
        old.queue_free()
    if is_instance_valid(_quick_button) and _screen == null:
        _quick_button.visible = _show_quick and not _campaign_board_active

func request_campaign_practice(chapter: int) -> void:
    if chapter not in [0,1,2,3] or not Realm2.unlocked(chapter): return
    _campaign_practice_requested = chapter
    close_campaign_challenges()
    var scene: Node = get_tree().current_scene
    if scene != null and scene.scene_file_path=="res://Ascend.tscn" and scene.has_method("start_campaign_practice"):
        _campaign_practice_requested = -1
        scene.call_deferred("start_campaign_practice",chapter)
    else:
        get_tree().call_deferred("change_scene_to_file","res://Ascend.tscn")

func consume_campaign_practice_launch() -> int:
    var chapter: int = _campaign_practice_requested
    _campaign_practice_requested = -1
    return chapter

# Only the chapter's Finish button may request this after page 30 and victory.
func request_campaign_breakthrough(chapter: int) -> void:
    if _breakthrough_active or chapter not in [0,1,2,3] or not Realm2.ready(chapter): return
    if not Realm2.story_finished(chapter): return
    _breakthrough_active = true
    _suspend_scene_music()
    close_campaign_challenges()
    if is_instance_valid(_shadow_reader): close_shadow_reader()
    if is_instance_valid(_ember_reader): close_ember_reader()
    if is_instance_valid(_abyss_reader): close_abyss_reader()
    var already: bool = Realm2.already_entered(chapter)
    if not Realm2.enter_next_realm(chapter):
        _breakthrough_active = false
        call_deferred("_resume_scene_music_if_free")
        return
    if already:
        _campaign_after_breakthrough(chapter)
        return
    var transition: ZenRealmTravelCeremony = Portal2.new()
    get_tree().root.add_child(transition)
    transition.finished.connect(_campaign_after_breakthrough.bind(chapter))
    var settings: Dictionary = SaveManager.load_data().get("settings",{})
    var from_art: String = Realm2.SOURCE_ART[chapter]
    var to_art: String = Realm2.SOURCE_ART[chapter+1]
    var abyss_art: String = "res://assets/abyss_of_memories/gameplay.webp"
    if ResourceLoader.exists(abyss_art):
        if chapter==0: to_art = abyss_art
        elif chapter==1: from_art = abyss_art
    transition.present(
        from_art,to_art,
        Realm2.REALM_NAMES[chapter+1],true,bool(settings.get("sound",true)),[],
        str(settings.get("language","de")))

func _campaign_after_breakthrough(chapter: int) -> void:
    _breakthrough_active = false
    if chapter==0: open_abyss_reader()
    elif chapter==1: open_ember_campaign_preview()
    elif chapter==2: open_celestial_campaign_preview()
    else: open_satori_campaign_preview()
    call_deferred("_resume_scene_music_if_free")

func open_ember_campaign_preview() -> void:
    open_ember_reader()

func open_celestial_campaign_preview() -> void:
    if not Realm2.unlocked(3):
        _campaign_locked_screen(3)
        return
    close_campaign_challenges()
    if is_instance_valid(_abyss_reader): close_abyss_reader()
    if is_instance_valid(_shadow_reader): close_shadow_reader()
    if is_instance_valid(_ember_reader): close_ember_reader()
    if _screen != null: close_chronicles()
    _ember_reader = CelestialReader.new()
    _root.add_child(_ember_reader)
    if _quick_button != null: _quick_button.hide()

func request_celestial_battle() -> void:
    _celestial_launch_requested = true
    close_ember_reader()
    var current: Node = get_tree().current_scene
    if current != null and current.scene_file_path == "res://Ascend.tscn" and current.has_method("start_celestial_battle"):
        _celestial_launch_requested = false
        current.call_deferred("start_celestial_battle")
    else:
        get_tree().call_deferred("change_scene_to_file","res://Ascend.tscn")

func consume_celestial_launch() -> bool:
    var flag: bool = _celestial_launch_requested
    _celestial_launch_requested = false
    return flag

func open_satori_campaign_preview() -> void:
    if not Realm2.unlocked(4):
        _campaign_locked_screen(4)
        return
    _sync_language()
    _screen_name = "realm-3-satori-preview"
    var outer: VBoxContainer = _make_screen()
    _make_label("The Enlightened Mind",outer,24,GOLD)
    _make_label("Satori Realm",outer,27,GOLD)
    outer.add_child(Campaign.artwork(Realm2.SOURCE_ART[4],360))
    _make_label(campaign_ui("Satori Realm freigeschaltet. Die Geschichte folgt.","Satori Realm unlocked. The story is coming.","Satori Realm desbloqueado. A história será acrescentada."),outer,16,CREAM)
    _make_button(campaign_ui("‹ Zur Bibliothek","‹ Library","‹ Biblioteca"),outer,open_library)

func open_realm_story_archive() -> void:
    # Preserve the original 12 boss story without another entrance in Realms.
    if not Realm2.base_unlocked():
        _campaign_locked_screen(0)
        return
    open_realm_story_overview()

# The prequel is independent of the original 3x3 campaign and 4x4 library.
func _act_one_hold_back() -> void:
    if not _act_one_back_owned:
        _act_one_previous_back = get_tree().quit_on_go_back
        get_tree().quit_on_go_back = false
        _act_one_back_owned = true

func _act_one_release_back() -> void:
    if _act_one_back_owned:
        get_tree().quit_on_go_back = _act_one_previous_back
        _act_one_back_owned = false

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_GO_BACK_REQUEST and _act_one_back_owned:
        _act_one_back()

func _act_one_back() -> void:
    if _screen_name == "act-one-gate":
        _open_prequel_reader()
    else:
        open_library()

func _act_one_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            _act_one_back()
            get_viewport().set_input_as_handled()
        elif _screen_name == "act-one-reader" and event.keycode in [KEY_LEFT, KEY_RIGHT]:
            _act_one_turn(1 if event.keycode == KEY_RIGHT else -1)
            get_viewport().set_input_as_handled()
    elif _screen_name == "act-one-reader" and event is InputEventScreenTouch:
        if event.pressed:
            _touch_start = event.position
        else:
            var distance: Vector2 = event.position - _touch_start
            if absf(distance.x) > 70 and absf(distance.x) > absf(distance.y) * 1.3:
                _act_one_turn(1 if distance.x < 0 else -1)
                get_viewport().set_input_as_handled()

func open_act_one() -> void:
    _prequel_act = 1
    _prequel_model = ActOne
    _open_prequel_reader()

func open_act_two() -> void:
    if not ActTwo.unlocked(SaveManager.load_data()) or not ActTwo.media_ready():
        open_library()
        return
    _prequel_act = 2
    _prequel_model = ActTwo
    _open_prequel_reader()

func open_act_three() -> void:
    if not ActThree.unlocked(SaveManager.load_data()) or not ActThree.media_ready():
        open_library()
        return
    _prequel_act = 3
    _prequel_model = ActThree
    _open_prequel_reader()

func open_act_four() -> void:
    if not ActFour.unlocked(SaveManager.load_data()) or not ActFour.media_ready():
        open_library()
        return
    _prequel_act = 4
    _prequel_model = ActFour
    _open_prequel_reader()

func _prequel_accessible() -> bool:
    if _prequel_act==4: return ActFour.unlocked(SaveManager.load_data()) and ActFour.media_ready()
    if _prequel_act==3: return ActThree.unlocked(SaveManager.load_data()) and ActThree.media_ready()
    if _prequel_act==2: return ActTwo.unlocked(SaveManager.load_data()) and ActTwo.media_ready()
    return _prequel_act==1

func _open_prequel_reader() -> void:
    if not _prequel_accessible():
        open_library()
        return
    _sync_language()
    _act_one_progress = _prequel_model.load_progress()
    _act_one_hold_back()
    _active_chapter = -1
    _screen_name = "act-one-reader"
    var outer := _make_screen()
    _screen.color = Color("#27251e")
    var head := HBoxContainer.new()
    outer.add_child(head)
    _make_button("‹", head, open_library)
    var titles: Array[String] = ["Act I · The Roots of Peace","Act II · The Art of Balance","Act III · The Beautiful Imperfection","Act IV · The Day Everything Broke"]
    var title := _make_label(titles[_prequel_act-1], head, 21, GOLD)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _make_button("✕", head, close_chronicles)
    _page_image = TextureRect.new()
    _page_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _page_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _page_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _page_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
    outer.add_child(_page_image)
    var nav := HBoxContainer.new()
    outer.add_child(nav)
    _prev_button = _make_button(campaign_ui("‹ Zurück", "‹ Previous", "‹ Anterior"), nav, _act_one_turn.bind(-1))
    _prev_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _page_counter = _make_label("", nav, 16, GOLD)
    _page_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _page_counter.custom_minimum_size.x = 68
    _next_button = _make_button("", nav, _act_one_turn.bind(1))
    _next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _act_one_update()

func _act_one_update() -> void:
    var page: int = clampi(int(_act_one_progress.page), 1, _prequel_model.max_page(_act_one_progress))
    _act_one_progress.page = page
    _page_image.texture = load(_prequel_model.page_path(page)) as Texture2D
    _page_counter.text = "%02d / 12" % page
    _prev_button.disabled = page == 1
    _next_button.text = campaign_ui("Weiter ›", "Next ›", "Seguinte ›")
    if page == 11 and _prequel_model.max_page(_act_one_progress) == 11:
        _next_button.text = campaign_ui("Prüfung ›", "Trial ›", "Prova ›")
    elif page == 12:
        _next_button.text = campaign_ui("Ins Shadow Realm", "Into the Shadow Realm", "Entrar no Shadow Realm") if _prequel_act==4 else campaign_ui("Abschließen", "Finish", "Concluir")

func _act_one_turn(direction: int) -> void:
    if _screen_name != "act-one-reader":
        return
    var page: int = int(_act_one_progress.page)
    if direction > 0 and page == 11 and _prequel_model.max_page(_act_one_progress) == 11:
        _act_one_progress.reached = true
        if _prequel_model.save_progress(_act_one_progress):
            open_act_one_gate()
        else:
            _page_counter.text = campaign_ui("Speicherfehler", "Save error", "Erro ao guardar")
        return
    if direction > 0 and page == 12:
        _act_one_progress.complete = true
        if _prequel_model.save_progress(_act_one_progress):
            if _prequel_act==4:
                _begin_moon_garden_breakthrough()
            else:
                open_library()
        else:
            _act_one_progress.complete = false
            _page_counter.text = campaign_ui("Speicherfehler", "Save error", "Erro ao guardar")
        return
    var old_page: int = page
    _act_one_progress.page = clampi(page + direction, 1, _prequel_model.max_page(_act_one_progress))
    if _prequel_model.save_progress(_act_one_progress):
        _act_one_update()
    else:
        _act_one_progress.page = old_page
        _page_counter.text = campaign_ui("Speicherfehler", "Save error", "Erro ao guardar")

func open_act_one_gate() -> void:
    if not _prequel_accessible():
        open_library()
        return
    _act_one_progress = _prequel_model.load_progress()
    if not bool(_act_one_progress.reached) or bool(_act_one_progress.acknowledged):
        _open_prequel_reader()
        return
    _act_one_hold_back()
    _screen_name = "act-one-gate"
    var outer := _make_screen()
    _screen.color = Color("#27251e")
    _make_button(campaign_ui("‹ Zurück zur Geschichte", "‹ Back to story", "‹ Voltar à história"), outer, _open_prequel_reader)
    var config: Dictionary = _prequel_model.config()
    _make_label(str(config.get("title", {}).get(_active_language, "The Zen Master")), outer, 26, GOLD)
    _make_label(str(config.get("subtitle", {}).get(_active_language, "The First Trial")), outer, 20, CREAM)
    var portrait := TextureRect.new()
    portrait.texture = load(_prequel_model.portrait_path()) as Texture2D
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
    portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
    outer.add_child(portrait)
    var saved_game: Dictionary = _act_one_progress.game
    var dialogue: Dictionary = config.get("dialogue_"+_active_language,config.get("dialogue", {}))
    var message := str(dialogue.get("intro", "Before you go, one more game. Show me what you have learned."))
    if bool(_act_one_progress.won):
        message = str(dialogue.get("victory", "Well played, Kuze. Take the cube home. Return tomorrow."))
    _make_label(message, outer, 20, CREAM)
    _make_label("Kuze · X    /    O · " + str(config.get("title", {}).get(_active_language, "The Zen Master")), outer, 15, GOLD)
    var action := campaign_ui("Prüfung beginnen", "Start trial", "Iniciar prova")
    if not saved_game.is_empty():
        action = campaign_ui("Prüfung fortsetzen", "Resume trial", "Retomar prova")
    if bool(_act_one_progress.won):
        action = campaign_ui("Zum Ergebnis", "View result", "Ver resultado")
    _make_button(action, outer, _act_one_launch)

func _act_one_launch() -> void:
    var game: Node = get_tree().current_scene
    if game != null and game.has_method("start_act_one_trial"):
        game.call("start_act_one_trial",_prequel_act)

# Act IV ends the 3×3 prequel. Play the portal only once, then open Shadow page 1.
func _begin_moon_garden_breakthrough() -> void:
    if not bool(ActFour.load_progress().complete): return
    if not ZenAscend.unlocked(SaveManager.load_data()):
        open_library()
        return
    _act_one_release_back()
    if FractureState.portal_seen():
        open_shadow_reader()
        return
    _suspend_scene_music()
    var ceremony: CanvasLayer = Awakening.new()
    get_tree().root.add_child(ceremony)
    ceremony.finished.connect(func():
        if not FractureState.mark_portal(): return
        open_shadow_reader())
    ceremony.call("present",0,str(SaveManager.load_data().get("settings",{}).get("language","en")))

# On Shadow page 1 the original 3×3 appears one last time.
# The second transition reveals the real four-by-four grid before page 2.
func shadow_first_page_awakening(continue_reading: Callable) -> void:
    if FractureState.awakening_seen() or not bool(ActFour.load_progress().complete):
        continue_reading.call()
        return
    var ceremony: CanvasLayer = Awakening.new()
    get_tree().root.add_child(ceremony)
    ceremony.finished.connect(func():
        if FractureState.mark_awakening(): continue_reading.call())
    ceremony.call("present",1,str(SaveManager.load_data().get("settings",{}).get("language","en")))

