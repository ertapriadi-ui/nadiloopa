class_name MainController
extends Control
## Coordinates screens, 100-level chapters, Endless Zen, Daily Sanctuary, Tactical Care Dock,
## Sanctuary Almanac & Achievements, bilingual localization, and safe areas.

const BG_SPLASH_PATH := "res://assets/backgrounds/bg_splash.png"
const BG_MENU_PATH := "res://assets/backgrounds/bg_menu.png"
const BG_GAME_PATH := "res://assets/backgrounds/bg_gameplay.png"

const CHAPTER_NAMES := [
	[1, "Tropical Dawn", "Fajar Tropis"],
	[2, "Bamboo Stream", "Arus Bambu"],
	[3, "Herbal Terrace", "Teras Herbal"],
	[4, "Coral Reef", "Terumbu Karang"],
	[5, "Emerald Canopy", "Kanopi Zamrud"],
	[6, "Lotus Lagoon", "Danau Teratai"],
	[7, "Monsoon Rhythm", "Irama Muson"],
	[8, "Sanctuary Peak", "Puncak Suaka"],
	[9, "Golden Archipelago", "Nusantara Emas"],
	[10, "Grand Harmony", "Harmoni Agung"]
]

const ALMANAC_CARDS := [
	["heart", "ALMANAC_CARD_HEART"],
	["brain", "ALMANAC_CARD_BRAIN"],
	["lungs", "ALMANAC_CARD_LUNGS"],
	["kidneys", "ALMANAC_CARD_KIDNEYS"],
	["stomach", "ALMANAC_CARD_STOMACH"],
	["muscle", "ALMANAC_CARD_MUSCLE"],
	["liver", "ALMANAC_CARD_LIVER"],
	["care", "ALMANAC_CARD_CARE"],
	["bloom", "ALMANAC_CARD_BLOOM"],
	["overload", "ALMANAC_CARD_OVERLOAD"],
	["overload_armor", "ALMANAC_CARD_ARMOR"]
]

const ACHIEVEMENT_KEYS := [
	"ACH_FIRST_WIN", "ACH_CH1", "ACH_LOOP_1", "ACH_LOOP_10", "ACH_ABILITY_1",
	"ACH_OVERLOAD_20", "ACH_HALFWAY", "ACH_ENDLESS_5", "ACH_DAILY_1", "ACH_MASTER_100"
]

var _font_reg: Font
var _font_bold: Font
var _tex_bg_splash: Texture2D
var _tex_bg_menu: Texture2D
var _tex_bg_game: Texture2D
var _tex_icon: Texture2D
var _tile_icons: Dictionary = {}
var _tex_spark: Texture2D
var _tex_flow: Texture2D
var _tex_rest: Texture2D

var level_manager: LevelManager = LevelManager.new()
var board_state: BoardState
var level_def: Dictionary = {}
var progress: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _current_screen: String = "splash"
var _current_mode: String = "campaign" # campaign | endless | daily
var _selected_chapter: int = 1
var _endless_wave: int = 1
var _last_warning_active: bool = false
var _skip_splash: bool = false

# Root layout
var _bg_rect: TextureRect
var _safe_margin: MarginContainer
var _screen_splash: Control
var _screen_menu: Control
var _screen_levels: Control
var _screen_game: Control

# Modal layer
var _modal_dim: ColorRect
var _modal_pause: PanelContainer
var _modal_win: PanelContainer
var _modal_lose: PanelContainer
var _modal_settings: PanelContainer
var _modal_howto: PanelContainer
var _modal_credits: PanelContainer
var _modal_almanac: PanelContainer
var _modal_quests: PanelContainer
var _modal_reset_confirm: PanelContainer

# Menu widgets
var _lbl_menu_rank: Label
var _lbl_menu_stars_chip: Label
var _lbl_menu_charms_chip: Label
var _menu_hero_icon: TextureRect
var _menu_flank_left: TextureRect
var _menu_flank_right: TextureRect
var _menu_anim_time: float = 0.0
var _lbl_menu_title: Label
var _lbl_menu_sub: Label
var _lbl_menu_tagline: Label
var _lbl_menu_progress: Label
var _lbl_menu_worktag: Label
var _lbl_diff_title: Label
var _btn_diff_easy: Button
var _btn_diff_medium: Button
var _btn_diff_hard: Button
var _btn_play: Button
var _btn_levels: Button
var _btn_endless: Button
var _btn_daily: Button
var _btn_almanac: Button
var _btn_quests: Button
var _btn_howto: Button
var _btn_settings: Button
var _btn_credits: Button

# Level select widgets
var _lbl_levels_title: Label
var _lbl_levels_stars: Label
var _btn_levels_back: Button
var _chapter_buttons: Array[Button] = []
var _lbl_chapter_banner: Label
var _level_grid: GridContainer
var _level_buttons: Array[Button] = []

# Gameplay HUD & board widgets
var _hud_panel: PanelContainer
var _lbl_stage: Label
var _streak_pill: PanelContainer
var _lbl_streak: Label
var _fever_pill: PanelContainer
var _lbl_fever: Label
var _lbl_score_title: Label
var _lbl_score_val: Label
var _moves_pill: PanelContainer
var _lbl_moves_title: Label
var _lbl_moves_val: Label
var _btn_pause: Button
var _star_progress_bar: ProgressBar
var _lbl_star_icons: Label
var _last_live_stars: int = 0
var _lbl_pulse_label: Label
var _pulse_bar: ProgressBar
var _lbl_pulse_val: Label
var _shield_pill: PanelContainer
var _lbl_shield: Label
# _objectives_box uses FlowContainer so large-font chips wrap cleanly without clipping
var _objectives_box: HFlowContainer
var _boss_bar_panel: PanelContainer
var _lbl_boss_name: Label
var _boss_hp_bar: ProgressBar
var _tutorial_bar: PanelContainer
var _lbl_tutorial: Label
var _board_host: Control
var _board_renderer: BoardRenderer
var _touch_ctrl: TouchInputController
var _bottom_panel: PanelContainer
var _lbl_preview: Label
var _btn_game_retry: Button
var _btn_game_help: Button
var _lbl_energy_val: Label
var _energy_bar: ProgressBar
var _btn_abl_spark: Button
var _btn_abl_flow: Button
var _btn_abl_rest: Button

# Modal widgets
var _lbl_pause_title: Label
var _btn_pause_resume: Button
var _btn_pause_retry: Button
var _btn_pause_settings: Button
var _btn_pause_menu: Button

var _lbl_win_title: Label
var _lbl_win_stars: Label
var _win_dance_box: HBoxContainer
var _win_dance_sprites: Array[TextureRect] = []
var _win_dance_time: float = 0.0
var _lbl_win_sub: Label
var _lbl_win_score: Label
var _lbl_win_bonus: Label
var _lbl_win_stats: Label
var _btn_win_next: Button
var _btn_win_retry: Button
var _btn_win_menu: Button

var _lbl_lose_title: Label
var _lbl_lose_reason: Label
var _btn_lose_second_wind: Button
var _btn_lose_retry: Button
var _btn_lose_levels: Button
var _btn_lose_menu: Button

var _lbl_set_title: Label
var _lbl_set_lang: Label
var _btn_lang_en: Button
var _btn_lang_id: Button
var _lbl_set_music: Label
var _slider_music: HSlider
var _chk_music_mute: CheckButton
var _lbl_set_sfx: Label
var _slider_sfx: HSlider
var _chk_sfx_mute: CheckButton
var _chk_reduce_motion: CheckButton
var _chk_screen_shake: CheckButton
var _chk_haptics: CheckButton
var _lbl_set_theme: Label
var _btn_theme_garden: Button
var _btn_theme_sunset: Button
var _btn_theme_starlight: Button
var _btn_set_reset: Button
var _btn_set_close: Button

var _lbl_howto_title: Label
var _lbl_howto_body: Label
var _btn_howto_close: Button

var _lbl_credits_title: Label
var _lbl_credits_body: Label
var _btn_credits_close: Button

var _lbl_almanac_title: Label
var _btn_alm_cards: Button
var _btn_alm_badges: Button
var _alm_list_box: VBoxContainer
var _btn_alm_close: Button
var _almanac_tab: String = "cards"

var _lbl_quests_title: Label
var _lbl_quests_charms: Label
var _quests_list_box: VBoxContainer
var _btn_quests_close: Button

var _lbl_reset_msg: Label
var _btn_reset_confirm: Button
var _btn_reset_cancel: Button
var _settings_return_to_pause: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	BoardState.set_difficulty_grid(str(SaveManager.get_setting("difficulty", "hard")))
	_load_resources()
	_build_ui()
	LocalizationManager.language_changed.connect(_on_language_changed)
	get_viewport().size_changed.connect(_update_safe_area)
	_selected_chapter = clampi(1 + (SaveManager.get_unlocked_level() - 1) / 10, 1, 10)
	_update_safe_area()
	_refresh_texts()

	if _skip_splash or DisplayServer.get_name() == "headless":
		show_screen("menu")
	else:
		show_screen("splash")
		var tw := create_tween()
		tw.tween_interval(1.0)
		tw.tween_callback(func():
			if _current_screen == "splash":
				show_screen("menu")
		)


func _load_resources() -> void:
	_font_reg = load("res://assets/fonts/Inter-Regular.ttf") if ResourceLoader.exists("res://assets/fonts/Inter-Regular.ttf") else ThemeDB.fallback_font
	_font_bold = load("res://assets/fonts/Inter-SemiBold.ttf") if ResourceLoader.exists("res://assets/fonts/Inter-SemiBold.ttf") else ThemeDB.fallback_font
	_tex_bg_splash = _safe_tex(BG_SPLASH_PATH)
	_tex_bg_menu = _safe_tex(BG_MENU_PATH)
	_tex_bg_game = _safe_tex(BG_GAME_PATH)
	_tex_icon = _safe_tex("res://assets/icons/icon_1024.png")
	_tex_spark = _safe_tex("res://assets/sprites/tiles/icon_ability_spark.png")
	_tex_flow = _safe_tex("res://assets/sprites/tiles/icon_ability_flow.png")
	_tex_rest = _safe_tex("res://assets/sprites/tiles/icon_ability_rest.png")
	for k in BoardRenderer.TILE_TEXTURE_PATHS.keys():
		_tile_icons[k] = _safe_tex(BoardRenderer.TILE_TEXTURE_PATHS[k])


func _safe_tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


func _make_box(bg: Color, radius: int = 20, border_col: Color = Color(0, 0, 0, 0), border_w: int = 0, pad_h: int = 16, pad_v: int = 12, shadow_px: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	if border_w > 0:
		sb.border_color = border_col
		sb.set_border_width_all(border_w)
	if shadow_px > 0:
		sb.shadow_size = shadow_px
		sb.shadow_color = Color(0.02, 0.12, 0.11, 0.24)
		sb.shadow_offset = Vector2(0, maxf(3.0, float(shadow_px) * 0.42))
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb


func _make_3d_btn_box(bg: Color, radius: int, lip_px: int, pad_h: int, pad_v: int, pressed: bool = false, shadow_px: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_color = bg.darkened(0.32)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2 if pressed else lip_px
	if shadow_px > 0 and not pressed:
		sb.shadow_size = shadow_px
		sb.shadow_color = Color(0.02, 0.12, 0.10, 0.28)
		sb.shadow_offset = Vector2(0, 5)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v + (lip_px - 2 if pressed else 0)
	sb.content_margin_bottom = maxi(4, pad_v - (2 if pressed else 0))
	return sb


func _attach_button_juice(btn: Button) -> void:
	if btn.has_meta("juice_wired"):
		return
	btn.set_meta("juice_wired", true)
	btn.button_down.connect(func():
		if DisplayServer.get_name() == "headless" or GameManager.is_reduce_motion():
			return
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(0.96, 0.94), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.button_up.connect(func():
		if DisplayServer.get_name() == "headless" or GameManager.is_reduce_motion():
			return
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)


func _style_button(btn: Button, bg: Color, hover_bg: Color, text_col: Color = Color.WHITE, font_px: int = 28, radius: int = 20, pad_h: int = 16, pad_v: int = 12) -> void:
	btn.add_theme_font_override("font", _font_bold)
	btn.add_theme_font_size_override("font_size", font_px)
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", text_col)
	btn.add_theme_color_override("font_pressed_color", text_col)
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.54, 0.54))
	btn.add_theme_color_override("font_outline_color", Color(0.03, 0.14, 0.12, 0.45) if text_col == Color.WHITE else Color(1, 1, 1, 0.0))
	btn.add_theme_constant_override("outline_size", 3 if text_col == Color.WHITE else 0)
	var lip := 7 if font_px >= 28 else 5
	btn.add_theme_stylebox_override("normal", _make_3d_btn_box(bg, radius, lip, pad_h, pad_v, false, 9))
	btn.add_theme_stylebox_override("hover", _make_3d_btn_box(hover_bg, radius, lip, pad_h, pad_v, false, 11))
	btn.add_theme_stylebox_override("pressed", _make_3d_btn_box(bg.darkened(0.10), radius, lip, pad_h, pad_v, true, 0))
	btn.add_theme_stylebox_override("disabled", _make_box(Color(0.80, 0.85, 0.83, 0.78), radius, Color(0.55, 0.64, 0.62, 0.35), 2, pad_h, pad_v, 0))
	_attach_button_juice(btn)


func _make_ribbon_header(title_lbl: Label, bg_col: Color, border_col: Color) -> PanelContainer:
	var rib := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(3)
	sb.border_width_bottom = 6
	sb.set_corner_radius_all(22)
	sb.shadow_size = 10
	sb.shadow_color = Color(0.02, 0.10, 0.10, 0.28)
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	rib.add_theme_stylebox_override("panel", sb)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.add_theme_color_override("font_outline_color", Color(0.04, 0.14, 0.12, 0.72))
	title_lbl.add_theme_constant_override("outline_size", 5)
	rib.add_child(title_lbl)
	return rib


func _style_check_button(chk: CheckButton, font_px: int = 24) -> void:
	var dark_teal := Color(0.10, 0.30, 0.28)
	chk.add_theme_font_override("font", _font_bold)
	chk.add_theme_font_size_override("font_size", font_px)
	chk.add_theme_color_override("font_color", dark_teal)
	chk.add_theme_color_override("font_pressed_color", dark_teal)
	chk.add_theme_color_override("font_hover_color", dark_teal)
	chk.add_theme_color_override("font_hover_pressed_color", dark_teal)
	chk.add_theme_color_override("font_focus_color", dark_teal)


func _make_label(text: String, font_px: int, col: Color, bold: bool = false, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", _font_bold if bold else _font_reg)
	lbl.add_theme_font_size_override("font_size", font_px)
	lbl.add_theme_color_override("font_color", col)
	return lbl


func _build_ui() -> void:
	_bg_rect = TextureRect.new()
	_bg_rect.name = "Background"
	_bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_rect)

	_safe_margin = MarginContainer.new()
	_safe_margin.name = "SafeArea"
	_safe_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_safe_margin)

	var screen_holder := Control.new()
	screen_holder.name = "ScreenHolder"
	screen_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_safe_margin.add_child(screen_holder)

	_build_splash_screen(screen_holder)
	_build_menu_screen(screen_holder)
	_build_levels_screen(screen_holder)
	_build_game_screen(screen_holder)
	_build_modals()


func _build_splash_screen(parent: Control) -> void:
	_screen_splash = Control.new()
	_screen_splash.name = "SplashScreen"
	_screen_splash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen_splash.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			show_screen("menu")
	)
	parent.add_child(_screen_splash)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen_splash.add_child(center)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_box(Color(0.98, 0.99, 0.96, 0.92), 32, Color(0.11, 0.56, 0.49, 0.65), 4, 48, 40))
	center.add_child(card)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 18)
	card.add_child(vb)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(240, 240)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _tex_icon
	vb.add_child(icon)

	vb.add_child(_make_label("NADILOOPA", 64, Color(0.06, 0.28, 0.27), true, HORIZONTAL_ALIGNMENT_CENTER))
	vb.add_child(_make_label("Pulse Puzzle Sanctuary", 28, Color(0.15, 0.44, 0.40), false, HORIZONTAL_ALIGNMENT_CENTER))


