class_name VFXController
extends Control
## Lightweight, Android-friendly particle bursts, pulse rings, combo banners, floating popups, and optional shake.

var _tex_star: Texture2D
var _tex_heart: Texture2D
var _tex_leaf: Texture2D
var _tex_pulse_ring: Texture2D
var _tex_shield_aura: Texture2D
var _font_bold: Font
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 9001
	_tex_star = _safe_load("res://assets/sprites/tiles/particle_star.png")
	_tex_heart = _safe_load("res://assets/sprites/tiles/particle_heart.png")
	_tex_leaf = _safe_load("res://assets/sprites/tiles/particle_leaf.png")
	_tex_pulse_ring = _safe_load("res://assets/sprites/tiles/pulse_ring.png")
	_tex_shield_aura = _safe_load("res://assets/sprites/tiles/overlay_shield_aura.png")
	_font_bold = _safe_load_font("res://assets/fonts/Inter-SemiBold.ttf")


func _safe_load(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


func _safe_load_font(path: String) -> Font:
	return load(path) if ResourceLoader.exists(path) else ThemeDB.fallback_font


func clear_all() -> void:
	for child in get_children():
		child.queue_free()


func spawn_tile_burst(local_pos: Vector2, kind: String, cell_px: int, is_large: bool = false) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var reduce := GameManager.is_reduce_motion()
	var count := 3 if reduce else (9 if is_large else 5)
	var tex := _tex_star
	var tint := Color(1, 0.9, 0.5)
	match kind:
		"heart":
			tex = _tex_heart
			tint = Color(1.0, 0.45, 0.58)
		"brain":
			tex = _tex_star
			tint = Color(0.76, 0.56, 1.0)
		"lungs":
			tex = _tex_star
			tint = Color(0.38, 0.92, 0.90)
		"kidneys":
			tex = _tex_star
			tint = Color(1.0, 0.72, 0.28)
		"stomach":
			tex = _tex_star
			tint = Color(1.0, 0.62, 0.36)
		"liver":
			tex = _tex_star
			tint = Color(1.0, 0.84, 0.22)
		"muscle":
			tex = _tex_heart
			tint = Color(0.96, 0.26, 0.64)
		"care":
			tex = _tex_leaf
			tint = Color(0.32, 0.96, 0.56)
		"bloom":
			tex = _tex_star
			tint = Color(1.0, 0.90, 0.32)
		"overload":
			tex = _tex_star
			tint = Color(1.0, 0.42, 0.25)

	if tex == null:
		return

	var base_scale := clampf(float(cell_px) / 360.0, 0.14, 0.40)
	for i in range(count):
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.modulate = tint
		sp.position = local_pos
		sp.scale = Vector2.ONE * base_scale * _rng.randf_range(0.75, 1.3)
		add_child(sp)

		var ang := (TAU / float(count)) * float(i) + _rng.randf_range(-0.35, 0.35)
		var dist := float(cell_px) * _rng.randf_range(0.45, 1.15 if is_large else 0.75)
		var target := local_pos + Vector2(cos(ang), sin(ang)) * dist
		var dur := 0.18 if reduce else _rng.randf_range(0.28, 0.46)

		var tw := sp.create_tween()
		tw.set_parallel(true)
		tw.tween_property(sp, "position", target, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(sp, "scale", Vector2.ZERO, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(sp, "modulate:a", 0.0, dur)
		tw.chain().tween_callback(sp.queue_free)


func spawn_pulse_ring(local_pos: Vector2, color: Color, cell_px: int, radius_cells: float = 1.65) -> void:
	if DisplayServer.get_name() == "headless" or _tex_pulse_ring == null:
		return
	var sp := Sprite2D.new()
	sp.texture = _tex_pulse_ring
	sp.modulate = color
	sp.position = local_pos
	var start_scale := float(cell_px) * 0.45 / 256.0
	var end_scale := float(cell_px) * radius_cells * 2.0 / 256.0
	sp.scale = Vector2.ONE * start_scale
	add_child(sp)

	var dur := 0.18 if GameManager.is_reduce_motion() else 0.42
	var tw := sp.create_tween()
	tw.set_parallel(true)
	tw.tween_property(sp, "scale", Vector2.ONE * end_scale, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(sp, "modulate:a", 0.0, dur)
	tw.chain().tween_callback(sp.queue_free)


func spawn_floating_text(local_pos: Vector2, text_str: String, color: Color, font_px: int = 28) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var lbl := Label.new()
	lbl.text = text_str
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", _font_bold)
	lbl.add_theme_font_size_override("font_size", font_px)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0.06, 0.12, 0.14, 0.96))
	lbl.add_theme_constant_override("outline_size", 7)
	lbl.size = Vector2(380, 52)
	lbl.pivot_offset = Vector2(190, 26)
	lbl.position = local_pos - Vector2(190, 26)
	add_child(lbl)

	var reduce := GameManager.is_reduce_motion()
	var rise := 18.0 if reduce else 72.0
	var dur := 0.35 if reduce else 0.86
	if not reduce:
		lbl.scale = Vector2.ONE * 0.65
	var tw := lbl.create_tween()
	tw.set_parallel(true)
	if not reduce:
		tw.tween_property(lbl, "scale", Vector2.ONE * 1.14, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(lbl, "scale", Vector2.ONE, 0.12).set_delay(0.14)
	tw.tween_property(lbl, "position:y", lbl.position.y - rise, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, dur * 0.45).set_delay(dur * 0.55)
	tw.chain().tween_callback(lbl.queue_free)


func spawn_combo_banner(center_pos: Vector2, text_str: String, color: Color) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.19, 0.18, 0.90)
	sb.border_color = color
	sb.set_border_width_all(4)
	sb.border_width_bottom = 7
	sb.set_corner_radius_all(28)
	sb.shadow_size = 14
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	sb.shadow_offset = Vector2(0, 6)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	pill.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text = text_str
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", _font_bold)
	lbl.add_theme_font_size_override("font_size", 42)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0.04, 0.10, 0.12, 0.96))
	lbl.add_theme_constant_override("outline_size", 8)
	pill.add_child(lbl)

	pill.custom_minimum_size = Vector2(560, 76)
	pill.size = Vector2(560, 76)
	pill.pivot_offset = Vector2(280, 38)
	pill.position = center_pos - Vector2(280, 38)
	pill.scale = Vector2.ONE * (1.0 if GameManager.is_reduce_motion() else 0.52)
	add_child(pill)

	var dur := 0.45 if GameManager.is_reduce_motion() else 1.05
	var tw := pill.create_tween()
	if not GameManager.is_reduce_motion():
		tw.tween_property(pill, "scale", Vector2.ONE * 1.12, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(pill, "scale", Vector2.ONE, 0.12)
	tw.tween_property(pill, "position:y", pill.position.y - (16.0 if GameManager.is_reduce_motion() else 48.0), dur * 0.65)
	tw.parallel().tween_property(pill, "modulate:a", 0.0, dur * 0.4).set_delay(dur * 0.6)
	tw.chain().tween_callback(pill.queue_free)


func spawn_confetti_burst(area: Rect2) -> void:
	if DisplayServer.get_name() == "headless" or GameManager.is_reduce_motion():
		return
	var palette := [
		Color(1.0, 0.84, 0.22),
		Color(0.20, 0.90, 0.58),
		Color(1.0, 0.42, 0.54),
		Color(0.32, 0.82, 1.0),
		Color(0.82, 0.50, 1.0)
	]
	var tex := _tex_star if _tex_star != null else _tex_leaf
	if tex == null:
		return
	for i in range(22):
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.modulate = palette[i % palette.size()]
		var start_x := area.position.x + _rng.randf_range(0.05, 0.95) * area.size.x
		var start_y := area.position.y - _rng.randf_range(10.0, 80.0)
		sp.position = Vector2(start_x, start_y)
		sp.scale = Vector2.ONE * _rng.randf_range(0.14, 0.28)
		sp.rotation = _rng.randf_range(0.0, TAU)
		add_child(sp)
		var end_pos := Vector2(start_x + _rng.randf_range(-90.0, 90.0), area.position.y + area.size.y * _rng.randf_range(0.55, 0.95))
		var dur := _rng.randf_range(0.95, 1.55)
		var tw := sp.create_tween()
		tw.set_parallel(true)
		tw.tween_property(sp, "position", end_pos, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(sp, "rotation", sp.rotation + _rng.randf_range(-4.0, 4.0), dur)
		tw.tween_property(sp, "modulate:a", 0.0, 0.45).set_delay(dur - 0.45)
		tw.chain().tween_callback(sp.queue_free)


func spawn_explosion_splash(local_pos: Vector2, color: Color, cell_px: int, intensity: float = 1.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var reduce := GameManager.is_reduce_motion()
	# Double concentric shockwave rings
	spawn_pulse_ring(local_pos, color, cell_px, 1.85 * intensity)
	if not reduce:
		spawn_pulse_ring(local_pos, Color(1.0, 0.96, 0.72, 0.95), cell_px, 2.75 * intensity)
	var tex := _tex_star if _tex_star != null else _tex_leaf
	if tex == null:
		return
	var count := 6 if reduce else clampi(int(round(16.0 * intensity)), 12, 28)
	var base_scale := clampf(float(cell_px) / 290.0, 0.18, 0.48)
	var palette := [color, Color(1.0, 0.92, 0.36), Color(1.0, 0.48, 0.22), Color(1.0, 1.0, 1.0)]
	for i in range(count):
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.modulate = palette[i % palette.size()]
		sp.position = local_pos
		sp.scale = Vector2.ONE * base_scale * _rng.randf_range(0.85, 1.45)
		sp.rotation = _rng.randf_range(0.0, TAU)
		add_child(sp)
		var ang := (TAU / float(count)) * float(i) + _rng.randf_range(-0.22, 0.22)
		var dist := float(cell_px) * _rng.randf_range(0.85, 2.15 * intensity)
		var target := local_pos + Vector2(cos(ang), sin(ang)) * dist
		var dur := 0.22 if reduce else _rng.randf_range(0.38, 0.62)
		var tw := sp.create_tween()
		tw.set_parallel(true)
		tw.tween_property(sp, "position", target, dur).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.tween_property(sp, "rotation", sp.rotation + _rng.randf_range(-5.0, 5.0), dur)
		tw.tween_property(sp, "scale", Vector2.ZERO, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(sp, "modulate:a", 0.0, dur)
		tw.chain().tween_callback(sp.queue_free)


func spawn_cross_beam(center_pos: Vector2, board_rect: Rect2, color: Color) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var reduce := GameManager.is_reduce_motion()
	var dur := 0.20 if reduce else 0.44
	var beam_thickness := clampf(board_rect.size.x * 0.085, 42.0, 74.0)

	# Horizontal beam across board
	var h_beam := ColorRect.new()
	h_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h_beam.color = Color(color.r, color.g, color.b, 0.88)
	h_beam.position = Vector2(board_rect.position.x, center_pos.y - beam_thickness * 0.5)
	h_beam.size = Vector2(board_rect.size.x, beam_thickness)
	h_beam.pivot_offset = Vector2(board_rect.size.x * 0.5, beam_thickness * 0.5)
	add_child(h_beam)

	# Vertical beam across board
	var v_beam := ColorRect.new()
	v_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_beam.color = Color(color.r, color.g, color.b, 0.88)
	v_beam.position = Vector2(center_pos.x - beam_thickness * 0.5, board_rect.position.y)
	v_beam.size = Vector2(beam_thickness, board_rect.size.y)
	v_beam.pivot_offset = Vector2(beam_thickness * 0.5, board_rect.size.y * 0.5)
	add_child(v_beam)

	var beams: Array[ColorRect] = [h_beam, v_beam]
	for beam in beams:
		var tw: Tween = beam.create_tween()
		tw.set_parallel(true)
		if beam == h_beam:
			tw.tween_property(beam, "scale", Vector2(1.0, 0.08), dur).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		else:
			tw.tween_property(beam, "scale", Vector2(0.08, 1.0), dur).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tw.tween_property(beam, "modulate:a", 0.0, dur)
		tw.chain().tween_callback(beam.queue_free)


func spawn_screen_flash(area: Rect2, color: Color, duration: float = 0.42) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var flash := ColorRect.new()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(color.r, color.g, color.b, 0.34 if GameManager.is_reduce_motion() else 0.52)
	flash.position = area.position
	flash.size = area.size
	add_child(flash)
	var dur := minf(duration, 0.22) if GameManager.is_reduce_motion() else duration
	var tw := flash.create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(flash.queue_free)


func trigger_shake(target: Control, strength: float = 8.0) -> void:
	if DisplayServer.get_name() == "headless" or target == null:
		return
	if not GameManager.is_screen_shake_enabled():
		return
	var base_pos := target.position
	var tw := target.create_tween()
	tw.tween_property(target, "position", base_pos + Vector2(strength, -strength * 0.5), 0.04)
	tw.tween_property(target, "position", base_pos + Vector2(-strength * 0.8, strength * 0.6), 0.04)
	tw.tween_property(target, "position", base_pos + Vector2(strength * 0.4, strength * 0.3), 0.04)
	tw.tween_property(target, "position", base_pos, 0.04)
