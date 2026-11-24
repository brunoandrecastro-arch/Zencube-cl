extends VBoxContainer
## A game home with one primary journey action and a separate story library.
const Type = preload("res://ui/ZenRealm2Typography.gd")
const Journey = preload("res://story/ZenJourney.gd")
const INK := Color("#102a25")
const GOLD := Color("#d8bb7e")
const CREAM := Color("#fff2d5")
var _hero: CubeRenderer
var _time: float = 0.0

func configure(game: Node) -> void:
    name = "ZenHomeMenu"
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_theme_constant_override("separation", 9)
    var language: String = game.language_code()
    var step: Dictionary = Journey.next_step(game.data)

    var top: HBoxContainer = game.row(self)
    var profile: Button = game.button("Profil", top, game.open_profile, true)
    profile.name = "HomeProfile"
    _quiet_button(profile)
    profile.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(spacer)
    var settings: Button = game.button("⚙", top, game.open_settings, true)
    settings.name = "HomeSettings"
    settings.tooltip_text = game.T("Einstellungen")
    _quiet_button(settings)
    settings.size_flags_horizontal = Control.SIZE_SHRINK_END
    settings.custom_minimum_size.x = 44

    var title: Label = game.label("ZenCube 3D", self, 36, CREAM)
    title.add_theme_font_override("font", Type.heading())
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var tagline: Label = game.label("Denke über die Kanten hinaus.", self, 15, GOLD)
    tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    var hero := TextureRect.new()
    hero.name = "HomeCubePreview"
    hero.custom_minimum_size.y = 205
    hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(hero)
    var view := SubViewport.new()
    view.size = Vector2i(640, 640)
    view.transparent_bg = true
    view.own_world_3d = true
    view.msaa_3d = Viewport.MSAA_4X
    view.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
    add_child(view)
    _hero = CubeRenderer.new()
    view.add_child(_hero)
    _hero.apply_skin(int(game.data.economy.equipped))
    var example := BoardModel.new()
    for cell in [3, 4, 13]: example.cells[cell] = 1
    for cell in [0, 8, 14]: example.cells[cell] = 2
    _hero.paint(example, false)
    _hero.camera.position.z = 8.2
    hero.texture = view.get_texture()

    var destination: Label = game.label(game.T(ZenAscension.WORLDS[int(step.world)]), self, 18, GOLD)
    destination.name = "HomeJourneyWorld"
    destination.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var task: Label = game.label(Journey.step_caption(step, language), self, 15, CREAM)
    task.name = "HomeJourneyTask"
    task.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var count: Label = game.label(Journey.progress_caption(step, language), self, 13, GOLD)
    count.name = "HomeJourneyProgress"
    count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    count.visible = count.text != ""

    var primary_source: String = "Kampagne fortsetzen" if bool(step.started) else "Kampagne starten"
    var play: Button = game.premium_button(primary_source, self, game.resume_campaign, true)
    play.name = "HomeCampaign"
    play.custom_minimum_size.y = 66
    for state in ["normal", "hover", "pressed"]:
        play.add_theme_stylebox_override(state, _frame(Color("#dfc58b") if state == "hover" else GOLD, GOLD, 18))
    for color in ["font_color", "font_hover_color", "font_pressed_color"]:
        play.add_theme_color_override(color, INK)

    var story: Button = game.premium_button("Zen Chronicles", self, game.open_story_library)
    story.name = "MainMenuZenChronicles"
    story.custom_minimum_size.y = 48
    story.tooltip_text = game.T("Geschichte und Kapitel")
    _quiet_button(story)

    # Direct navigation: the campaign and story still lead, all other routes are grouped.

    var tower_button: Button = game.premium_button("Zen Tower",self,game.open_zen_tower)
    tower_button.name = "HomeZenTower"
    tower_button.custom_minimum_size.y = 54

    var first_row: HBoxContainer = game.row(self)
    var worlds: Button = game.premium_button("Welten", first_row, game.open_worlds)
    worlds.name = "HomeWorlds"
    var ascend: Button = game.premium_button("Zen Ascend", first_row, game.open_ascend_intro)
    ascend.name = "HomeZenAscend"
    var second_row: HBoxContainer = game.row(self)
    var achievements: Button = game.premium_button("Erfolge", second_row, game.open_achievements)
    achievements.name = "HomeAchievements"
    var shop: Button = game.premium_button("Zen-Shop", second_row, game.open_store)
    shop.name = "HomeShop"
    var third_row: HBoxContainer = game.row(self)
    var modes: Button = game.premium_button("Spielmodi", third_row, game.open_game_modes)
    modes.name = "HomeGameModes"
    var help: Button = game.button("Spielanleitung", third_row, game.open_welcome, true)
    help.name = "HomeHowToPlay"
    for option in [worlds,ascend,achievements,shop,modes,help]:
        option.custom_minimum_size.y = 52
        option.add_theme_font_size_override("font_size",16)
        option.add_theme_stylebox_override("normal",_frame(Color("#18382c"),Color("#8d9870"),16))
    if game.board.move_count() > 0 or game.challenge_active or game.tutorial != null:
        var resume: Button = game.button("Partie fortsetzen", self, game.resume_current_match, true)
        resume.name = "HomeResumeMatch"
        _quiet_button(resume)

func _quiet_button(button: Button) -> void:
    button.add_theme_stylebox_override("normal", _frame(Color("#102a25", 0.35), Color("#cfb37e", 0.45), 14))
    button.add_theme_font_size_override("font_size", 15)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _frame(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(radius)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    return style

func _process(delta: float) -> void:
    _time += delta
    if is_instance_valid(_hero) and is_instance_valid(_hero.pivot):
        _hero.pivot.rotation = Vector3(0.43, -0.58 + sin(_time * 0.35) * 0.14, -0.04)