func _build_menu_screen(parent: Control) -> void:
	_screen_menu = Control.new()
	_screen_menu.name = "MenuScreen"
	_screen_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(_screen_menu)

	var outer_vb := VBoxContainer.new()
	outer_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer_vb.add_theme_constant_override("separation", 16)
	_screen_menu.add_child(outer_vb)

	# Play-Store Floating Top Status Bar (Rank • Stars • Charms)
	var top_bar := HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_theme_constant_override("separation", 12)
	outer_vb.add_child(top_bar)

	var rank_pill := PanelContainer.new()
	rank_pill.add_theme_stylebox_override("panel", _make_box(Color(0.08, 0.36, 0.34, 0.94), 22, Color(0.98, 0.84, 0.42, 0.85), 3, 18, 9, 8))
	top_bar.add_child(rank_pill)
	_lbl_menu_rank = _make_label("Rank 1 • Seedling", 24, Color(1.0, 0.96, 0.80), true, HORIZONTAL_ALIGNMENT_CENTER)
	rank_pill.add_child(_lbl_menu_rank)

	var star_pill := PanelContainer.new()
	star_pill.add_theme_stylebox_override("panel", _make_box(Color(0.99, 0.96, 0.86, 0.96), 22, Color(0.92, 0.66, 0.12, 0.85), 3, 18, 9, 8))
	top_bar.add_child(star_pill)
	_lbl_menu_stars_chip = _make_label("★ 0/300", 24, Color(0.68, 0.40, 0.04), true, HORIZONTAL_ALIGNMENT_CENTER)
	star_pill.add_child(_lbl_menu_stars_chip)

	var charm_pill := PanelContainer.new()
	charm_pill.add_theme_stylebox_override("panel", _make_box(Color(0.94, 0.90, 1.0, 0.96), 22, Color(0.56, 0.34, 0.88, 0.82), 3, 18, 9, 8))
	top_bar.add_child(charm_pill)
	_lbl_menu_charms_chip = _make_label("✦ 2", 24, Color(0.36, 0.16, 0.68), true, HORIZONTAL_ALIGNMENT_CENTER)
	charm_pill.add_child(_lbl_menu_charms_chip)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vb.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(960, 0)
	card.add_theme_stylebox_override("panel", _make_box(Color(0.99, 0.985, 0.955, 0.96), 38, Color(0.94, 0.78, 0.42, 0.85), 5, 40, 32, 20))
	center.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	card.add_child(vb)

	# Hero Mascot Trio (Flanking Smiling Brain & Lungs + Floating Heart Icon)
	var hero_hb := HBoxContainer.new()
	hero_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_hb.add_theme_constant_override("separation", 22)
	vb.add_child(hero_hb)

	var flank_l_wrap := Control.new()
	flank_l_wrap.custom_minimum_size = Vector2(124, 150)
	hero_hb.add_child(flank_l_wrap)
	_menu_flank_left = TextureRect.new()
	_menu_flank_left.size = Vector2(120, 120)
	_menu_flank_left.position = Vector2(2, 24)
	_menu_flank_left.pivot_offset = Vector2(60, 60)
	_menu_flank_left.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_menu_flank_left.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_menu_flank_left.texture = _tile_icons.get("brain_happy", _tile_icons.get("brain", null))
	flank_l_wrap.add_child(_menu_flank_left)

	var hero_wrap := Control.new()
	hero_wrap.custom_minimum_size = Vector2(224, 224)
	hero_hb.add_child(hero_wrap)
	_menu_hero_icon = TextureRect.new()
	_menu_hero_icon.size = Vector2(224, 224)
	_menu_hero_icon.pivot_offset = Vector2(112, 112)
	_menu_hero_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_menu_hero_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_menu_hero_icon.texture = _tex_icon
	hero_wrap.add_child(_menu_hero_icon)

	var flank_r_wrap := Control.new()
	flank_r_wrap.custom_minimum_size = Vector2(124, 150)
	hero_hb.add_child(flank_r_wrap)
	_menu_flank_right = TextureRect.new()
	_menu_flank_right.size = Vector2(120, 120)
	_menu_flank_right.position = Vector2(2, 24)
	_menu_flank_right.pivot_offset = Vector2(60, 60)
	_menu_flank_right.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_menu_flank_right.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_menu_flank_right.texture = _tile_icons.get("lungs_happy", _tile_icons.get("lungs", null))
	flank_r_wrap.add_child(_menu_flank_right)

	_lbl_menu_title = _make_label("NADILOOPA", 74, Color(0.05, 0.30, 0.27), true, HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_menu_title.add_theme_color_override("font_outline_color", Color(0.98, 0.88, 0.56, 0.90))
	_lbl_menu_title.add_theme_constant_override("outline_size", 6)
	vb.add_child(_lbl_menu_title)

	_lbl_menu_sub = _make_label("Pulse Puzzle Sanctuary", 32, Color(0.11, 0.48, 0.42), true, HORIZONTAL_ALIGNMENT_CENTER)
	vb.add_child(_lbl_menu_sub)

	_lbl_menu_tagline = _make_label("", 26, Color(0.22, 0.36, 0.36), true, HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_menu_tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_lbl_menu_tagline)

	var prog_pill := PanelContainer.new()
	prog_pill.add_theme_stylebox_override("panel", _make_box(Color(0.88, 0.96, 0.92, 0.96), 20, Color(0.14, 0.60, 0.46, 0.48), 2, 18, 10))
	vb.add_child(prog_pill)
	_lbl_menu_progress = _make_label("", 26, Color(0.07, 0.36, 0.28), true, HORIZONTAL_ALIGNMENT_CENTER)
	prog_pill.add_child(_lbl_menu_progress)

	# Difficulty & Dynamic Grid Size Selector (Easy 5x7 | Medium 6x9 | Hard 7x12)
	var diff_card := PanelContainer.new()
	diff_card.add_theme_stylebox_override("panel", _make_box(Color(0.92, 0.97, 0.94, 0.96), 24, Color(0.12, 0.50, 0.44, 0.35), 2, 16, 14))
	vb.add_child(diff_card)
	var diff_vb := VBoxContainer.new()
	diff_vb.add_theme_constant_override("separation", 10)
	diff_card.add_child(diff_vb)

	_lbl_diff_title = _make_label("Difficulty & Grid Size", 25, Color(0.08, 0.32, 0.30), true, HORIZONTAL_ALIGNMENT_CENTER)
	diff_vb.add_child(_lbl_diff_title)

	var diff_hb := HBoxContainer.new()
	diff_hb.add_theme_constant_override("separation", 12)
	diff_vb.add_child(diff_hb)

	_btn_diff_easy = Button.new()
	_btn_diff_easy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_diff_easy.custom_minimum_size = Vector2(0, 100)
	_btn_diff_easy.pressed.connect(func(): _set_difficulty("easy"))
	diff_hb.add_child(_btn_diff_easy)

	_btn_diff_medium = Button.new()
	_btn_diff_medium.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_diff_medium.custom_minimum_size = Vector2(0, 100)
	_btn_diff_medium.pressed.connect(func(): _set_difficulty("medium"))
	diff_hb.add_child(_btn_diff_medium)

	_btn_diff_hard = Button.new()
	_btn_diff_hard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_diff_hard.custom_minimum_size = Vector2(0, 100)
	_btn_diff_hard.pressed.connect(func(): _set_difficulty("hard"))
	diff_hb.add_child(_btn_diff_hard)

	# Primary 3D Emerald Play CTA
	_btn_play = Button.new()
	_btn_play.custom_minimum_size = Vector2(0, 114)
	_style_button(_btn_play, Color(0.08, 0.68, 0.48), Color(0.12, 0.78, 0.56), Color.WHITE, 40, 26)
	_btn_play.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		start_level(SaveManager.get_unlocked_level())
	)
	vb.add_child(_btn_play)

	# 2-Button Action Row: Stages | Quests & Star Chest
	var row_mid := HBoxContainer.new()
	row_mid.add_theme_constant_override("separation", 14)
	vb.add_child(row_mid)

	_btn_levels = Button.new()
	_btn_levels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_levels.custom_minimum_size = Vector2(0, 90)
	_style_button(_btn_levels, Color(0.12, 0.52, 0.72), Color(0.18, 0.62, 0.82), Color.WHITE, 30, 22, 12, 12)
	_btn_levels.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		show_screen("levels")
	)
	row_mid.add_child(_btn_levels)

	_btn_quests = Button.new()
	_btn_quests.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_quests.custom_minimum_size = Vector2(0, 90)
	_style_button(_btn_quests, Color(0.90, 0.56, 0.12), Color(0.98, 0.66, 0.20), Color.WHITE, 30, 22, 12, 12)
	_btn_quests.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_refresh_quests_ui()
		_open_modal(_modal_quests)
	)
	row_mid.add_child(_btn_quests)

	# Bottom Row: Organs | Settings & Guide
	var row_bot := HBoxContainer.new()
	row_bot.add_theme_constant_override("separation", 14)
	vb.add_child(row_bot)

	_btn_almanac = Button.new()
	_btn_almanac.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_almanac.custom_minimum_size = Vector2(0, 84)
	_style_button(_btn_almanac, Color(0.14, 0.56, 0.46), Color(0.20, 0.66, 0.56), Color.WHITE, 28, 20, 12, 10)
	_btn_almanac.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_refresh_almanac_ui()
		_open_modal(_modal_almanac)
	)
	row_bot.add_child(_btn_almanac)

	_btn_settings = Button.new()
	_btn_settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_settings.custom_minimum_size = Vector2(0, 84)
	_style_button(_btn_settings, Color(0.26, 0.38, 0.44), Color(0.34, 0.48, 0.54), Color.WHITE, 28, 20, 12, 10)
	_btn_settings.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_settings_return_to_pause = false
		_sync_settings_ui()
		_open_modal(_modal_settings)
	)
	row_bot.add_child(_btn_settings)

	_lbl_menu_worktag = _make_label("", 22, Color(0.36, 0.46, 0.44), true, HORIZONTAL_ALIGNMENT_CENTER)
	vb.add_child(_lbl_menu_worktag)


func _build_levels_screen(parent: Control) -> void:
	_screen_levels = Control.new()
	_screen_levels.name = "LevelSelectScreen"
	_screen_levels.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(_screen_levels)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 14)
	_screen_levels.add_child(vb)

	var hdr := PanelContainer.new()
	hdr.add_theme_stylebox_override("panel", _make_box(Color(0.97, 0.99, 0.96, 0.94), 24, Color(0.12, 0.48, 0.44, 0.4), 3, 20, 14))
	vb.add_child(hdr)

	var hb := HBoxContainer.new()
	hdr.add_child(hb)
	_btn_levels_back = Button.new()
	_btn_levels_back.custom_minimum_size = Vector2(168, 68)
	_style_button(_btn_levels_back, Color(0.22, 0.36, 0.40), Color(0.30, 0.46, 0.50), Color.WHITE, 28, 16)
	_btn_levels_back.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		show_screen("menu")
	)
	hb.add_child(_btn_levels_back)

	_lbl_levels_title = _make_label("100-Stage Sanctuary", 34, Color(0.06, 0.27, 0.26), true, HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_levels_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(_lbl_levels_title)

	_lbl_levels_stars = _make_label("★ 0/300", 28, Color(0.84, 0.54, 0.08), true, HORIZONTAL_ALIGNMENT_RIGHT)
	_lbl_levels_stars.custom_minimum_size = Vector2(170, 0)
	hb.add_child(_lbl_levels_stars)

	# Bonus Modes Row (Endless & Daily moved cleanly off Main Menu into Level Select)
	var extra_modes_hb := HBoxContainer.new()
	extra_modes_hb.add_theme_constant_override("separation", 14)
	vb.add_child(extra_modes_hb)

	_btn_endless = Button.new()
	_btn_endless.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_endless.custom_minimum_size = Vector2(0, 74)
	_style_button(_btn_endless, Color(0.42, 0.32, 0.76), Color(0.52, 0.42, 0.86), Color.WHITE, 28, 18, 12, 10)
	_btn_endless.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		start_endless_mode()
	)
	extra_modes_hb.add_child(_btn_endless)

	_btn_daily = Button.new()
	_btn_daily.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_daily.custom_minimum_size = Vector2(0, 74)
	_style_button(_btn_daily, Color(0.88, 0.50, 0.16), Color(0.96, 0.58, 0.24), Color.WHITE, 28, 18, 12, 10)
	_btn_daily.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		start_daily_challenge()
	)
	extra_modes_hb.add_child(_btn_daily)

	# 10 Chapter Selector Grid (5x2)
	var ch_panel := PanelContainer.new()
	ch_panel.add_theme_stylebox_override("panel", _make_box(Color(0.96, 0.99, 0.96, 0.90), 20, Color(0.12, 0.48, 0.44, 0.3), 2, 14, 12))
	vb.add_child(ch_panel)
	var ch_grid := GridContainer.new()
	ch_grid.columns = 5
	ch_grid.add_theme_constant_override("h_separation", 10)
	ch_grid.add_theme_constant_override("v_separation", 10)
	ch_panel.add_child(ch_grid)

	_chapter_buttons.clear()
	for ch in range(1, 11):
		var cbtn := Button.new()
		cbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cbtn.custom_minimum_size = Vector2(0, 62)
		var ch_id := ch
		cbtn.pressed.connect(func():
			AudioManager.play_sfx("menu_button")
			_selected_chapter = ch_id
			_refresh_level_cards()
		)
		ch_grid.add_child(cbtn)
		_chapter_buttons.append(cbtn)

	var banner_pill := PanelContainer.new()
	banner_pill.add_theme_stylebox_override("panel", _make_box(Color(0.12, 0.52, 0.44, 0.92), 16, Color(1, 1, 1, 0.4), 2, 18, 10))
	vb.add_child(banner_pill)
	_lbl_chapter_banner = _make_label("", 26, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	banner_pill.add_child(_lbl_chapter_banner)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	var center_grid := CenterContainer.new()
	center_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center_grid)

	_level_grid = GridContainer.new()
	_level_grid.columns = 2
	_level_grid.add_theme_constant_override("h_separation", 18)
	_level_grid.add_theme_constant_override("v_separation", 18)
	center_grid.add_child(_level_grid)

	_level_buttons.clear()
	for slot in range(10):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(465, 175)
		btn.clip_text = true
		var s_idx := slot
		btn.pressed.connect(func():
			AudioManager.play_sfx("menu_button")
			var lid := (_selected_chapter - 1) * 10 + s_idx + 1
			start_level(lid)
		)
		_level_grid.add_child(btn)
		_level_buttons.append(btn)


func _build_game_screen(parent: Control) -> void:
	_screen_game = Control.new()
	_screen_game.name = "GameplayScreen"
	_screen_game.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(_screen_game)

	var root_vb := VBoxContainer.new()
	root_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vb.add_theme_constant_override("separation", 8)
	_screen_game.add_child(root_vb)

	# --- Compact Top HUD (Elevated Play-Store Style) ---
	_hud_panel = PanelContainer.new()
	_hud_panel.add_theme_stylebox_override("panel", _make_box(Color(0.99, 0.985, 0.955, 0.96), 26, Color(0.92, 0.78, 0.44, 0.75), 3, 18, 10, 12))
	root_vb.add_child(_hud_panel)

	var hud_vb := VBoxContainer.new()
	hud_vb.add_theme_constant_override("separation", 6)
	_hud_panel.add_child(hud_vb)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	hud_vb.add_child(row1)

	_lbl_stage = _make_label("Stage 1", 30, Color(0.06, 0.28, 0.26), true, HORIZONTAL_ALIGNMENT_LEFT)
	_lbl_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_stage.clip_text = true
	row1.add_child(_lbl_stage)

	_streak_pill = PanelContainer.new()
	_streak_pill.add_theme_stylebox_override("panel", _make_box(Color(1.0, 0.88, 0.42), 14, Color(0.84, 0.48, 0.08), 2, 10, 4))
	_streak_pill.visible = false
	row1.add_child(_streak_pill)
	_lbl_streak = _make_label("x1.2", 22, Color(0.48, 0.20, 0.04), true)
	_streak_pill.add_child(_lbl_streak)

	_fever_pill = PanelContainer.new()
	_fever_pill.add_theme_stylebox_override("panel", _make_box(Color(0.92, 0.95, 0.94), 14, Color(0.24, 0.56, 0.50, 0.45), 2, 10, 4))
	row1.add_child(_fever_pill)
	_lbl_fever = _make_label("Fever 0/3", 22, Color(0.14, 0.40, 0.36), true)
	_fever_pill.add_child(_lbl_fever)

	var score_pill := PanelContainer.new()
	score_pill.add_theme_stylebox_override("panel", _make_box(Color(0.90, 0.96, 0.93), 16, Color(0.15, 0.55, 0.45, 0.35), 2, 12, 4))
	row1.add_child(score_pill)
	var score_hb := HBoxContainer.new()
	score_hb.add_theme_constant_override("separation", 6)
	score_pill.add_child(score_hb)
	_lbl_score_title = _make_label("Score", 22, Color(0.20, 0.42, 0.38), true)
	_lbl_score_val = _make_label("0", 32, Color(0.05, 0.26, 0.24), true)
	score_hb.add_child(_lbl_score_title)
	score_hb.add_child(_lbl_score_val)

	_moves_pill = PanelContainer.new()
	_moves_pill.add_theme_stylebox_override("panel", _make_box(Color(0.99, 0.93, 0.84), 16, Color(0.88, 0.50, 0.16, 0.55), 2, 12, 4))
	row1.add_child(_moves_pill)
	var moves_hb := HBoxContainer.new()
	moves_hb.add_theme_constant_override("separation", 6)
	_moves_pill.add_child(moves_hb)
	_lbl_moves_title = _make_label("Moves", 22, Color(0.55, 0.28, 0.08), true)
	_lbl_moves_val = _make_label("14", 32, Color(0.75, 0.30, 0.06), true)
	moves_hb.add_child(_lbl_moves_title)
	moves_hb.add_child(_lbl_moves_val)

	_btn_pause = Button.new()
	_btn_pause.custom_minimum_size = Vector2(124, 62)
	_style_button(_btn_pause, Color(0.18, 0.44, 0.48), Color(0.24, 0.54, 0.58), Color.WHITE, 26, 16, 10, 6)
	_btn_pause.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		pause_game()
	)
	row1.add_child(_btn_pause)

	# Slim Live 3-Star Score Progress Bar + Pulse Bar Row
	var row_stars := HBoxContainer.new()
	row_stars.add_theme_constant_override("separation", 10)
	hud_vb.add_child(row_stars)

	_lbl_star_icons = _make_label("☆☆☆", 24, Color(0.88, 0.58, 0.08), true)
	_lbl_star_icons.custom_minimum_size = Vector2(90, 0)
	row_stars.add_child(_lbl_star_icons)

	_star_progress_bar = ProgressBar.new()
	_star_progress_bar.min_value = 0
	_star_progress_bar.max_value = 3000
	_star_progress_bar.value = 0
	_star_progress_bar.show_percentage = false
	_star_progress_bar.custom_minimum_size = Vector2(0, 16)
	_star_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_star_progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_star_progress_bar.add_theme_stylebox_override("background", _make_box(Color(0.88, 0.90, 0.86), 8, Color(0.78, 0.62, 0.20, 0.35), 1, 0, 0))
	_star_progress_bar.add_theme_stylebox_override("fill", _make_box(Color(0.96, 0.72, 0.14), 7, Color(0, 0, 0, 0), 0, 0, 0))
	row_stars.add_child(_star_progress_bar)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 12)
	hud_vb.add_child(row2)

	_lbl_pulse_label = _make_label("Pulse", 26, Color(0.10, 0.34, 0.32), true)
	row2.add_child(_lbl_pulse_label)

	_pulse_bar = ProgressBar.new()
	_pulse_bar.min_value = 0
	_pulse_bar.max_value = 100
	_pulse_bar.value = 100
	_pulse_bar.show_percentage = false
	_pulse_bar.custom_minimum_size = Vector2(0, 28)
	_pulse_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pulse_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_pulse_bar.add_theme_stylebox_override("background", _make_box(Color(0.84, 0.90, 0.88), 12, Color(0.12, 0.38, 0.36, 0.25), 2, 0, 0))
	_pulse_bar.add_theme_stylebox_override("fill", _make_box(Color(0.12, 0.76, 0.48), 10, Color(0, 0, 0, 0), 0, 0, 0))
	row2.add_child(_pulse_bar)

	_lbl_pulse_val = _make_label("100/100", 26, Color(0.06, 0.32, 0.24), true)
	row2.add_child(_lbl_pulse_val)

	_shield_pill = PanelContainer.new()
	_shield_pill.add_theme_stylebox_override("panel", _make_box(Color(0.88, 0.94, 0.92), 14, Color(0.2, 0.5, 0.4, 0.3), 2, 14, 4))
	row2.add_child(_shield_pill)
	_lbl_shield = _make_label("No Shield", 24, Color(0.24, 0.38, 0.36), true)
	_shield_pill.add_child(_lbl_shield)

	_boss_bar_panel = PanelContainer.new()
	_boss_bar_panel.visible = false
	_boss_bar_panel.add_theme_stylebox_override("panel", _make_box(Color(0.99, 0.90, 0.88), 16, Color(0.84, 0.24, 0.18, 0.78), 2, 14, 6))
	hud_vb.add_child(_boss_bar_panel)
	var boss_hb := HBoxContainer.new()
	boss_hb.add_theme_constant_override("separation", 12)
	_boss_bar_panel.add_child(boss_hb)
	var boss_ic := TextureRect.new()
	boss_ic.custom_minimum_size = Vector2(40, 40)
	boss_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boss_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	boss_ic.texture = _tile_icons.get("overload", null)
	boss_hb.add_child(boss_ic)
	var boss_vb := VBoxContainer.new()
	boss_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	boss_vb.add_theme_constant_override("separation", 4)
	boss_hb.add_child(boss_vb)
	_lbl_boss_name = _make_label("Boss", 22, Color(0.70, 0.14, 0.12), true)
	boss_vb.add_child(_lbl_boss_name)
	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.min_value = 0
	_boss_hp_bar.max_value = 100
	_boss_hp_bar.value = 100
	_boss_hp_bar.show_percentage = false
	_boss_hp_bar.custom_minimum_size = Vector2(0, 14)
	_boss_hp_bar.add_theme_stylebox_override("background", _make_box(Color(0.88, 0.78, 0.76), 7, Color(0, 0, 0, 0), 0, 0, 0))
	_boss_hp_bar.add_theme_stylebox_override("fill", _make_box(Color(0.88, 0.22, 0.18), 7, Color(0, 0, 0, 0), 0, 0, 0))
	boss_vb.add_child(_boss_hp_bar)

	_objectives_box = HFlowContainer.new()
	_objectives_box.alignment = FlowContainer.ALIGNMENT_CENTER
	_objectives_box.add_theme_constant_override("h_separation", 12)
	_objectives_box.add_theme_constant_override("v_separation", 6)
	hud_vb.add_child(_objectives_box)

	_tutorial_bar = PanelContainer.new()
	_tutorial_bar.add_theme_stylebox_override("panel", _make_box(Color(0.12, 0.56, 0.46, 0.94), 14, Color(1, 1, 1, 0.45), 2, 14, 7))
	hud_vb.add_child(_tutorial_bar)
	_lbl_tutorial = _make_label("", 26, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_tutorial.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_bar.add_child(_lbl_tutorial)

	# --- Center Adaptive Board Container ---
	_board_host = Control.new()
	_board_host.name = "BoardHost"
	_board_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vb.add_child(_board_host)

	_board_renderer = BoardRenderer.new()
	_board_renderer.name = "BoardRenderer"
	_board_renderer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_board_host.add_child(_board_renderer)

	_touch_ctrl = TouchInputController.new()
	_touch_ctrl.name = "TouchInputController"
	_touch_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_board_host.add_child(_touch_ctrl)
	_touch_ctrl.bind(_board_renderer)
	_touch_ctrl.chain_updated.connect(_on_chain_updated)
	_touch_ctrl.chain_committed.connect(_on_chain_committed)
	_touch_ctrl.chain_cancelled.connect(_on_chain_cancelled)

	# --- Bottom Preview + Tactical Care Dock ---
	_bottom_panel = PanelContainer.new()
	_bottom_panel.add_theme_stylebox_override("panel", _make_box(Color(0.99, 0.985, 0.955, 0.96), 24, Color(0.92, 0.78, 0.44, 0.75), 3, 14, 8, 12))
	root_vb.add_child(_bottom_panel)

	var bot_vb := VBoxContainer.new()
	bot_vb.add_theme_constant_override("separation", 6)
	_bottom_panel.add_child(bot_vb)

	var bot_top := HBoxContainer.new()
	bot_top.add_theme_constant_override("separation", 10)
	bot_vb.add_child(bot_top)

	_lbl_preview = _make_label("", 26, Color(0.08, 0.30, 0.28), true, HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bot_top.add_child(_lbl_preview)

	# Keep secondary buttons hidden on gameplay screen to avoid button clutter (available via Pause)
	_btn_game_retry = Button.new()
	_btn_game_retry.visible = false
	_btn_game_retry.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		if _current_mode == "endless":
			start_endless_mode()
		elif _current_mode == "daily":
			start_daily_challenge()
		else:
			start_level(GameManager.current_level_id)
	)
	bot_top.add_child(_btn_game_retry)

	_btn_game_help = Button.new()
	_btn_game_help.visible = false
	_btn_game_help.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_open_modal(_modal_howto)
	)
	bot_top.add_child(_btn_game_help)

	# Tactical Care Dock (Larger typography & touch targets)
	var dock_hb := HBoxContainer.new()
	dock_hb.add_theme_constant_override("separation", 10)
	bot_vb.add_child(dock_hb)

	var en_box := VBoxContainer.new()
	en_box.custom_minimum_size = Vector2(215, 0)
	en_box.add_theme_constant_override("separation", 4)
	dock_hb.add_child(en_box)

	_lbl_energy_val = _make_label("Energy 0/100", 22, Color(0.08, 0.38, 0.28), true)
	en_box.add_child(_lbl_energy_val)
	_energy_bar = ProgressBar.new()
	_energy_bar.min_value = 0
	_energy_bar.max_value = 100
	_energy_bar.value = 0
	_energy_bar.show_percentage = false
	_energy_bar.custom_minimum_size = Vector2(0, 22)
	_energy_bar.add_theme_stylebox_override("background", _make_box(Color(0.84, 0.90, 0.88), 9, Color(0.12, 0.38, 0.36, 0.25), 1, 0, 0))
	_energy_bar.add_theme_stylebox_override("fill", _make_box(Color(0.95, 0.72, 0.14), 7, Color(0, 0, 0, 0), 0, 0, 0))
	en_box.add_child(_energy_bar)

	_btn_abl_spark = _make_ability_btn(_tex_spark, Color(0.90, 0.52, 0.12))
	_btn_abl_spark.pressed.connect(func(): _use_tactical_ability("spark"))
	dock_hb.add_child(_btn_abl_spark)

	_btn_abl_flow = _make_ability_btn(_tex_flow, Color(0.12, 0.56, 0.68))
	_btn_abl_flow.pressed.connect(func(): _use_tactical_ability("flow"))
	dock_hb.add_child(_btn_abl_flow)

	_btn_abl_rest = _make_ability_btn(_tex_rest, Color(0.10, 0.58, 0.36))
	_btn_abl_rest.pressed.connect(func(): _use_tactical_ability("rest"))
	dock_hb.add_child(_btn_abl_rest)


func _make_ability_btn(icon_tex: Texture2D, bg: Color) -> Button:
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 64)
	b.icon = icon_tex
	b.expand_icon = true
	b.clip_text = true
	_style_button(b, bg, bg.lightened(0.12), Color.WHITE, 21, 16, 8, 6)
	return b


func _build_modals() -> void:
	_modal_dim = ColorRect.new()
	_modal_dim.name = "ModalDim"
	_modal_dim.z_index = 100
	_modal_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_dim.color = Color(0.03, 0.12, 0.12, 0.70)
	_modal_dim.visible = false
	add_child(_modal_dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_dim.add_child(center)

	# Pause
	_modal_pause = _create_modal_card(center, 820)
	var p_vb := VBoxContainer.new()
	p_vb.add_theme_constant_override("separation", 18)
	_modal_pause.add_child(p_vb)
	_lbl_pause_title = _make_label("Paused", 42, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	p_vb.add_child(_make_ribbon_header(_lbl_pause_title, Color(0.10, 0.50, 0.46), Color(0.06, 0.34, 0.32)))
	_btn_pause_resume = Button.new()
	_btn_pause_resume.custom_minimum_size = Vector2(0, 82)
	_style_button(_btn_pause_resume, Color(0.08, 0.66, 0.48), Color(0.12, 0.76, 0.56), Color.WHITE, 30)
	_btn_pause_resume.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		resume_game()
	)
	p_vb.add_child(_btn_pause_resume)
	_btn_pause_retry = Button.new()
	_btn_pause_retry.custom_minimum_size = Vector2(0, 76)
	_style_button(_btn_pause_retry, Color(0.90, 0.52, 0.14), Color(0.96, 0.60, 0.22), Color.WHITE, 28)
	_btn_pause_retry.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_close_modals()
		if _current_mode == "endless":
			start_endless_mode()
		elif _current_mode == "daily":
			start_daily_challenge()
		else:
			start_level(GameManager.current_level_id)
	)
	p_vb.add_child(_btn_pause_retry)
	_btn_pause_settings = Button.new()
	_btn_pause_settings.custom_minimum_size = Vector2(0, 76)
	_style_button(_btn_pause_settings, Color(0.14, 0.50, 0.66), Color(0.20, 0.60, 0.76), Color.WHITE, 28)
	_btn_pause_settings.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_settings_return_to_pause = true
		_sync_settings_ui()
		_open_modal(_modal_settings)
	)
	p_vb.add_child(_btn_pause_settings)
	_btn_pause_menu = Button.new()
	_btn_pause_menu.custom_minimum_size = Vector2(0, 76)
	_style_button(_btn_pause_menu, Color(0.28, 0.38, 0.42), Color(0.36, 0.48, 0.52), Color.WHITE, 28)
	_btn_pause_menu.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_close_modals()
		show_screen("menu")
	)
	p_vb.add_child(_btn_pause_menu)

	# Win Modal with Golden Ribbon, Smiling & Dancing Organ Mascots Parade & Match Summary
	_modal_win = _create_modal_card(center, 920)
	var w_vb := VBoxContainer.new()
	w_vb.add_theme_constant_override("separation", 14)
	_modal_win.add_child(w_vb)
	_lbl_win_title = _make_label("Stage Complete!", 48, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	w_vb.add_child(_make_ribbon_header(_lbl_win_title, Color(0.92, 0.64, 0.10), Color(0.70, 0.42, 0.04)))
	_lbl_win_stars = _make_label("★★★", 74, Color(0.96, 0.68, 0.08), true, HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_win_stars.add_theme_color_override("font_outline_color", Color(0.45, 0.24, 0.02, 0.85))
	_lbl_win_stars.add_theme_constant_override("outline_size", 5)
	w_vb.add_child(_lbl_win_stars)

	_win_dance_box = HBoxContainer.new()
	_win_dance_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_win_dance_box.add_theme_constant_override("separation", 10)
	_win_dance_box.custom_minimum_size = Vector2(0, 126)
	w_vb.add_child(_win_dance_box)
	_win_dance_sprites.clear()
	for org in BoardState.ORGANS:
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(96, 112)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_win_dance_box.add_child(holder)
		var dtr := TextureRect.new()
		dtr.custom_minimum_size = Vector2(96, 96)
		dtr.size = Vector2(96, 96)
		dtr.position = Vector2(0, 8)
		dtr.pivot_offset = Vector2(48, 48)
		dtr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dtr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dtr.texture = _tile_icons.get(org + "_happy", _tile_icons.get(org, null))
		holder.add_child(dtr)
		_win_dance_sprites.append(dtr)

	_lbl_win_sub = _make_label("", 28, Color(0.18, 0.36, 0.34), true, HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_win_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	w_vb.add_child(_lbl_win_sub)

	var win_score_card := PanelContainer.new()
	win_score_card.add_theme_stylebox_override("panel", _make_box(Color(0.92, 0.97, 0.94), 20, Color(0.14, 0.58, 0.44, 0.42), 2, 18, 12))
	w_vb.add_child(win_score_card)
	var ws_vb := VBoxContainer.new()
	ws_vb.add_theme_constant_override("separation", 6)
	win_score_card.add_child(ws_vb)
	_lbl_win_score = _make_label("", 38, Color(0.05, 0.28, 0.24), true, HORIZONTAL_ALIGNMENT_CENTER)
	ws_vb.add_child(_lbl_win_score)
	_lbl_win_bonus = _make_label("", 26, Color(0.10, 0.54, 0.38), true, HORIZONTAL_ALIGNMENT_CENTER)
	ws_vb.add_child(_lbl_win_bonus)
	_lbl_win_stats = _make_label("", 24, Color(0.24, 0.40, 0.38), true, HORIZONTAL_ALIGNMENT_CENTER)
	ws_vb.add_child(_lbl_win_stats)

	_btn_win_next = Button.new()
	_btn_win_next.custom_minimum_size = Vector2(0, 90)
	_style_button(_btn_win_next, Color(0.08, 0.66, 0.48), Color(0.12, 0.76, 0.56), Color.WHITE, 34, 22)
	_btn_win_next.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_close_modals()
		if _current_mode == "daily":
			show_screen("menu")
		else:
			var next_id := GameManager.current_level_id + 1
			if next_id <= 100:
				start_level(next_id)
			else:
				show_screen("levels")
	)
	w_vb.add_child(_btn_win_next)

	var win_bot_hb := HBoxContainer.new()
	win_bot_hb.add_theme_constant_override("separation", 14)
	w_vb.add_child(win_bot_hb)
	_btn_win_retry = Button.new()
	_btn_win_retry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_win_retry.custom_minimum_size = Vector2(0, 74)
	_style_button(_btn_win_retry, Color(0.14, 0.52, 0.68), Color(0.20, 0.62, 0.78), Color.WHITE, 26)
	_btn_win_retry.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_close_modals()
		if _current_mode == "daily":
			start_daily_challenge()
		else:
			start_level(GameManager.current_level_id)
	)
	win_bot_hb.add_child(_btn_win_retry)
	_btn_win_menu = Button.new()
	_btn_win_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_win_menu.custom_minimum_size = Vector2(0, 74)
	_style_button(_btn_win_menu, Color(0.28, 0.38, 0.42), Color(0.36, 0.48, 0.52), Color.WHITE, 26)
	_btn_win_menu.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_close_modals()
		show_screen("menu")
	)
	win_bot_hb.add_child(_btn_win_menu)

	# Lose Modal with Second Wind Revival Option
	_modal_lose = _create_modal_card(center, 840)
	var l_vb := VBoxContainer.new()
	l_vb.add_theme_constant_override("separation", 16)
	_modal_lose.add_child(l_vb)
	_lbl_lose_title = _make_label("Out of Rhythm", 44, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	l_vb.add_child(_make_ribbon_header(_lbl_lose_title, Color(0.82, 0.24, 0.20), Color(0.58, 0.14, 0.12)))
	_lbl_lose_reason = _make_label("", 26, Color(0.24, 0.30, 0.32), true, HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_lose_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_vb.add_child(_lbl_lose_reason)

	_btn_lose_second_wind = Button.new()
	_btn_lose_second_wind.custom_minimum_size = Vector2(0, 88)
	_style_button(_btn_lose_second_wind, Color(0.92, 0.60, 0.10), Color(0.98, 0.70, 0.18), Color.WHITE, 28, 22)
	_btn_lose_second_wind.pressed.connect(_use_second_wind)
	l_vb.add_child(_btn_lose_second_wind)

	_btn_lose_retry = Button.new()
	_btn_lose_retry.custom_minimum_size = Vector2(0, 82)
	_style_button(_btn_lose_retry, Color(0.08, 0.64, 0.48), Color(0.12, 0.74, 0.56), Color.WHITE, 30)
	_btn_lose_retry.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_close_modals()
		if _current_mode == "endless":
			start_endless_mode()
		elif _current_mode == "daily":
			start_daily_challenge()
		else:
			start_level(GameManager.current_level_id)
	)
	l_vb.add_child(_btn_lose_retry)
	var lose_bot_hb := HBoxContainer.new()
	lose_bot_hb.add_theme_constant_override("separation", 14)
	l_vb.add_child(lose_bot_hb)
	_btn_lose_levels = Button.new()
	_btn_lose_levels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_lose_levels.custom_minimum_size = Vector2(0, 74)
	_style_button(_btn_lose_levels, Color(0.14, 0.52, 0.68), Color(0.20, 0.62, 0.78), Color.WHITE, 26)
	_btn_lose_levels.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_close_modals()
		show_screen("levels")
	)
	lose_bot_hb.add_child(_btn_lose_levels)
	_btn_lose_menu = Button.new()
	_btn_lose_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_lose_menu.custom_minimum_size = Vector2(0, 74)
	_style_button(_btn_lose_menu, Color(0.28, 0.38, 0.42), Color(0.36, 0.48, 0.52), Color.WHITE, 26)
	_btn_lose_menu.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_close_modals()
		show_screen("menu")
	)
	lose_bot_hb.add_child(_btn_lose_menu)

	# Settings Modal
	_modal_settings = _create_modal_card(center, 880)
	var s_vb := VBoxContainer.new()
	s_vb.add_theme_constant_override("separation", 16)
	_modal_settings.add_child(s_vb)
	_lbl_set_title = _make_label("Settings", 42, Color(0.06, 0.27, 0.26), true, HORIZONTAL_ALIGNMENT_CENTER)
	s_vb.add_child(_lbl_set_title)

	_lbl_set_lang = _make_label("Language", 26, Color(0.12, 0.32, 0.30), true)
	s_vb.add_child(_lbl_set_lang)
	var lang_hb := HBoxContainer.new()
	lang_hb.add_theme_constant_override("separation", 16)
	s_vb.add_child(lang_hb)
	_btn_lang_en = Button.new()
	_btn_lang_en.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_lang_en.custom_minimum_size = Vector2(0, 68)
	_btn_lang_en.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		LocalizationManager.set_language("en")
		_sync_settings_ui()
	)
	lang_hb.add_child(_btn_lang_en)
	_btn_lang_id = Button.new()
	_btn_lang_id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_lang_id.custom_minimum_size = Vector2(0, 68)
	_btn_lang_id.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		LocalizationManager.set_language("id")
		_sync_settings_ui()
	)
	lang_hb.add_child(_btn_lang_id)

	var mus_card := PanelContainer.new()
	mus_card.add_theme_stylebox_override("panel", _make_box(Color(0.92, 0.97, 0.95), 14, Color(0.14, 0.48, 0.44, 0.22), 1, 14, 10))
	s_vb.add_child(mus_card)
	var mus_hb := HBoxContainer.new()
	mus_hb.add_theme_constant_override("separation", 14)
	mus_card.add_child(mus_hb)
	_lbl_set_music = _make_label("Music Volume", 24, Color(0.12, 0.32, 0.30), true)
	_lbl_set_music.custom_minimum_size = Vector2(220, 0)
	mus_hb.add_child(_lbl_set_music)
	_slider_music = HSlider.new()
	_slider_music.min_value = 0.0
	_slider_music.max_value = 1.0
	_slider_music.step = 0.05
	_slider_music.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider_music.custom_minimum_size = Vector2(0, 44)
	_slider_music.value_changed.connect(func(v): AudioManager.set_music_volume(v))
	mus_hb.add_child(_slider_music)
	_chk_music_mute = CheckButton.new()
	_chk_music_mute.text = "Mute"
	_style_check_button(_chk_music_mute, 22)
	_chk_music_mute.toggled.connect(func(b): AudioManager.set_music_muted(b))
	mus_hb.add_child(_chk_music_mute)

	var sfx_card := PanelContainer.new()
	sfx_card.add_theme_stylebox_override("panel", _make_box(Color(0.92, 0.97, 0.95), 14, Color(0.14, 0.48, 0.44, 0.22), 1, 14, 10))
	s_vb.add_child(sfx_card)
	var sfx_hb := HBoxContainer.new()
	sfx_hb.add_theme_constant_override("separation", 14)
	sfx_card.add_child(sfx_hb)
	_lbl_set_sfx = _make_label("SFX Volume", 24, Color(0.12, 0.32, 0.30), true)
	_lbl_set_sfx.custom_minimum_size = Vector2(220, 0)
	sfx_hb.add_child(_lbl_set_sfx)
	_slider_sfx = HSlider.new()
	_slider_sfx.min_value = 0.0
	_slider_sfx.max_value = 1.0
	_slider_sfx.step = 0.05
	_slider_sfx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider_sfx.custom_minimum_size = Vector2(0, 44)
	_slider_sfx.value_changed.connect(func(v): AudioManager.set_sfx_volume(v))
	sfx_hb.add_child(_slider_sfx)
	_chk_sfx_mute = CheckButton.new()
	_chk_sfx_mute.text = "Mute"
	_style_check_button(_chk_sfx_mute, 22)
	_chk_sfx_mute.toggled.connect(func(b): AudioManager.set_sfx_muted(b))
	sfx_hb.add_child(_chk_sfx_mute)

	var rm_card := PanelContainer.new()
	rm_card.add_theme_stylebox_override("panel", _make_box(Color(0.92, 0.97, 0.95), 14, Color(0.14, 0.48, 0.44, 0.22), 1, 14, 8))
	s_vb.add_child(rm_card)
	_chk_reduce_motion = CheckButton.new()
	_style_check_button(_chk_reduce_motion, 24)
	_chk_reduce_motion.toggled.connect(func(b):
		SaveManager.set_setting("reduce_motion", b)
		if b and _chk_screen_shake.button_pressed:
			_chk_screen_shake.button_pressed = false
	)
	rm_card.add_child(_chk_reduce_motion)

	var ss_card := PanelContainer.new()
	ss_card.add_theme_stylebox_override("panel", _make_box(Color(0.92, 0.97, 0.95), 14, Color(0.14, 0.48, 0.44, 0.22), 1, 14, 8))
	s_vb.add_child(ss_card)
	_chk_screen_shake = CheckButton.new()
	_style_check_button(_chk_screen_shake, 24)
	_chk_screen_shake.toggled.connect(func(b): SaveManager.set_setting("screen_shake", b))
	ss_card.add_child(_chk_screen_shake)

	var hap_card := PanelContainer.new()
	hap_card.add_theme_stylebox_override("panel", _make_box(Color(0.92, 0.97, 0.95), 14, Color(0.14, 0.48, 0.44, 0.22), 1, 14, 8))
	s_vb.add_child(hap_card)
	_chk_haptics = CheckButton.new()
	_style_check_button(_chk_haptics, 24)
	_chk_haptics.toggled.connect(func(b):
		SaveManager.set_setting("haptics", b)
		if b:
			GameManager.trigger_haptic(18)
	)
	hap_card.add_child(_chk_haptics)

	_lbl_set_theme = _make_label("Board Theme", 22, Color(0.12, 0.32, 0.30), true)
	s_vb.add_child(_lbl_set_theme)
	var thm_hb := HBoxContainer.new()
	thm_hb.add_theme_constant_override("separation", 10)
	s_vb.add_child(thm_hb)
	_btn_theme_garden = Button.new()
	_btn_theme_garden.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_theme_garden.custom_minimum_size = Vector2(0, 60)
	_btn_theme_garden.pressed.connect(func(): _select_board_theme("garden"))
	thm_hb.add_child(_btn_theme_garden)
	_btn_theme_sunset = Button.new()
	_btn_theme_sunset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_theme_sunset.custom_minimum_size = Vector2(0, 60)
	_btn_theme_sunset.pressed.connect(func(): _select_board_theme("sunset"))
	thm_hb.add_child(_btn_theme_sunset)
	_btn_theme_starlight = Button.new()
	_btn_theme_starlight.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_theme_starlight.custom_minimum_size = Vector2(0, 60)
	_btn_theme_starlight.pressed.connect(func(): _select_board_theme("starlight"))
	thm_hb.add_child(_btn_theme_starlight)

	var help_hb := HBoxContainer.new()
	help_hb.add_theme_constant_override("separation", 14)
	s_vb.add_child(help_hb)

	_btn_howto = Button.new()
	_btn_howto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_howto.custom_minimum_size = Vector2(0, 72)
	_style_button(_btn_howto, Color(0.18, 0.50, 0.62), Color(0.24, 0.60, 0.72), Color.WHITE, 26, 16)
	_btn_howto.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_open_modal(_modal_howto)
	)
	help_hb.add_child(_btn_howto)

	_btn_credits = Button.new()
	_btn_credits.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_credits.custom_minimum_size = Vector2(0, 72)
	_style_button(_btn_credits, Color(0.28, 0.38, 0.38), Color(0.36, 0.48, 0.48), Color.WHITE, 26, 16)
	_btn_credits.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_open_modal(_modal_credits)
	)
	help_hb.add_child(_btn_credits)

	_btn_set_reset = Button.new()
	_btn_set_reset.custom_minimum_size = Vector2(0, 72)
	_style_button(_btn_set_reset, Color(0.78, 0.24, 0.22), Color(0.88, 0.30, 0.28), Color.WHITE, 26)
	_btn_set_reset.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_open_modal(_modal_reset_confirm)
	)
	s_vb.add_child(_btn_set_reset)

	_btn_set_close = Button.new()
	_btn_set_close.custom_minimum_size = Vector2(0, 78)
	_style_button(_btn_set_close, Color(0.12, 0.56, 0.44), Color(0.16, 0.66, 0.52), Color.WHITE, 30)
	_btn_set_close.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		if _settings_return_to_pause:
			_open_modal(_modal_pause)
		else:
			_close_modals()
	)
	s_vb.add_child(_btn_set_close)

	# How to Play Modal
	_modal_howto = _create_modal_card(center, 900)
	var h_vb := VBoxContainer.new()
	h_vb.add_theme_constant_override("separation", 18)
	_modal_howto.add_child(h_vb)
	_lbl_howto_title = _make_label("How to Play", 44, Color(0.06, 0.27, 0.26), true, HORIZONTAL_ALIGNMENT_CENTER)
	h_vb.add_child(_lbl_howto_title)
	_lbl_howto_body = _make_label("", 26, Color(0.14, 0.28, 0.28), false)
	_lbl_howto_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h_vb.add_child(_lbl_howto_body)
	_btn_howto_close = Button.new()
	_btn_howto_close.custom_minimum_size = Vector2(0, 74)
	_style_button(_btn_howto_close, Color(0.12, 0.56, 0.44), Color(0.16, 0.66, 0.52), Color.WHITE, 28)
	_btn_howto_close.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_close_modals()
	)
	h_vb.add_child(_btn_howto_close)

	# Credits Modal
	_modal_credits = _create_modal_card(center, 900)
	var c_vb := VBoxContainer.new()
	c_vb.add_theme_constant_override("separation", 18)
	_modal_credits.add_child(c_vb)
	_lbl_credits_title = _make_label("Credits", 40, Color(0.06, 0.27, 0.26), true, HORIZONTAL_ALIGNMENT_CENTER)
	c_vb.add_child(_lbl_credits_title)
	_lbl_credits_body = _make_label("", 22, Color(0.14, 0.28, 0.28), false)
	_lbl_credits_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c_vb.add_child(_lbl_credits_body)
	_btn_credits_close = Button.new()
	_btn_credits_close.custom_minimum_size = Vector2(0, 74)
	_style_button(_btn_credits_close, Color(0.12, 0.56, 0.44), Color(0.16, 0.66, 0.52), Color.WHITE, 28)
	_btn_credits_close.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_close_modals()
	)
	c_vb.add_child(_btn_credits_close)

	# Sanctuary Almanac & Badges Modal
	_modal_almanac = _create_modal_card(center, 920)
	var a_vb := VBoxContainer.new()
	a_vb.add_theme_constant_override("separation", 14)
	_modal_almanac.add_child(a_vb)
	_lbl_almanac_title = _make_label("Sanctuary Almanac & Badges", 36, Color(0.06, 0.27, 0.26), true, HORIZONTAL_ALIGNMENT_CENTER)
	a_vb.add_child(_lbl_almanac_title)

	var tab_hb := HBoxContainer.new()
	tab_hb.add_theme_constant_override("separation", 14)
	a_vb.add_child(tab_hb)
	_btn_alm_cards = Button.new()
	_btn_alm_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_alm_cards.custom_minimum_size = Vector2(0, 62)
	_btn_alm_cards.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_almanac_tab = "cards"
		_refresh_almanac_ui()
	)
	tab_hb.add_child(_btn_alm_cards)
	_btn_alm_badges = Button.new()
	_btn_alm_badges.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_alm_badges.custom_minimum_size = Vector2(0, 62)
	_btn_alm_badges.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_almanac_tab = "badges"
		_refresh_almanac_ui()
	)
	tab_hb.add_child(_btn_alm_badges)

	var alm_scroll := ScrollContainer.new()
	alm_scroll.custom_minimum_size = Vector2(0, 940)
	alm_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	a_vb.add_child(alm_scroll)
	_alm_list_box = VBoxContainer.new()
	_alm_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_alm_list_box.add_theme_constant_override("separation", 12)
	alm_scroll.add_child(_alm_list_box)

	_btn_alm_close = Button.new()
	_btn_alm_close.custom_minimum_size = Vector2(0, 70)
	_style_button(_btn_alm_close, Color(0.12, 0.56, 0.44), Color(0.16, 0.66, 0.52), Color.WHITE, 26)
	_btn_alm_close.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_close_modals()
	)
	a_vb.add_child(_btn_alm_close)

	# Daily Quests & Star Milestone Chest Modal
	_modal_quests = _create_modal_card(center, 920)
	var q_vb := VBoxContainer.new()
	q_vb.add_theme_constant_override("separation", 14)
	_modal_quests.add_child(q_vb)
	_lbl_quests_title = _make_label("Daily Quests & Star Chest", 36, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	q_vb.add_child(_make_ribbon_header(_lbl_quests_title, Color(0.90, 0.56, 0.12), Color(0.68, 0.38, 0.04)))

	var charms_pill := PanelContainer.new()
	charms_pill.add_theme_stylebox_override("panel", _make_box(Color(0.94, 0.90, 1.0), 18, Color(0.56, 0.34, 0.88, 0.55), 2, 16, 10))
	q_vb.add_child(charms_pill)
	_lbl_quests_charms = _make_label("", 24, Color(0.32, 0.14, 0.62), true, HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_quests_charms.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	charms_pill.add_child(_lbl_quests_charms)

	var q_scroll := ScrollContainer.new()
	q_scroll.custom_minimum_size = Vector2(0, 760)
	q_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	q_vb.add_child(q_scroll)
	_quests_list_box = VBoxContainer.new()
	_quests_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quests_list_box.add_theme_constant_override("separation", 14)
	q_scroll.add_child(_quests_list_box)

	_btn_quests_close = Button.new()
	_btn_quests_close.custom_minimum_size = Vector2(0, 74)
	_style_button(_btn_quests_close, Color(0.10, 0.60, 0.46), Color(0.14, 0.70, 0.54), Color.WHITE, 28)
	_btn_quests_close.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_close_modals()
		_refresh_texts()
	)
	q_vb.add_child(_btn_quests_close)

	# Reset Confirmation
	_modal_reset_confirm = _create_modal_card(center, 780)
	var r_vb := VBoxContainer.new()
	r_vb.add_theme_constant_override("separation", 20)
	_modal_reset_confirm.add_child(r_vb)
	_lbl_reset_msg = _make_label("", 26, Color(0.16, 0.24, 0.24), true, HORIZONTAL_ALIGNMENT_CENTER)
	_lbl_reset_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r_vb.add_child(_lbl_reset_msg)
	var r_hb := HBoxContainer.new()
	r_hb.add_theme_constant_override("separation", 18)
	r_vb.add_child(r_hb)
	_btn_reset_cancel = Button.new()
	_btn_reset_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_reset_cancel.custom_minimum_size = Vector2(0, 72)
	_style_button(_btn_reset_cancel, Color(0.28, 0.38, 0.38), Color(0.36, 0.48, 0.48), Color.WHITE, 26)
	_btn_reset_cancel.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		_open_modal(_modal_settings)
	)
	r_hb.add_child(_btn_reset_cancel)
	_btn_reset_confirm = Button.new()
	_btn_reset_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_reset_confirm.custom_minimum_size = Vector2(0, 72)
	_style_button(_btn_reset_confirm, Color(0.78, 0.22, 0.20), Color(0.90, 0.28, 0.26), Color.WHITE, 26)
	_btn_reset_confirm.pressed.connect(func():
		AudioManager.play_sfx("menu_button")
		SaveManager.reset_progress_keep_settings()
		_selected_chapter = 1
		_refresh_texts()
		_open_modal(_modal_settings)
	)
	r_hb.add_child(_btn_reset_confirm)


func _create_modal_card(parent: Control, width_px: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(width_px, 0)
	card.add_theme_stylebox_override("panel", _make_box(Color(0.99, 0.985, 0.955, 0.98), 32, Color(0.94, 0.78, 0.42, 0.85), 5, 34, 28, 22))
	card.visible = false
	parent.add_child(card)
	return card


func _open_modal(modal: PanelContainer) -> void:
	if is_instance_valid(_board_renderer):
		var empty_chain: Array[Vector2i] = []
		_board_renderer.set_chain_preview(empty_chain, {})
	for m in [_modal_pause, _modal_win, _modal_lose, _modal_settings, _modal_howto, _modal_credits, _modal_almanac, _modal_quests, _modal_reset_confirm]:
		m.visible = (m == modal)
	_modal_dim.visible = true
	if _current_screen == "game":
		_touch_ctrl.set_input_enabled(false)
	if DisplayServer.get_name() != "headless" and not GameManager.is_reduce_motion():
		modal.pivot_offset = modal.size * 0.5
		modal.scale = Vector2.ONE * 0.88
		var tw := modal.create_tween()
		tw.tween_property(modal, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close_modals() -> void:
	_modal_dim.visible = false
	for m in [_modal_pause, _modal_win, _modal_lose, _modal_settings, _modal_howto, _modal_credits, _modal_almanac, _modal_quests, _modal_reset_confirm]:
		m.visible = false
	if _current_screen == "game" and GameManager.play_state == GameManager.PlayState.READY:
		_touch_ctrl.set_input_enabled(true)


func show_screen(screen_name: String) -> void:
	_current_screen = screen_name
	_close_modals()
	_screen_splash.visible = (screen_name == "splash")
	_screen_menu.visible = (screen_name == "menu")
	_screen_levels.visible = (screen_name == "levels")
	_screen_game.visible = (screen_name == "game")

	match screen_name:
		"splash":
			_bg_rect.texture = _tex_bg_splash
			GameManager.play_state = GameManager.PlayState.MENU
		"menu":
			_bg_rect.texture = _tex_bg_menu
			GameManager.play_state = GameManager.PlayState.MENU
			AudioManager.play_music("menu")
			_refresh_texts()
		"levels":
			_bg_rect.texture = _tex_bg_menu
			GameManager.play_state = GameManager.PlayState.MENU
			AudioManager.play_music("menu")
			_refresh_level_cards()
		"game":
			_bg_rect.texture = _tex_bg_game
			var is_boss := bool(level_def.get("is_boss", false))
			AudioManager.play_music("boss" if is_boss else "gameplay")


func start_level(level_id: int) -> void:
	var lv := level_manager.get_level(level_id)
	if lv.is_empty():
		return
	_current_mode = "campaign"
	GameManager.current_level_id = level_id
	_selected_chapter = clampi(1 + (level_id - 1) / 10, 1, 10)
	_begin_loaded_level(lv)


func start_endless_mode() -> void:
	_current_mode = "endless"
	_endless_wave = 1
	var lv := LevelManager.build_endless_wave_def(_endless_wave, 80000)
	_begin_loaded_level(lv)


func start_daily_challenge() -> void:
	_current_mode = "daily"
	var dt := Time.get_date_dict_from_system()
	var lv := LevelManager.build_daily_level(dt)
	_begin_loaded_level(lv)


func _set_difficulty(diff: String) -> void:
	AudioManager.play_sfx("menu_button")
	BoardState.set_difficulty_grid(diff)
	SaveManager.set_setting("difficulty", BoardState.current_difficulty)
	_refresh_difficulty_buttons()


func _refresh_difficulty_buttons() -> void:
	var cur := BoardState.current_difficulty
	var specs := [
		[_btn_diff_easy, "easy", Color(0.09, 0.62, 0.47)],
		[_btn_diff_medium, "medium", Color(0.14, 0.50, 0.68)],
		[_btn_diff_hard, "hard", Color(0.84, 0.42, 0.14)]
	]
	for item in specs:
		var btn: Button = item[0]
		if btn == null:
			continue
		var code: String = item[1]
		var active_col: Color = item[2]
		var is_sel := (cur == code)
		var bg := active_col if is_sel else Color(0.82, 0.89, 0.86)
		var fg := Color.WHITE if is_sel else Color(0.14, 0.30, 0.28)
		_style_button(btn, bg, bg.lightened(0.08), fg, 30, 18, 10, 10)


func _scale_level_for_difficulty(raw_lv: Dictionary) -> Dictionary:
	var lv := raw_lv.duplicate(true)
	var diff := BoardState.current_difficulty
	if diff == "hard":
		return lv
	var move_bonus := 4 if diff == "easy" else 2
	lv["moves"] = int(lv.get("moves", 16)) + move_bonus
	var mult := 0.75 if diff == "easy" else 0.90
	var objs: Dictionary = lv.get("objectives", {})
	if objs.has("collect"):
		var col_req: Dictionary = objs["collect"]
		for o in col_req.keys():
			col_req[o] = maxi(3, int(round(float(col_req[o]) * mult)))
	if objs.has("score"):
		objs["score"] = maxi(300, int(round(float(objs["score"]) * mult / 50.0)) * 50)
	if objs.has("activate_care"):
		objs["activate_care"] = maxi(1, int(round(float(objs["activate_care"]) * mult)))
	if objs.has("neutralize_overload"):
		objs["neutralize_overload"] = maxi(1, int(round(float(objs["neutralize_overload"]) * mult)))
	if objs.has("long_chains"):
		objs["long_chains"] = maxi(1, int(round(float(objs["long_chains"]) * mult)))
	return lv


func _begin_loaded_level(raw_lv: Dictionary) -> void:
	BoardState.set_difficulty_grid(str(SaveManager.get_setting("difficulty", BoardState.current_difficulty)))
	var lv := _scale_level_for_difficulty(raw_lv)
	level_def = lv
	rng.seed = int(lv.get("seed", 1001))
	board_state = LevelManager.build_board_for_level(lv, rng)
	progress = LevelManager.create_initial_progress(lv)

	show_screen("game")
	var is_tut := str(lv.get("tutorial_key", "")) != ""
	_board_renderer.set_board_state(board_state, is_tut)
	_touch_ctrl.set_board_state(board_state)
	GameManager.play_state = GameManager.PlayState.READY
	_touch_ctrl.set_input_enabled(true)
	_last_warning_active = false
	_last_live_stars = 0
	if is_instance_valid(_board_renderer):
		_board_renderer.set_fever_active(false)
	_refresh_hud()
	_lbl_preview.text = LocalizationManager.tr_key("PREVIEW_IDLE")
	_lbl_preview.add_theme_color_override("font_color", Color(0.08, 0.30, 0.28))
	AudioManager.play_sfx("level_transition")


func _play_sfx_delayed(sfx_name: String, delay_sec: float, pitch_scale: float = 1.0, vol_db: float = 0.0) -> void:
	if delay_sec <= 0.0 or DisplayServer.get_name() == "headless":
		AudioManager.play_sfx(sfx_name, pitch_scale, vol_db)
		return
	var timer := get_tree().create_timer(delay_sec)
	timer.timeout.connect(func():
		AudioManager.play_sfx(sfx_name, pitch_scale, vol_db)
	)


func _unlock_and_announce(ach_id: String) -> void:
	if SaveManager.unlock_achievement(ach_id):
		var full := LocalizationManager.tr_key(ach_id)
		var short_name := full.split(" — ")[0]
		_board_renderer.show_banner(LocalizationManager.tr_key("BANNER_BADGE_UNLOCKED", {"name": short_name}), Color(1.0, 0.84, 0.22))
		_play_sfx_delayed("star_pop", 0.32, 1.08, 0.0)


func _use_tactical_ability(kind: String) -> void:
	if _current_screen != "game" or GameManager.play_state != GameManager.PlayState.READY:
		return
	var res: Dictionary = {}
	match kind:
		"spark":
			res = BoosterSystem.cast_fruit_spark(board_state, level_def, progress, rng)
		"flow":
			res = BoosterSystem.cast_clear_flow(board_state, progress, 100)
		"rest":
			res = BoosterSystem.cast_rest_shield(board_state, progress, rng, 2)
	if not bool(res.get("used", false)):
		AudioManager.play_sfx("invalid_path", 1.0, -3.0)
		var rsn := str(res.get("reason", ""))
		if rsn == "no_effect":
			_lbl_preview.text = LocalizationManager.tr_key("ABL_NO_EFFECT_FLOW")
			_lbl_preview.add_theme_color_override("font_color", Color(0.76, 0.44, 0.08))
		elif rsn == "max_shields":
			_lbl_preview.text = LocalizationManager.tr_key("ABL_MAX_SHIELDS")
			_lbl_preview.add_theme_color_override("font_color", Color(0.76, 0.44, 0.08))
		return
	AudioManager.play_sfx("ability_cast")
	SaveManager.increment_stat("total_abilities_used", 1)
	_unlock_and_announce("ACH_ABILITY_1")
	SaveManager.save_to_disk()
	_board_renderer.animate_ability_effect(res)
	_refresh_hud()
	match kind:
		"spark":
			_lbl_preview.text = LocalizationManager.tr_key("ABL_USED_SPARK", {"count": res.get("cells", []).size()})
		"flow":
			_lbl_preview.text = LocalizationManager.tr_key("ABL_USED_FLOW")
		"rest":
			_lbl_preview.text = LocalizationManager.tr_key("ABL_USED_REST")
	_lbl_preview.add_theme_color_override("font_color", Color(0.06, 0.56, 0.34))


func _use_second_wind() -> void:
	if _current_screen != "game" or GameManager.play_state != GameManager.PlayState.LOSE:
		return
	if bool(progress.get("second_wind_used", false)):
		return
	if not SaveManager.spend_sanctuary_charm():
		AudioManager.play_sfx("invalid_path", 1.0, -3.0)
		return
	var sw := BoosterSystem.apply_second_wind(progress, 100, 2)
	if not bool(sw.get("used", false)):
		return
	_close_modals()
	GameManager.play_state = GameManager.PlayState.READY
	_touch_ctrl.set_input_enabled(true)
	_refresh_hud()
	AudioManager.play_sfx("ability_cast", 1.12)
	_play_sfx_delayed("star_pop", 0.14, 1.08)
	if is_instance_valid(_board_renderer):
		_board_renderer.show_banner(LocalizationManager.tr_key("BANNER_SECOND_WIND"), Color(1.0, 0.80, 0.18))
	_lbl_preview.text = LocalizationManager.tr_key("BANNER_SECOND_WIND")
	_lbl_preview.add_theme_color_override("font_color", Color(0.84, 0.48, 0.06))


func pause_game() -> void:
	if _current_screen != "game":
		return
	if GameManager.play_state == GameManager.PlayState.READY or GameManager.play_state == GameManager.PlayState.SELECTING:
		GameManager.play_state = GameManager.PlayState.PAUSED
		SaveManager.save_to_disk()
		_open_modal(_modal_pause)


func resume_game() -> void:
	if _current_screen == "game":
		GameManager.play_state = GameManager.PlayState.READY
		_close_modals()


func _on_chain_updated(chain: Array[Vector2i]) -> void:
	if _current_screen != "game" or board_state == null:
		return
	if chain.is_empty():
		GameManager.play_state = GameManager.PlayState.READY
		var empty_chain: Array[Vector2i] = []
		_board_renderer.set_chain_preview(empty_chain, {})
		_lbl_preview.text = LocalizationManager.tr_key("PREVIEW_IDLE")
		_lbl_preview.add_theme_color_override("font_color", Color(0.08, 0.30, 0.28))
		_last_warning_active = false
		return

	GameManager.play_state = GameManager.PlayState.SELECTING
	if chain.size() < 3:
		_board_renderer.set_chain_preview(chain, {})
		_lbl_preview.text = LocalizationManager.tr_key("PREVIEW_TOO_SHORT", {"need": 3 - chain.size()})
		_lbl_preview.add_theme_color_override("font_color", Color(0.18, 0.38, 0.42))
		_last_warning_active = false
		return

	var preview := PulseSystem.preview_endpoint(
		board_state,
		chain,
		int(progress.get("shield_charges", 0)),
		int(progress.get("pulse_meter", 100)),
		GameManager.config.get("balance", {})
	)
	_board_renderer.set_chain_preview(chain, preview)

	var tag := str(preview.get("summary_tag", "neutral"))
	var est_score := ScoreManager.calculate_chain_score(chain.size(), GameManager.get_balance("base_tile_score", 25))
	match tag:
		"loop":
			_lbl_preview.text = LocalizationManager.tr_key("PREVIEW_LOOP")
			_lbl_preview.add_theme_color_override("font_color", Color(0.76, 0.44, 0.04))
			_last_warning_active = false
		"loop_danger":
			_lbl_preview.text = LocalizationManager.tr_key("PREVIEW_LOOP_DANGER")
			_lbl_preview.add_theme_color_override("font_color", Color(0.84, 0.22, 0.12))
			if not _last_warning_active:
				AudioManager.play_sfx("hazard_warning")
				_last_warning_active = true
		"care":
			_lbl_preview.text = LocalizationManager.tr_key("PREVIEW_CARE")
			_lbl_preview.add_theme_color_override("font_color", Color(0.06, 0.56, 0.30))
			_last_warning_active = false
		"bloom":
			_lbl_preview.text = LocalizationManager.tr_key("PREVIEW_BLOOM")
			_lbl_preview.add_theme_color_override("font_color", Color(0.72, 0.48, 0.04))
			_last_warning_active = false
		"overload_blocked":
			_lbl_preview.text = LocalizationManager.tr_key("PREVIEW_OVERLOAD_BLOCK")
			_lbl_preview.add_theme_color_override("font_color", Color(0.06, 0.56, 0.36))
			_last_warning_active = false
		"overload_cracked":
			_lbl_preview.text = LocalizationManager.tr_key("PREVIEW_OVERLOAD_CRACK")
			_lbl_preview.add_theme_color_override("font_color", Color(0.76, 0.44, 0.06))
			_last_warning_active = false
		"care_and_overload":
			_lbl_preview.text = LocalizationManager.tr_key("PREVIEW_CARE_AND_OVERLOAD")
			_lbl_preview.add_theme_color_override("font_color", Color(0.06, 0.54, 0.34))
			_last_warning_active = false
		"overload_danger":
			_lbl_preview.text = LocalizationManager.tr_key("PREVIEW_OVERLOAD_WARN")
			_lbl_preview.add_theme_color_override("font_color", Color(0.82, 0.18, 0.12))
			if not _last_warning_active:
				AudioManager.play_sfx("hazard_warning")
				_last_warning_active = true
		_:
			if chain.size() >= 6:
				_lbl_preview.text = LocalizationManager.tr_key("PREVIEW_VITALITY_BURST")
				_lbl_preview.add_theme_color_override("font_color", Color(0.05, 0.56, 0.30))
			else:
				_lbl_preview.text = LocalizationManager.tr_key("PREVIEW_NEUTRAL", {"score": est_score})
				_lbl_preview.add_theme_color_override("font_color", Color(0.08, 0.40, 0.34))
			_last_warning_active = false


func _on_chain_cancelled(_reason: String) -> void:
	if _current_screen == "game" and GameManager.play_state == GameManager.PlayState.SELECTING:
		GameManager.play_state = GameManager.PlayState.READY


func _on_chain_committed(chain: Array[Vector2i]) -> void:
	if _current_screen != "game":
		return
	if GameManager.play_state != GameManager.PlayState.READY and GameManager.play_state != GameManager.PlayState.SELECTING:
		return

	GameManager.play_state = GameManager.PlayState.RESOLVING
	_touch_ctrl.set_input_enabled(false)

	var res := ChainResolver.resolve_turn(
		board_state,
		chain,
		level_def,
		progress,
		rng,
		GameManager.config.get("balance", {})
	)
	if not bool(res.get("committed", false)):
		GameManager.play_state = GameManager.PlayState.READY
		_touch_ctrl.set_input_enabled(true)
		return

	# Update career stats & mid-game achievements
	SaveManager.increment_stat("total_chains", 1)
	if bool(res.get("is_loop", false)):
		SaveManager.increment_stat("total_loops", 1)
		_unlock_and_announce("ACH_LOOP_1")
		if int(SaveManager.data.get("stats", {}).get("total_loops", 0)) >= 10:
			_unlock_and_announce("ACH_LOOP_10")
	var pulse: Dictionary = res.get("pulse", {})
	var neut := int(pulse.get("overloads_neutralized", 0))
	if neut > 0:
		SaveManager.increment_stat("total_overloads_cleared", neut)
		if int(SaveManager.data.get("stats", {}).get("total_overloads_cleared", 0)) >= 20:
			_unlock_and_announce("ACH_OVERLOAD_20")
	var healthy_count := int(res.get("healthy_popped", []).size()) + neut
	SaveManager.record_daily_quest_progress(
		SaveManager.get_today_date_str(),
		int(res.get("chain_len", 0)),
		1 if bool(res.get("is_loop", false)) else 0,
		healthy_count
	)
	SaveManager.save_to_disk()

	# Staggered SFX cadence across clear (0.00s) -> pulse/events (0.08s) -> refill (0.17s) -> score (0.25s)
	if bool(res.get("is_large_match", false)) or bool(res.get("is_loop", false)):
		AudioManager.play_sfx("match_large")
	else:
		AudioManager.play_sfx("match_small")
	_play_sfx_delayed("endpoint_pulse", 0.08)

	if int(pulse.get("care_activated", 0)) > 0 or int(pulse.get("blooms_collected", 0)) > 0:
		_play_sfx_delayed("shield_activate", 0.09)
	if neut > 0 or int(pulse.get("overloads_cracked", 0)) > 0:
		_play_sfx_delayed("shield_block", 0.11)
	if int(pulse.get("overloads_triggered", 0)) > 0:
		_play_sfx_delayed("hazard_trigger", 0.11)
		GameManager.trigger_haptic(40)
	if bool(res.get("fever_triggered", false)) or bool(res.get("vitality_burst_triggered", false)):
		_play_sfx_delayed("star_pop", 0.16, 1.18, 1.0)
		GameManager.trigger_haptic(45)
	_play_sfx_delayed("tile_refill", 0.17)
	_play_sfx_delayed("score_popup", 0.25)

	_refresh_hud()
	_board_renderer.animate_turn_resolution(res, func():
		_finish_turn_animations(res)
	)


func _finish_turn_animations(res: Dictionary) -> void:
	var status := str(res.get("status", "continue"))
	if status == "win":
		GameManager.trigger_haptic(30)
		if _current_mode == "endless":
			_advance_endless_wave()
			return
		GameManager.play_state = GameManager.PlayState.WIN
		var stars := int(res.get("stars", 1))
		if _current_mode == "daily":
			SaveManager.record_daily_win(str(level_def.get("daily_date", "")))
			_unlock_and_announce("ACH_DAILY_1")
			SaveManager.save_to_disk()
		else:
			var lid := int(level_def["id"])
			SaveManager.record_level_win(lid, stars, int(progress["score"]))
			if lid >= 1:
				_unlock_and_announce("ACH_FIRST_WIN")
			if lid >= 10:
				_unlock_and_announce("ACH_CH1")
			if lid >= 50:
				_unlock_and_announce("ACH_HALFWAY")
			if lid >= 100:
				_unlock_and_announce("ACH_MASTER_100")
			SaveManager.save_to_disk()
		AudioManager.play_sfx("victory")
		AudioManager.play_music("victory")
		_show_win_modal(stars, int(res.get("move_bonus", 0)))
	elif status == "lose":
		GameManager.play_state = GameManager.PlayState.LOSE
		if _current_mode == "endless":
			SaveManager.record_endless_run(_endless_wave, int(progress.get("score", 0)))
		SaveManager.save_to_disk()
		AudioManager.play_sfx("defeat")
		_show_lose_modal(str(res.get("lose_reason", "moves")))
	else:
		GameManager.play_state = GameManager.PlayState.READY
		_touch_ctrl.set_input_enabled(true)
		_lbl_preview.text = LocalizationManager.tr_key("PREVIEW_IDLE")
		_lbl_preview.add_theme_color_override("font_color", Color(0.08, 0.30, 0.28))


func _advance_endless_wave() -> void:
	var cleared_wave := _endless_wave
	_endless_wave += 1
	SaveManager.record_endless_run(_endless_wave, int(progress.get("score", 0)))
	if _endless_wave >= 5:
		_unlock_and_announce("ACH_ENDLESS_5")
		SaveManager.save_to_disk()
	var wave_is_boss := (cleared_wave % 5 == 0)
	var move_reward := 8 if wave_is_boss else 7
	var prev_score := int(progress.get("score", 0)) + 500
	var prev_moves := int(progress.get("moves_left", 0)) + move_reward
	var prev_pulse := mini(100, int(progress.get("pulse_meter", 100)) + 10)
	var prev_energy := int(progress.get("care_energy", 0))
	var prev_shields := int(progress.get("shield_charges", 0))
	var prev_streak := int(progress.get("combo_streak", 0))

	level_def = LevelManager.build_endless_wave_def(_endless_wave, 80000)
	rng.seed = int(level_def.get("seed", 80000))
	board_state = LevelManager.build_board_for_level(level_def, rng)
	progress = LevelManager.create_initial_progress(level_def)
	progress["score"] = prev_score
	progress["moves_left"] = prev_moves
	progress["pulse_meter"] = prev_pulse
	progress["care_energy"] = prev_energy
	progress["shield_charges"] = prev_shields
	progress["combo_streak"] = prev_streak

	_board_renderer.set_board_state(board_state, false)
	_touch_ctrl.set_board_state(board_state)
	GameManager.play_state = GameManager.PlayState.READY
	_touch_ctrl.set_input_enabled(true)
	_refresh_hud()
	AudioManager.play_sfx("victory")
	AudioManager.play_music("boss" if bool(level_def.get("is_boss", false)) else "gameplay")
	_board_renderer.show_banner(LocalizationManager.tr_key("BANNER_WAVE_CLEAR", {"wave": cleared_wave}), Color(0.24, 0.96, 0.62))
	_lbl_preview.text = LocalizationManager.tr_key("EVENT_WAVE_CLEAR", {"wave": cleared_wave, "moves": move_reward})
	_lbl_preview.add_theme_color_override("font_color", Color(0.06, 0.56, 0.32))


func _process(delta: float) -> void:
	if _screen_menu != null and _screen_menu.visible and DisplayServer.get_name() != "headless":
		var t := float(Time.get_ticks_msec()) * 0.001
		if GameManager.is_reduce_motion():
			if is_instance_valid(_menu_hero_icon):
				_menu_hero_icon.rotation = 0.0
				_menu_hero_icon.scale = Vector2.ONE
			if is_instance_valid(_menu_flank_left):
				_menu_flank_left.rotation = 0.0
			if is_instance_valid(_menu_flank_right):
				_menu_flank_right.rotation = 0.0
		else:
			if is_instance_valid(_menu_hero_icon):
				_menu_hero_icon.pivot_offset = _menu_hero_icon.size * 0.5
				var hs := 1.0 + 0.045 * sin(t * 2.8)
				_menu_hero_icon.scale = Vector2(hs, hs)
				_menu_hero_icon.rotation = sin(t * 1.9) * 0.05
			if is_instance_valid(_menu_flank_left):
				_menu_flank_left.pivot_offset = _menu_flank_left.size * 0.5
				_menu_flank_left.rotation = -0.08 + sin(t * 2.4 + 0.8) * 0.07
			if is_instance_valid(_menu_flank_right):
				_menu_flank_right.pivot_offset = _menu_flank_right.size * 0.5
				_menu_flank_right.rotation = 0.08 + sin(t * 2.4 + 2.1) * 0.07

	if _modal_win != null and _modal_win.visible and not _win_dance_sprites.is_empty():
		_win_dance_time += delta
		for i in range(_win_dance_sprites.size()):
			var sp: TextureRect = _win_dance_sprites[i]
			if not is_instance_valid(sp):
				continue
			if GameManager.is_reduce_motion():
				sp.position.y = 8.0
				sp.rotation = 0.0
				sp.scale = Vector2.ONE
			else:
				var phase := _win_dance_time * 6.5 + float(i) * 0.72
				sp.position.y = 8.0 - absf(sin(phase)) * 18.0
				sp.rotation = sin(phase * 0.8) * 0.16
				var sq := 1.04 + 0.08 * sin(phase * 1.4)
				sp.scale = Vector2(sq, 2.08 - sq)


func _show_win_modal(stars: int, move_bonus: int) -> void:
	if is_instance_valid(_board_renderer):
		_board_renderer.start_victory_dance()
	_win_dance_time = 0.0
	if _current_mode == "daily":
		_lbl_win_sub.text = LocalizationManager.tr_key("WIN_DAILY_DONE", {"streak": int(SaveManager.data.get("daily_streak", 1))})
		_btn_win_next.text = LocalizationManager.tr_key("BTN_MENU")
		_btn_win_menu.visible = false
	else:
		var lid := int(level_def.get("id", 1))
		_lbl_win_sub.text = LocalizationManager.tr_key("WIN_ALL_DONE" if lid >= 100 else "WIN_SUBTITLE")
		_btn_win_next.text = LocalizationManager.tr_key("BTN_LEVELS" if lid >= 100 else "BTN_NEXT_LEVEL")
		_btn_win_menu.visible = true

	var final_score := int(progress.get("score", 0))
	_lbl_win_score.text = LocalizationManager.tr_key("WIN_SCORE", {"score": final_score})
	_lbl_win_bonus.text = LocalizationManager.tr_key("WIN_BONUS", {"bonus": move_bonus})
	if is_instance_valid(_lbl_win_stats):
		_lbl_win_stats.text = LocalizationManager.tr_key("WIN_STATS_SUMMARY", {
			"chain": int(progress.get("best_chain_len", 0)),
			"loops": int(progress.get("loops_formed", 0)),
			"fever": int(progress.get("fever_activations", 0))
		})

	if GameManager.is_reduce_motion() or DisplayServer.get_name() == "headless":
		var star_str := ""
		for i in range(3):
			star_str += "★" if i < stars else "☆"
		_lbl_win_stars.text = star_str
		_open_modal(_modal_win)
		return

	_lbl_win_stars.text = "☆☆☆"
	_lbl_win_score.text = LocalizationManager.tr_key("WIN_SCORE", {"score": 0})
	_open_modal(_modal_win)
	var score_tw := create_tween()
	score_tw.tween_method(func(val: float):
		if is_instance_valid(_lbl_win_score):
			_lbl_win_score.text = LocalizationManager.tr_key("WIN_SCORE", {"score": int(round(val))})
	, 0.0, float(final_score), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var tw := create_tween()
	for s_idx in range(1, stars + 1):
		var count_now := s_idx
		tw.tween_interval(0.22)
		tw.tween_callback(func():
			var st := ""
			for j in range(3):
				st += "★" if j < count_now else "☆"
			_lbl_win_stars.text = st
			AudioManager.play_sfx("star_pop", 1.0 + float(count_now - 1) * 0.12)
		)


func _show_lose_modal(reason: String) -> void:
	if _current_mode == "endless":
		_lbl_lose_reason.text = LocalizationManager.tr_key("LOSE_ENDLESS", {"wave": _endless_wave, "score": int(progress.get("score", 0))})
	else:
		var key := "LOSE_REASON_PULSE" if reason == "pulse" else "LOSE_REASON_MOVES"
		_lbl_lose_reason.text = LocalizationManager.tr_key(key)
	var charms := SaveManager.get_sanctuary_charms()
	var can_revive := (not bool(progress.get("second_wind_used", false))) and charms > 0
	if is_instance_valid(_btn_lose_second_wind):
		_btn_lose_second_wind.visible = can_revive
		if can_revive:
			_btn_lose_second_wind.text = LocalizationManager.tr_key("BTN_SECOND_WIND", {"charms": charms})
	_open_modal(_modal_lose)


func _refresh_hud() -> void:
	if level_def.is_empty():
		return
	var lid := int(level_def.get("id", 1))
	var lv_title := str(level_def.get("title_id" if LocalizationManager.current_locale == "id" else "title_en", ""))
	var grid_tag := "(%d×%d)" % [BoardState.COLS, BoardState.ROWS]
	if _current_mode == "endless":
		_lbl_stage.text = "%s %s" % [LocalizationManager.tr_key("HUD_ENDLESS", {"wave": _endless_wave}), grid_tag]
	elif _current_mode == "daily":
		_lbl_stage.text = "%s %s" % [lv_title, grid_tag]
	else:
		_lbl_stage.text = "%s %s" % [LocalizationManager.tr_key("HUD_LEVEL", {"num": lid}), grid_tag]

	var streak := int(progress.get("combo_streak", 0))
	if streak >= 2:
		var mult := 1.0 + float(streak - 1) * 0.2
		_streak_pill.visible = true
		_lbl_streak.text = LocalizationManager.tr_key("HUD_STREAK", {"mult": "%.1f" % mult})
	else:
		_streak_pill.visible = false

	# Harmony Fever Pill & Board Glow
	var fever_turns := int(progress.get("fever_turns", 0))
	var fever_charge := int(progress.get("fever_charge", 0))
	if is_instance_valid(_fever_pill) and is_instance_valid(_lbl_fever):
		if fever_turns > 0:
			_lbl_fever.text = LocalizationManager.tr_key("HUD_FEVER_ACTIVE", {"turns": fever_turns})
			_lbl_fever.add_theme_color_override("font_color", Color.WHITE)
			_fever_pill.add_theme_stylebox_override("panel", _make_box(Color(0.96, 0.56, 0.08), 14, Color(1.0, 0.90, 0.42), 2, 12, 4))
		else:
			_lbl_fever.text = LocalizationManager.tr_key("HUD_FEVER_CHARGE", {"cur": fever_charge})
			_lbl_fever.add_theme_color_override("font_color", Color(0.56, 0.34, 0.04) if fever_charge >= 2 else Color(0.28, 0.38, 0.38))
			var f_bg := Color(1.0, 0.94, 0.76) if fever_charge >= 2 else Color(0.92, 0.95, 0.94)
			var f_bd := Color(0.94, 0.66, 0.16) if fever_charge >= 2 else Color(0.20, 0.50, 0.46, 0.25)
			_fever_pill.add_theme_stylebox_override("panel", _make_box(f_bg, 14, f_bd, 2, 12, 4))
	if is_instance_valid(_board_renderer):
		_board_renderer.set_fever_active(fever_turns > 0)

	var score_now := int(progress.get("score", 0))
	var moves_left := int(progress.get("moves_left", 0))
	_lbl_score_val.text = str(score_now)
	_lbl_moves_val.text = str(moves_left)
	if is_instance_valid(_moves_pill):
		if moves_left <= 5:
			_moves_pill.add_theme_stylebox_override("panel", _make_box(Color(1.0, 0.90, 0.88), 16, Color(0.88, 0.24, 0.20), 2, 16, 4))
			_lbl_moves_val.add_theme_color_override("font_color", Color(0.84, 0.16, 0.14))
		else:
			_moves_pill.add_theme_stylebox_override("panel", _make_box(Color(0.92, 0.97, 0.95), 16, Color(0.12, 0.54, 0.48, 0.32), 2, 16, 4))
			_lbl_moves_val.add_theme_color_override("font_color", Color(0.06, 0.30, 0.28))

	# Live 3-Star Score Progress Bar
	if is_instance_valid(_star_progress_bar) and is_instance_valid(_lbl_star_icons):
		var star_t: Array = level_def.get("star_thresholds", [600, 1200, 1900])
		var max_t := maxi(100, int(star_t[2]) if star_t.size() >= 3 else 1900)
		_star_progress_bar.max_value = max_t
		_star_progress_bar.value = mini(score_now, max_t)
		var cur_stars := 0
		for st_idx in range(mini(3, star_t.size())):
			if score_now >= int(star_t[st_idx]):
				cur_stars = st_idx + 1
		var star_icons := ""
		for j in range(3):
			star_icons += "★" if j < cur_stars else "☆"
		_lbl_star_icons.text = star_icons
		if cur_stars > _last_live_stars and GameManager.play_state == GameManager.PlayState.RESOLVING:
			_play_sfx_delayed("star_pop", 0.22, 1.0 + float(cur_stars - 1) * 0.12)
		_last_live_stars = cur_stars

	var pulse_val := clampi(int(progress.get("pulse_meter", 100)), 0, 100)
	_pulse_bar.value = pulse_val
	_lbl_pulse_val.text = "%d/100" % pulse_val
	var fill_col := Color(0.12, 0.76, 0.48) if pulse_val >= 60 else (Color(0.92, 0.62, 0.16) if pulse_val >= 30 else Color(0.88, 0.24, 0.20))
	_pulse_bar.add_theme_stylebox_override("fill", _make_box(fill_col, 8, Color(0, 0, 0, 0), 0, 0, 0))

	var shields := int(progress.get("shield_charges", 0))
	if shields > 0:
		_lbl_shield.text = LocalizationManager.tr_key("HUD_SHIELD_READY", {"count": shields})
		_lbl_shield.add_theme_color_override("font_color", Color(0.05, 0.46, 0.24))
		_shield_pill.add_theme_stylebox_override("panel", _make_box(Color(0.80, 0.98, 0.86), 12, Color(0.12, 0.72, 0.38), 2, 12, 3))
	else:
		_lbl_shield.text = LocalizationManager.tr_key("HUD_SHIELD_NONE")
		_lbl_shield.add_theme_color_override("font_color", Color(0.32, 0.42, 0.40))
		_shield_pill.add_theme_stylebox_override("panel", _make_box(Color(0.90, 0.94, 0.92), 12, Color(0.2, 0.5, 0.4, 0.25), 2, 12, 3))

	# Tactical Care Dock state
	var energy := clampi(int(progress.get("care_energy", 0)), 0, 100)
	_energy_bar.value = energy
	_lbl_energy_val.text = "%s %d/100" % [LocalizationManager.tr_key("HUD_CARE_ENERGY"), energy]
	_btn_abl_spark.text = "%s (%d)" % [LocalizationManager.tr_key("ABL_SPARK_NAME"), BoosterSystem.COST_FRUIT_SPARK]
	_btn_abl_flow.text = "%s (%d)" % [LocalizationManager.tr_key("ABL_FLOW_NAME"), BoosterSystem.COST_CLEAR_FLOW]
	_btn_abl_rest.text = "%s (%d)" % [LocalizationManager.tr_key("ABL_REST_NAME"), BoosterSystem.COST_REST_SHIELD]
	_btn_abl_spark.disabled = (energy < BoosterSystem.COST_FRUIT_SPARK)
	_btn_abl_flow.disabled = (energy < BoosterSystem.COST_CLEAR_FLOW)
	_btn_abl_rest.disabled = (energy < BoosterSystem.COST_REST_SHIELD)

	for ch in _objectives_box.get_children():
		ch.queue_free()
	var objs: Dictionary = level_def.get("objectives", {})
	var obj_done_sum := 0.0
	var obj_count := 0
	if objs.has("collect"):
		var col_req: Dictionary = objs["collect"]
		for organ in col_req.keys():
			var cur := int(progress.get("collected", {}).get(organ, 0))
			var tgt := maxi(1, int(col_req[organ]))
			obj_done_sum += clampf(float(cur) / float(tgt), 0.0, 1.0)
			obj_count += 1
			var o_name := LocalizationManager.tr_key("ORGAN_" + str(organ).to_upper())
			_add_objective_chip(LocalizationManager.tr_key("OBJ_COLLECT_ORGAN", {"organ": o_name, "current": mini(cur, tgt), "target": tgt}), cur >= tgt, str(organ))
	if objs.has("score"):
		var cur_s := int(progress.get("score", 0))
		var tgt_s := maxi(1, int(objs["score"]))
		obj_done_sum += clampf(float(cur_s) / float(tgt_s), 0.0, 1.0)
		obj_count += 1
		_add_objective_chip(LocalizationManager.tr_key("OBJ_SCORE", {"current": mini(cur_s, tgt_s), "target": tgt_s}), cur_s >= tgt_s, "")
	if objs.has("activate_care"):
		var cur_c := int(progress.get("care_activated", 0))
		var tgt_c := maxi(1, int(objs["activate_care"]))
		obj_done_sum += clampf(float(cur_c) / float(tgt_c), 0.0, 1.0)
		obj_count += 1
		_add_objective_chip(LocalizationManager.tr_key("OBJ_CARE", {"current": mini(cur_c, tgt_c), "target": tgt_c}), cur_c >= tgt_c, "care")
	if objs.has("neutralize_overload"):
		var cur_o := int(progress.get("overloads_neutralized", 0))
		var tgt_o := maxi(1, int(objs["neutralize_overload"]))
		obj_done_sum += clampf(float(cur_o) / float(tgt_o), 0.0, 1.0)
		obj_count += 1
		_add_objective_chip(LocalizationManager.tr_key("OBJ_OVERLOAD", {"current": mini(cur_o, tgt_o), "target": tgt_o}), cur_o >= tgt_o, "overload")
	if objs.has("long_chains"):
		var cur_l := int(progress.get("long_chains", 0))
		var tgt_l := maxi(1, int(objs["long_chains"]))
		obj_done_sum += clampf(float(cur_l) / float(tgt_l), 0.0, 1.0)
		obj_count += 1
		_add_objective_chip(LocalizationManager.tr_key("OBJ_LONG_CHAIN", {"current": mini(cur_l, tgt_l), "target": tgt_l}), cur_l >= tgt_l, "")
	if objs.has("keep_pulse"):
		var tgt_p := int(objs["keep_pulse"])
		_add_objective_chip(LocalizationManager.tr_key("OBJ_KEEP_PULSE", {"target": tgt_p}), pulse_val >= tgt_p, "")

	if is_instance_valid(_boss_bar_panel):
		var is_boss := bool(level_def.get("is_boss", false))
		_boss_bar_panel.visible = is_boss
		if is_boss:
			var pct_left := clampi(int(round((1.0 - (obj_done_sum / float(maxi(1, obj_count)))) * 100.0)), 0, 100)
			_boss_hp_bar.value = pct_left
			_lbl_boss_name.text = LocalizationManager.tr_key("BOSS_RESISTANCE", {
				"name": lv_title if lv_title != "" else ("#%d" % lid),
				"pct": pct_left
			})

	var tut_key := str(level_def.get("tutorial_key", ""))
	if tut_key != "":
		_tutorial_bar.visible = true
		_lbl_tutorial.text = LocalizationManager.tr_key(tut_key)
	else:
		_tutorial_bar.visible = false


func _add_objective_chip(text_str: String, done: bool, icon_key: String) -> void:
	var pill := PanelContainer.new()
	var bg := Color(0.82, 0.98, 0.88) if done else Color(0.92, 0.96, 0.95)
	var bcol := Color(0.10, 0.72, 0.42) if done else Color(0.18, 0.48, 0.46, 0.35)
	pill.add_theme_stylebox_override("panel", _make_box(bg, 14, bcol, 2, 14, 5))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	pill.add_child(hb)
	if icon_key != "" and _tile_icons.has(icon_key) and _tile_icons[icon_key] != null:
		var ic := TextureRect.new()
		ic.custom_minimum_size = Vector2(36, 36)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture = _tile_icons[icon_key]
		hb.add_child(ic)
	hb.add_child(_make_label(("✓ " if done else "") + text_str, 26, Color(0.05, 0.42, 0.24) if done else Color(0.10, 0.28, 0.28), true))
	_objectives_box.add_child(pill)


func _refresh_level_cards() -> void:
	var unlocked := SaveManager.get_unlocked_level()
	_lbl_levels_stars.text = "★ %d/300" % SaveManager.get_total_stars()

	for idx in range(_chapter_buttons.size()):
		var ch_num := idx + 1
		var cbtn := _chapter_buttons[idx]
		var first_lid := (ch_num - 1) * 10 + 1
		var ch_open := first_lid <= unlocked
		cbtn.text = "%d" % ch_num
		var bg := Color(0.09, 0.62, 0.47) if ch_num == _selected_chapter else (Color(0.20, 0.44, 0.52) if ch_open else Color(0.72, 0.79, 0.77))
		var tcol := Color.WHITE if (ch_num == _selected_chapter or ch_open) else Color(0.20, 0.30, 0.30)
		_style_button(cbtn, bg, bg.lightened(0.1), tcol, 24, 14, 6, 6)

	var ch_info: Array = CHAPTER_NAMES[_selected_chapter - 1]
	var ch_name := str(ch_info[2] if LocalizationManager.current_locale == "id" else ch_info[1])
	var ch_stars := 0
	var start_id := (_selected_chapter - 1) * 10 + 1
	for k in range(start_id, start_id + 10):
		ch_stars += SaveManager.get_level_stars(k)
	_lbl_chapter_banner.text = "%s  •  %s" % [
		LocalizationManager.tr_key("CHAPTER_LABEL", {"num": _selected_chapter, "name": ch_name}),
		LocalizationManager.tr_key("CHAPTER_PROGRESS", {"stars": ch_stars})
	]

	for i in range(_level_buttons.size()):
		var lid := start_id + i
		var btn := _level_buttons[i]
		var lv := level_manager.get_level(lid)
		var stars := SaveManager.get_level_stars(lid)
		var best := SaveManager.get_level_best_score(lid)
		var is_open := lid <= unlocked
		var is_boss := bool(lv.get("is_boss", false))
		btn.disabled = not is_open

		var star_line := ""
		if is_open:
			for s in range(3):
				star_line += "★" if s < stars else "☆"
		else:
			star_line = LocalizationManager.tr_key("LEVEL_LOCKED")

		var lv_name := str(lv.get("title_id" if LocalizationManager.current_locale == "id" else "title_en", ""))
		btn.text = "%s%s\n%s\n%s%s" % [
			LocalizationManager.tr_key("LEVEL_BOSS_TAG") if is_boss else "",
			LocalizationManager.tr_key("LEVEL_CARD", {"num": lid}),
			lv_name,
			star_line,
			(" • %d" % best if best > 0 else "")
		]
		if is_open:
			var bg := Color(0.78, 0.44, 0.12) if is_boss else (Color(0.11, 0.58, 0.46) if stars > 0 else Color(0.16, 0.50, 0.62))
			_style_button(btn, bg, bg.lightened(0.10), Color.WHITE, 22, 20)
		else:
			_style_button(btn, Color(0.68, 0.75, 0.74), Color(0.68, 0.75, 0.74), Color(0.24, 0.34, 0.34), 21, 20)


func _refresh_almanac_ui() -> void:
	_lbl_almanac_title.text = LocalizationManager.tr_key("ALMANAC_TITLE")
	_btn_alm_cards.text = LocalizationManager.tr_key("ALMANAC_CARDS_TAB")
	_btn_alm_badges.text = LocalizationManager.tr_key("ALMANAC_BADGES_TAB", {"count": SaveManager.get_unlocked_achievement_count()})
	_btn_alm_close.text = LocalizationManager.tr_key("BTN_CLOSE")

	var c_col := Color(0.09, 0.62, 0.47) if _almanac_tab == "cards" else Color(0.32, 0.44, 0.44)
	var b_col := Color(0.09, 0.62, 0.47) if _almanac_tab == "badges" else Color(0.32, 0.44, 0.44)
	_style_button(_btn_alm_cards, c_col, c_col.lightened(0.1), Color.WHITE, 26, 14)
	_style_button(_btn_alm_badges, b_col, b_col.lightened(0.1), Color.WHITE, 26, 14)

	for ch in _alm_list_box.get_children():
		ch.queue_free()

	if _almanac_tab == "cards":
		for item in ALMANAC_CARDS:
			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", _make_box(Color(0.92, 0.97, 0.95), 16, Color(0.14, 0.48, 0.44, 0.25), 2, 16, 14))
			var hb := HBoxContainer.new()
			hb.add_theme_constant_override("separation", 16)
			card.add_child(hb)
			var ic := TextureRect.new()
			ic.custom_minimum_size = Vector2(104, 104)
			ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ic.texture = _tile_icons.get(item[0], null)
			hb.add_child(ic)
			var txt := _make_label(LocalizationManager.tr_key(item[1]), 24, Color(0.08, 0.28, 0.26), false)
			txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			hb.add_child(txt)
			_alm_list_box.add_child(card)
	else:
		var st_dict: Dictionary = SaveManager.data.get("stats", {})
		var stats_card := PanelContainer.new()
		stats_card.add_theme_stylebox_override("panel", _make_box(Color(0.88, 0.96, 0.96), 16, Color(0.14, 0.52, 0.56, 0.45), 2, 16, 12))
		var stats_lbl := _make_label(LocalizationManager.tr_key("ALMANAC_STATS_HEADER", {
			"chains": int(st_dict.get("total_chains", 0)),
			"loops": int(st_dict.get("total_loops", 0)),
			"abilities": int(st_dict.get("total_abilities_used", 0)),
			"overloads": int(st_dict.get("total_overloads_cleared", 0))
		}), 24, Color(0.06, 0.30, 0.34), true)
		stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stats_card.add_child(stats_lbl)
		_alm_list_box.add_child(stats_card)

		for ak in ACHIEVEMENT_KEYS:
			var got := SaveManager.has_achievement(ak)
			var card := PanelContainer.new()
			var bg := Color(0.84, 0.98, 0.89) if got else Color(0.93, 0.95, 0.94)
			var bc := Color(0.10, 0.72, 0.40) if got else Color(0.6, 0.68, 0.66, 0.5)
			card.add_theme_stylebox_override("panel", _make_box(bg, 16, bc, 2, 16, 12))
			var txt := _make_label(("★ " if got else "○ ") + LocalizationManager.tr_key(ak), 25, Color(0.06, 0.36, 0.22) if got else Color(0.36, 0.44, 0.44), got)
			txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(txt)
			_alm_list_box.add_child(card)


func _refresh_quests_ui() -> void:
	if _quests_list_box == null:
		return
	_lbl_quests_title.text = LocalizationManager.tr_key("QUESTS_TITLE")
	_lbl_quests_charms.text = LocalizationManager.tr_key("QUESTS_CHARMS_BANNER", {"count": SaveManager.get_sanctuary_charms()})
	_btn_quests_close.text = LocalizationManager.tr_key("BTN_CLOSE")

	for ch in _quests_list_box.get_children():
		ch.queue_free()

	# 1. Star Milestone Chest Card
	var chest := SaveManager.get_star_chest_info()
	var chest_claimable := bool(chest.get("claimable", false))
	var chest_card := PanelContainer.new()
	chest_card.add_theme_stylebox_override("panel", _make_box(
		Color(1.0, 0.96, 0.84) if chest_claimable else Color(0.95, 0.97, 0.95),
		20,
		Color(0.94, 0.66, 0.14) if chest_claimable else Color(0.16, 0.50, 0.46, 0.30),
		3 if chest_claimable else 2,
		18,
		14
	))
	var ch_vb := VBoxContainer.new()
	ch_vb.add_theme_constant_override("separation", 8)
	chest_card.add_child(ch_vb)
	var ch_top := HBoxContainer.new()
	ch_top.add_theme_constant_override("separation", 12)
	ch_vb.add_child(ch_top)
	var ch_txt_vb := VBoxContainer.new()
	ch_txt_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ch_txt_vb.add_theme_constant_override("separation", 4)
	ch_top.add_child(ch_txt_vb)
	ch_txt_vb.add_child(_make_label(LocalizationManager.tr_key("STAR_CHEST_TITLE", {
		"current": int(chest.get("current_stars", 0)),
		"target": int(chest.get("next_milestone", 15))
	}), 28, Color(0.56, 0.32, 0.04), true))
	var ch_desc := _make_label(LocalizationManager.tr_key("STAR_CHEST_DESC", {"target": int(chest.get("next_milestone", 15))}), 21, Color(0.24, 0.34, 0.32), false)
	ch_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ch_txt_vb.add_child(ch_desc)

	var btn_chest := Button.new()
	btn_chest.custom_minimum_size = Vector2(200, 66)
	btn_chest.disabled = not chest_claimable
	if chest_claimable:
		btn_chest.text = LocalizationManager.tr_key("BTN_CLAIM", {"reward": int(chest.get("reward", 2))})
		_style_button(btn_chest, Color(0.92, 0.58, 0.10), Color(0.98, 0.68, 0.18), Color.WHITE, 24, 16)
	else:
		btn_chest.text = LocalizationManager.tr_key("BTN_IN_PROGRESS")
		_style_button(btn_chest, Color(0.76, 0.82, 0.80), Color(0.76, 0.82, 0.80), Color(0.32, 0.40, 0.40), 22, 16)
	btn_chest.pressed.connect(func():
		if SaveManager.claim_star_chest():
			AudioManager.play_sfx("star_pop", 1.15)
			_refresh_quests_ui()
			_refresh_texts()
	)
	ch_top.add_child(btn_chest)

	var ch_bar := ProgressBar.new()
	ch_bar.custom_minimum_size = Vector2(0, 16)
	ch_bar.show_percentage = false
	ch_bar.max_value = maxf(1.0, float(chest.get("next_milestone", 15)))
	ch_bar.value = minf(float(chest.get("current_stars", 0)), ch_bar.max_value)
	ch_bar.add_theme_stylebox_override("background", _make_box(Color(0.84, 0.88, 0.86), 8, Color(0, 0, 0, 0), 0, 0, 0))
	ch_bar.add_theme_stylebox_override("fill", _make_box(Color(0.96, 0.66, 0.12), 8, Color(0, 0, 0, 0), 0, 0, 0))
	ch_vb.add_child(ch_bar)
	_quests_list_box.add_child(chest_card)

	# 2. Daily Quest Cards
	var today := SaveManager.get_today_date_str()
	var quests := SaveManager.get_daily_quest_states(today)
	for q in quests:
		var q_idx := int(q.get("idx", 0))
		var cur := int(q.get("current", 0))
		var tgt := int(q.get("target", 1))
		var reward := int(q.get("reward", 1))
		var claimed := bool(q.get("claimed", false))
		var claimable := bool(q.get("claimable", false))

		var q_card := PanelContainer.new()
		var bg := Color(0.86, 0.98, 0.90) if claimed else (Color(1.0, 0.97, 0.86) if claimable else Color(0.95, 0.98, 0.96))
		var bc := Color(0.10, 0.70, 0.40) if claimed else (Color(0.92, 0.62, 0.12) if claimable else Color(0.16, 0.50, 0.46, 0.28))
		q_card.add_theme_stylebox_override("panel", _make_box(bg, 18, bc, 2, 16, 12))
		var q_vb := VBoxContainer.new()
		q_vb.add_theme_constant_override("separation", 8)
		q_card.add_child(q_vb)

		var q_hb := HBoxContainer.new()
		q_hb.add_theme_constant_override("separation", 12)
		q_vb.add_child(q_hb)

		var q_lbl := _make_label(LocalizationManager.tr_key(str(q.get("key", "QUEST_CHAINS")), {
			"current": mini(cur, tgt),
			"target": tgt
		}), 23, Color(0.08, 0.28, 0.26), true)
		q_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		q_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		q_hb.add_child(q_lbl)

		var q_btn := Button.new()
		q_btn.custom_minimum_size = Vector2(188, 62)
		q_btn.disabled = not claimable
		if claimed:
			q_btn.text = LocalizationManager.tr_key("BTN_CLAIMED")
			_style_button(q_btn, Color(0.12, 0.64, 0.42), Color(0.12, 0.64, 0.42), Color.WHITE, 22, 16)
		elif claimable:
			q_btn.text = LocalizationManager.tr_key("BTN_CLAIM", {"reward": reward})
			_style_button(q_btn, Color(0.92, 0.58, 0.10), Color(0.98, 0.68, 0.18), Color.WHITE, 24, 16)
		else:
			q_btn.text = LocalizationManager.tr_key("BTN_IN_PROGRESS")
			_style_button(q_btn, Color(0.76, 0.82, 0.80), Color(0.76, 0.82, 0.80), Color(0.32, 0.40, 0.40), 22, 16)
		q_btn.pressed.connect(func():
			if SaveManager.claim_daily_quest(today, q_idx):
				AudioManager.play_sfx("star_pop", 1.12)
				_refresh_quests_ui()
				_refresh_texts()
		)
		q_hb.add_child(q_btn)

		var q_bar := ProgressBar.new()
		q_bar.custom_minimum_size = Vector2(0, 14)
		q_bar.show_percentage = false
		q_bar.max_value = maxf(1.0, float(tgt))
		q_bar.value = minf(float(cur), q_bar.max_value)
		q_bar.add_theme_stylebox_override("background", _make_box(Color(0.84, 0.88, 0.86), 7, Color(0, 0, 0, 0), 0, 0, 0))
		q_bar.add_theme_stylebox_override("fill", _make_box(Color(0.10, 0.72, 0.46) if (claimed or claimable) else Color(0.16, 0.60, 0.74), 7, Color(0, 0, 0, 0), 0, 0, 0))
		q_vb.add_child(q_bar)
		_quests_list_box.add_child(q_card)


func _select_board_theme(theme_id: String) -> void:
	if not SaveManager.is_board_theme_unlocked(theme_id):
		AudioManager.play_sfx("invalid_path", 1.0, -3.0)
		return
	AudioManager.play_sfx("menu_button")
	GameManager.trigger_haptic(14)
	SaveManager.set_setting("board_theme", theme_id)
	if is_instance_valid(_board_renderer):
		_board_renderer.set_board_theme(theme_id)
	_sync_settings_ui()


func _sync_settings_ui() -> void:
	var lang := LocalizationManager.current_locale
	_btn_lang_en.text = LocalizationManager.tr_key("SETTINGS_LANG_EN")
	_btn_lang_id.text = LocalizationManager.tr_key("SETTINGS_LANG_ID")
	var en_col := Color(0.09, 0.62, 0.47) if lang == "en" else Color(0.35, 0.46, 0.46)
	var id_col := Color(0.09, 0.62, 0.47) if lang == "id" else Color(0.35, 0.46, 0.46)
	_style_button(_btn_lang_en, en_col, en_col.lightened(0.1), Color.WHITE, 24, 14)
	_style_button(_btn_lang_id, id_col, id_col.lightened(0.1), Color.WHITE, 24, 14)

	_slider_music.set_value_no_signal(float(SaveManager.get_setting("music_volume", 0.78)))
	_chk_music_mute.set_pressed_no_signal(bool(SaveManager.get_setting("music_muted", false)))
	_slider_sfx.set_value_no_signal(float(SaveManager.get_setting("sfx_volume", 0.85)))
	_chk_sfx_mute.set_pressed_no_signal(bool(SaveManager.get_setting("sfx_muted", false)))
	_chk_reduce_motion.set_pressed_no_signal(bool(SaveManager.get_setting("reduce_motion", false)))
	_chk_screen_shake.set_pressed_no_signal(bool(SaveManager.get_setting("screen_shake", true)))
	if is_instance_valid(_chk_haptics):
		_chk_haptics.set_pressed_no_signal(bool(SaveManager.get_setting("haptics", true)))

	var cur_thm := str(SaveManager.get_setting("board_theme", "garden"))
	var theme_specs := [
		[_btn_theme_garden, "garden", "THEME_GARDEN", 1, Color(0.09, 0.62, 0.47)],
		[_btn_theme_sunset, "sunset", "THEME_SUNSET", 3, Color(0.84, 0.42, 0.24)],
		[_btn_theme_starlight, "starlight", "THEME_STARLIGHT", 6, Color(0.24, 0.30, 0.66)]
	]
	for sp in theme_specs:
		var btn: Button = sp[0]
		if not is_instance_valid(btn):
			continue
		var tid: String = sp[1]
		var name_txt := LocalizationManager.tr_key(str(sp[2]))
		var req_rank: int = sp[3]
		var col: Color = sp[4]
		var open := SaveManager.is_board_theme_unlocked(tid)
		btn.disabled = not open
		if open:
			btn.text = ("✓ " if cur_thm == tid else "") + name_txt
			var bg := col if cur_thm == tid else Color(0.35, 0.46, 0.46)
			_style_button(btn, bg, bg.lightened(0.1), Color.WHITE, 21, 14)
		else:
			btn.text = "%s\n(%s)" % [name_txt, LocalizationManager.tr_key("THEME_LOCKED_RANK", {"rank": req_rank})]
			_style_button(btn, Color(0.74, 0.79, 0.78), Color(0.74, 0.79, 0.78), Color(0.32, 0.38, 0.38), 18, 14)


func _on_language_changed(_locale: String) -> void:
	_refresh_texts()


func _refresh_texts() -> void:
	_lbl_menu_title.text = LocalizationManager.tr_key("APP_TITLE")
	_lbl_menu_sub.text = LocalizationManager.tr_key("APP_SUBTITLE")
	_lbl_menu_tagline.text = LocalizationManager.tr_key("MENU_TAGLINE")
	_lbl_menu_worktag.text = LocalizationManager.tr_key("APP_WORKING_TAG")
	var unlocked := SaveManager.get_unlocked_level()
	var total_stars := SaveManager.get_total_stars()
	var charms := SaveManager.get_sanctuary_charms()
	var rank_info := SaveManager.get_sanctuary_rank()
	if is_instance_valid(_lbl_menu_rank):
		_lbl_menu_rank.text = LocalizationManager.tr_key("RANK_LABEL", {
			"rank": int(rank_info.get("rank", 1)),
			"tier": LocalizationManager.tr_key(str(rank_info.get("tier_key", "RANK_SEEDLING")))
		})
	if is_instance_valid(_lbl_menu_stars_chip):
		_lbl_menu_stars_chip.text = "★ %d/300" % total_stars
	if is_instance_valid(_lbl_menu_charms_chip):
		_lbl_menu_charms_chip.text = "✦ %d" % charms
	_lbl_menu_progress.text = LocalizationManager.tr_key("MENU_PROGRESS", {
		"unlocked": unlocked,
		"stars": total_stars,
		"streak": int(SaveManager.data.get("daily_streak", 0)),
		"ach": SaveManager.get_unlocked_achievement_count()
	})
	_lbl_diff_title.text = LocalizationManager.tr_key("DIFF_TITLE")
	_btn_diff_easy.text = LocalizationManager.tr_key("DIFF_EASY")
	_btn_diff_medium.text = LocalizationManager.tr_key("DIFF_MEDIUM")
	_btn_diff_hard.text = LocalizationManager.tr_key("DIFF_HARD")
	_refresh_difficulty_buttons()
	_btn_play.text = LocalizationManager.tr_key("BTN_CONTINUE", {"level": unlocked}) if unlocked > 1 else LocalizationManager.tr_key("BTN_PLAY")
	_btn_levels.text = LocalizationManager.tr_key("BTN_LEVELS")
	var unclaimed := SaveManager.get_unclaimed_rewards_count()
	if is_instance_valid(_btn_quests):
		if unclaimed > 0:
			_btn_quests.text = LocalizationManager.tr_key("BTN_QUESTS_READY", {"count": unclaimed})
			_style_button(_btn_quests, Color(0.94, 0.56, 0.08), Color(1.0, 0.66, 0.16), Color.WHITE, 28, 22, 16, 10)
		else:
			_btn_quests.text = LocalizationManager.tr_key("BTN_QUESTS")
			_style_button(_btn_quests, Color(0.86, 0.54, 0.12), Color(0.94, 0.62, 0.18), Color.WHITE, 28, 22, 16, 10)
	_btn_endless.text = LocalizationManager.tr_key("BTN_ENDLESS")
	_btn_daily.text = LocalizationManager.tr_key("BTN_DAILY")
	_btn_almanac.text = LocalizationManager.tr_key("BTN_ALMANAC")
	_btn_howto.text = LocalizationManager.tr_key("BTN_HOW_TO_PLAY")
	_btn_settings.text = LocalizationManager.tr_key("BTN_SETTINGS")
	_btn_credits.text = LocalizationManager.tr_key("BTN_CREDITS")

	_lbl_levels_title.text = LocalizationManager.tr_key("LEVEL_SELECT_TITLE")
	_btn_levels_back.text = LocalizationManager.tr_key("BTN_BACK")
	_refresh_level_cards()

	_lbl_score_title.text = LocalizationManager.tr_key("HUD_SCORE")
	_lbl_moves_title.text = LocalizationManager.tr_key("HUD_MOVES")
	_lbl_pulse_label.text = LocalizationManager.tr_key("HUD_PULSE")
	_btn_pause.text = LocalizationManager.tr_key("BTN_PAUSE")
	_btn_game_retry.text = LocalizationManager.tr_key("BTN_RETRY")
	_refresh_hud()

	_lbl_pause_title.text = LocalizationManager.tr_key("PAUSE_TITLE")
	_btn_pause_resume.text = LocalizationManager.tr_key("BTN_RESUME")
	_btn_pause_retry.text = LocalizationManager.tr_key("BTN_RETRY")
	_btn_pause_settings.text = LocalizationManager.tr_key("BTN_SETTINGS")
	_btn_pause_menu.text = LocalizationManager.tr_key("BTN_MENU")

	_lbl_win_title.text = LocalizationManager.tr_key("WIN_TITLE")
	_btn_win_retry.text = LocalizationManager.tr_key("BTN_RETRY")
	_btn_win_menu.text = LocalizationManager.tr_key("BTN_MENU")

	_lbl_lose_title.text = LocalizationManager.tr_key("LOSE_TITLE")
	_btn_lose_retry.text = LocalizationManager.tr_key("BTN_RETRY")
	_btn_lose_levels.text = LocalizationManager.tr_key("BTN_LEVELS")
	_btn_lose_menu.text = LocalizationManager.tr_key("BTN_MENU")

	_lbl_set_title.text = LocalizationManager.tr_key("SETTINGS_TITLE")
	_lbl_set_lang.text = LocalizationManager.tr_key("SETTINGS_LANGUAGE")
	_lbl_set_music.text = LocalizationManager.tr_key("SETTINGS_MUSIC")
	_lbl_set_sfx.text = LocalizationManager.tr_key("SETTINGS_SFX")
	_chk_music_mute.text = LocalizationManager.tr_key("SETTINGS_MUTE")
	_chk_sfx_mute.text = LocalizationManager.tr_key("SETTINGS_MUTE")
	_chk_reduce_motion.text = LocalizationManager.tr_key("SETTINGS_REDUCE_MOTION")
	_chk_screen_shake.text = LocalizationManager.tr_key("SETTINGS_SCREEN_SHAKE")
	if is_instance_valid(_chk_haptics):
		_chk_haptics.text = LocalizationManager.tr_key("SETTINGS_HAPTICS")
	if is_instance_valid(_lbl_set_theme):
		_lbl_set_theme.text = LocalizationManager.tr_key("SETTINGS_BOARD_THEME")
	_btn_set_reset.text = LocalizationManager.tr_key("BTN_RESET_PROGRESS")
	_btn_set_close.text = LocalizationManager.tr_key("BTN_CLOSE")
	_sync_settings_ui()

	_lbl_howto_title.text = LocalizationManager.tr_key("HOWTO_TITLE")
	_lbl_howto_body.text = LocalizationManager.tr_key("HOWTO_BODY")
	_btn_howto_close.text = LocalizationManager.tr_key("BTN_CLOSE")

	_lbl_credits_title.text = LocalizationManager.tr_key("CREDITS_TITLE")
	_lbl_credits_body.text = LocalizationManager.tr_key("CREDITS_BODY")
	_btn_credits_close.text = LocalizationManager.tr_key("BTN_CLOSE")

	_refresh_almanac_ui()
	_refresh_quests_ui()

	_lbl_reset_msg.text = LocalizationManager.tr_key("SETTINGS_RESET_CONFIRM")
	_btn_reset_confirm.text = LocalizationManager.tr_key("BTN_CONFIRM")
	_btn_reset_cancel.text = LocalizationManager.tr_key("BTN_CANCEL")


func _update_safe_area() -> void:
	var vp_sz := get_viewport_rect().size
	var pad_l := 20
	var pad_r := 20
	# Extra top margin on tall modern phones (Android punch-hole camera cutouts) while keeping 1080x1920 tight
	var pad_t := 64 if (OS.get_name() == "Android" or vp_sz.y >= 2100.0) else 22
	var pad_b := 22

	var win_sz := DisplayServer.window_get_size()
	if win_sz.x > 0 and win_sz.y > 0 and vp_sz.x > 0 and vp_sz.y > 0:
		var safe := DisplayServer.get_display_safe_area()
		if safe.size.x > 0 and safe.size.y > 0:
			var sx := vp_sz.x / float(win_sz.x)
			var sy := vp_sz.y / float(win_sz.y)
			pad_l = maxi(pad_l, int(ceil(float(safe.position.x) * sx)) + 12)
			pad_t = maxi(pad_t, int(ceil(float(safe.position.y) * sy)) + 14)
			var right_inset := win_sz.x - (safe.position.x + safe.size.x)
			var bot_inset := win_sz.y - (safe.position.y + safe.size.y)
			pad_r = maxi(pad_r, int(ceil(float(right_inset) * sx)) + 12)
			pad_b = maxi(pad_b, int(ceil(float(bot_inset) * sy)) + 14)

	_safe_margin.add_theme_constant_override("margin_left", pad_l)
	_safe_margin.add_theme_constant_override("margin_right", pad_r)
	_safe_margin.add_theme_constant_override("margin_top", pad_t)
	_safe_margin.add_theme_constant_override("margin_bottom", pad_b)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _modal_dim.visible:
			if _modal_pause.visible:
				resume_game()
			elif not _modal_win.visible and not _modal_lose.visible:
				_close_modals()
		elif _current_screen == "game":
			pause_game()
		elif _current_screen == "levels":
			show_screen("menu")


func get_layout_metrics() -> Dictionary:
	return {
		"viewport_size": get_viewport_rect().size,
		"board_host_size": _board_host.size if is_instance_valid(_board_host) else Vector2.ZERO,
		"board_rect": _board_renderer.get_board_rect() if is_instance_valid(_board_renderer) else Rect2(),
		"cell_px": _board_renderer.cell_px if is_instance_valid(_board_renderer) else 0,
		"hud_rect": _hud_panel.get_global_rect() if is_instance_valid(_hud_panel) else Rect2(),
		"bottom_rect": _bottom_panel.get_global_rect() if is_instance_valid(_bottom_panel) else Rect2()
	}
