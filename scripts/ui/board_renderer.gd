class_name BoardRenderer
extends Control
## Renders the exact 7x12 square cell board, glossy 2.5D smiling organs (normal & happy),
## Overload variants, Vitality Blooms, glowing Nadi Loop / Endpoint Pulse previews, and idle hand hints.

const TILE_TEXTURE_PATHS := {
	"heart": "res://assets/sprites/tiles/organ_heart.png",
	"heart_happy": "res://assets/sprites/tiles/organ_heart_happy.png",
	"brain": "res://assets/sprites/tiles/organ_brain.png",
	"brain_happy": "res://assets/sprites/tiles/organ_brain_happy.png",
	"lungs": "res://assets/sprites/tiles/organ_lungs.png",
	"lungs_happy": "res://assets/sprites/tiles/organ_lungs_happy.png",
	"kidneys": "res://assets/sprites/tiles/organ_kidneys.png",
	"kidneys_happy": "res://assets/sprites/tiles/organ_kidneys_happy.png",
	"stomach": "res://assets/sprites/tiles/organ_stomach.png",
	"stomach_happy": "res://assets/sprites/tiles/organ_stomach_happy.png",
	"liver": "res://assets/sprites/tiles/organ_liver.png",
	"liver_happy": "res://assets/sprites/tiles/organ_liver_happy.png",
	"muscle": "res://assets/sprites/tiles/organ_muscle.png",
	"muscle_happy": "res://assets/sprites/tiles/organ_muscle_happy.png",
	"care": "res://assets/sprites/tiles/special_care.png",
	"bloom": "res://assets/sprites/tiles/special_bloom.png",
	"overload": "res://assets/sprites/tiles/special_overload.png",
	"overload_soda": "res://assets/sprites/tiles/special_overload_soda.png",
	"overload_snack": "res://assets/sprites/tiles/special_overload_snack.png",
	"overload_armor": "res://assets/sprites/tiles/special_overload_armor.png"
}

const ORGAN_COLORS := {
	"heart": Color(0.95, 0.18, 0.30, 0.94),
	"brain": Color(0.66, 0.34, 0.95, 0.94),
	"lungs": Color(0.14, 0.76, 0.95, 0.94),
	"kidneys": Color(0.68, 0.34, 0.14, 0.94),
	"stomach": Color(0.98, 0.48, 0.16, 0.94),
	"liver": Color(0.98, 0.78, 0.12, 0.94),
	"muscle": Color(0.88, 0.18, 0.52, 0.94)
}

var cell_px: int = 80
var board_origin: Vector2 = Vector2.ZERO
var board_pixel_size: Vector2 = Vector2.ZERO
var hint_delay_sec: float = 5.0

var _board_state: BoardState
var _tile_layer: Control
var _pulse_overlay: Control
var _vfx: VFXController
var _textures: Dictionary = {}
var _tex_restricted: Texture2D
var _font_bold: Font

var _tile_nodes: Dictionary = {}
var _active_chain: Array[Vector2i] = []
var _endpoint_preview: Dictionary = {}
var _anim_time: float = 0.0
var _idle_hint_timer: float = 0.0
var _hint_chain: Array[Vector2i] = []
var _is_animating: bool = false
var _victory_dance: bool = false
var _victory_dance_time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load_assets()

	_tile_layer = Control.new()
	_tile_layer.name = "TileLayer"
	_tile_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tile_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_tile_layer)

	_pulse_overlay = Control.new()
	_pulse_overlay.name = "PulseOverlay"
	_pulse_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pulse_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pulse_overlay.draw.connect(_draw_pulse_overlay)
	add_child(_pulse_overlay)

	_vfx = VFXController.new()
	_vfx.name = "VFXController"
	_vfx.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_vfx)

	resized.connect(_on_resized)
	_recompute_geometry()


func _load_assets() -> void:
	for k in TILE_TEXTURE_PATHS.keys():
		var p: String = TILE_TEXTURE_PATHS[k]
		if ResourceLoader.exists(p):
			_textures[k] = load(p)
	if ResourceLoader.exists("res://assets/sprites/tiles/overlay_restricted.png"):
		_tex_restricted = load("res://assets/sprites/tiles/overlay_restricted.png")
	if ResourceLoader.exists("res://assets/fonts/Inter-SemiBold.ttf"):
		_font_bold = load("res://assets/fonts/Inter-SemiBold.ttf")
	else:
		_font_bold = ThemeDB.fallback_font


func _on_resized() -> void:
	_recompute_geometry()
	if _board_state != null and not _is_animating:
		sync_board_immediate()
	queue_redraw()
	if is_instance_valid(_pulse_overlay):
		_pulse_overlay.queue_redraw()


func _recompute_geometry() -> void:
	var usable_w := maxf(210.0, size.x)
	var usable_h := maxf(360.0, size.y)
	cell_px = int(floor(minf(usable_w / float(BoardState.COLS), usable_h / float(BoardState.ROWS))))
	cell_px = maxi(24, cell_px)
	board_pixel_size = Vector2(float(cell_px * BoardState.COLS), float(cell_px * BoardState.ROWS))
	board_origin = Vector2(
		floor((size.x - board_pixel_size.x) * 0.5),
		floor((size.y - board_pixel_size.y) * 0.5)
	)


func get_board_rect() -> Rect2:
	return Rect2(board_origin, board_pixel_size)


func cell_top_left(pos: Vector2i) -> Vector2:
	return board_origin + Vector2(float(pos.x * cell_px), float(pos.y * cell_px))


func cell_center(pos: Vector2i) -> Vector2:
	return cell_top_left(pos) + Vector2(float(cell_px) * 0.5, float(cell_px) * 0.5)


func local_to_cell(local_pos: Vector2, allow_edge_margin: bool = false) -> Vector2i:
	var rel := local_pos - board_origin
	if allow_edge_margin:
		var pad := float(cell_px) * 0.35
		if rel.x >= -pad and rel.x <= board_pixel_size.x + pad and rel.y >= -pad and rel.y <= board_pixel_size.y + pad:
			return Vector2i(
				clampi(int(floor(rel.x / float(cell_px))), 0, BoardState.COLS - 1),
				clampi(int(floor(rel.y / float(cell_px))), 0, BoardState.ROWS - 1)
			)
		return Vector2i(-1, -1)

	if rel.x < 0.0 or rel.y < 0.0 or rel.x >= board_pixel_size.x or rel.y >= board_pixel_size.y:
		return Vector2i(-1, -1)
	return Vector2i(int(floor(rel.x / float(cell_px))), int(floor(rel.y / float(cell_px))))


func reset_idle_hint() -> void:
	_idle_hint_timer = 0.0
	if not _hint_chain.is_empty():
		_hint_chain.clear()
		if is_instance_valid(_pulse_overlay):
			_pulse_overlay.queue_redraw()


func set_board_state(state: BoardState, is_tutorial_stage: bool = false) -> void:
	_board_state = state
	_victory_dance = false
	_victory_dance_time = 0.0
	_active_chain.clear()
	_endpoint_preview.clear()
	_hint_chain.clear()
	_idle_hint_timer = 0.0
	hint_delay_sec = 1.8 if is_tutorial_stage else 5.2
	_vfx.clear_all()
	_recompute_geometry()
	sync_board_immediate()
	queue_redraw()
	if is_instance_valid(_pulse_overlay):
		_pulse_overlay.queue_redraw()


func set_chain_preview(chain: Array[Vector2i], preview: Dictionary) -> void:
	_active_chain = chain.duplicate()
	_endpoint_preview = preview
	reset_idle_hint()
	_update_selection_visuals()
	queue_redraw()
	if is_instance_valid(_pulse_overlay):
		_pulse_overlay.queue_redraw()


func _resolve_tex_key(cell: Dictionary, happy: bool = false) -> String:
	var kind := str(cell.get("kind", "organ"))
	if kind == "organ":
		var org := str(cell.get("organ", "heart"))
		return (org + "_happy") if happy else org
	if kind == "overload":
		if int(cell.get("hp", 1)) > 1:
			return "overload_armor"
		var c := int(cell.get("col", 0))
		var r := int(cell.get("row", 0))
		var variants := ["overload", "overload_soda", "overload_snack"]
		return variants[(c * 3 + r) % 3]
	return kind


func _update_selection_visuals() -> void:
	if _board_state == null:
		return
	var selected_ids := {}
	for p in _active_chain:
		var c := _board_state.get_cell(p)
		var tid := int(c.get("id", 0))
		if tid > 0:
			selected_ids[tid] = true

	var ep_id := 0
	if _active_chain.size() >= 3:
		ep_id = int(_board_state.get_cell(_active_chain[_active_chain.size() - 1]).get("id", 0))

	for tid in _tile_nodes.keys():
		var node: Control = _tile_nodes[tid]
		if not is_instance_valid(node):
			continue
		var is_sel := selected_ids.has(tid)
		node.scale = Vector2.ONE * (1.18 if tid == ep_id else (1.12 if is_sel else 1.0))
		node.z_index = 4 if tid == ep_id else (2 if is_sel else 0)
		var sp := node.get_node_or_null("Sprite") as TextureRect
		if sp != null and str(node.get_meta("kind", "")) == "organ":
			var base_key := str(node.get_meta("base_organ", "heart"))
			var use_key := (base_key + "_happy") if is_sel else base_key
			if _textures.has(use_key):
				sp.texture = _textures[use_key]


func sync_board_immediate() -> void:
	for k in _tile_nodes.keys():
		if is_instance_valid(_tile_nodes[k]):
			_tile_nodes[k].queue_free()
	_tile_nodes.clear()

	if _board_state == null:
		return

	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			var cell := _board_state.get_cell(Vector2i(c, r))
			if cell.get("kind", "empty") == "empty":
				continue
			var node := _create_tile_node(cell)
			node.position = cell_center(Vector2i(c, r))
			_tile_layer.add_child(node)
			_tile_nodes[int(cell["id"])] = node


func _create_tile_node(cell: Dictionary) -> Control:
	var tid := int(cell.get("id", 0))
	var kind := str(cell.get("kind", "organ"))
	var organ := str(cell.get("organ", ""))
	var tex_key := _resolve_tex_key(cell, false)
	var restricted := int(cell.get("restricted_turns", 0)) > 0

	var root := Control.new()
	root.name = "Tile_%d" % tid
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_meta("col", int(cell.get("col", 0)))
	root.set_meta("row", int(cell.get("row", 0)))
	root.set_meta("kind", kind)
	root.set_meta("base_organ", organ)
	root.set_meta("tex_key", tex_key)

	var sprite_px := float(cell_px) * 0.95
	var tr := TextureRect.new()
	tr.name = "Sprite"
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size = Vector2(sprite_px, sprite_px)
	tr.position = Vector2(-sprite_px * 0.5, -sprite_px * 0.5)
	tr.pivot_offset = Vector2(sprite_px * 0.5, sprite_px * 0.5)
	tr.texture = _textures.get(tex_key, null)
	if restricted:
		tr.modulate = Color(0.75, 0.72, 0.72, 0.90)
	root.add_child(tr)

	if restricted and _tex_restricted != null:
		var lock_r := TextureRect.new()
		lock_r.name = "LockOverlay"
		lock_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var ov_px := float(cell_px) * 0.92
		lock_r.size = Vector2(ov_px, ov_px)
		lock_r.position = Vector2(-ov_px * 0.5, -ov_px * 0.5)
		lock_r.texture = _tex_restricted
		root.add_child(lock_r)

	return root


func show_banner(text_str: String, col: Color) -> void:
	if DisplayServer.get_name() == "headless" or not is_instance_valid(_vfx):
		return
	var banner_pos := board_origin + Vector2(board_pixel_size.x * 0.5, board_pixel_size.y * 0.16)
	_vfx.spawn_combo_banner(banner_pos, text_str, col)


func animate_ability_effect(res: Dictionary) -> void:
	reset_idle_hint()
	sync_board_immediate()
	if DisplayServer.get_name() == "headless":
		return
	var ability := str(res.get("ability", ""))
	if ability == "spark":
		for p in res.get("cells", []):
			var center := cell_center(p)
			_vfx.spawn_tile_burst(center, str(res.get("organ", "heart")), cell_px, true)
			_vfx.spawn_pulse_ring(center, Color(1.0, 0.85, 0.25, 0.9), cell_px, 1.1)
	elif ability == "flow":
		for p in res.get("cleared", []):
			var center := cell_center(p)
			_vfx.spawn_tile_burst(center, "lungs", cell_px, false)
		_vfx.spawn_floating_text(board_origin + board_pixel_size * 0.5, LocalizationManager.tr_key("POPUP_PLUS_PULSE", {"val": 12}), Color(0.30, 0.95, 0.85), 34)
	elif ability == "rest":
		var cp: Vector2i = res.get("care_pos", Vector2i(-1, -1))
		if BoardState.is_in_bounds(cp):
			var center := cell_center(cp)
			_vfx.spawn_tile_burst(center, "care", cell_px, true)
			_vfx.spawn_pulse_ring(center, Color(0.28, 0.98, 0.56, 0.95), cell_px, 1.4)


func animate_turn_resolution(result: Dictionary, on_finished: Callable) -> void:
	if DisplayServer.get_name() == "headless":
		sync_board_immediate()
		if on_finished.is_valid():
			on_finished.call()
		return

	_is_animating = true
	_active_chain.clear()
	_endpoint_preview.clear()
	reset_idle_hint()
	_update_selection_visuals()
	queue_redraw()
	if is_instance_valid(_pulse_overlay):
		_pulse_overlay.queue_redraw()

	var reduce := GameManager.is_reduce_motion()
	var clear_dur := 0.08 if reduce else 0.16
	var drop_dur := 0.08 if reduce else 0.22

	var organ_kind := str(result.get("organ", "heart"))
	var is_large := bool(result.get("is_large_match", false))
	var is_loop := bool(result.get("is_loop", false))
	var streak := int(result.get("streak", 0))
	var pulse: Dictionary = result.get("pulse", {})
	var ep_pos: Vector2i = pulse.get("endpoint", Vector2i(-1, -1))

	var new_ids := {}
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			var cell := _board_state.get_cell(Vector2i(c, r))
			if cell.get("kind", "empty") != "empty":
				new_ids[int(cell["id"])] = cell

	for tid in _tile_nodes.keys():
		if not new_ids.has(tid):
			var node: Control = _tile_nodes[tid]
			if is_instance_valid(node):
				var pos := node.position
				var nkind := str(node.get_meta("base_organ", ""))
				if nkind == "":
					nkind = str(node.get_meta("kind", organ_kind))
				_vfx.spawn_tile_burst(pos, nkind, cell_px, is_large or is_loop)
				var tw := node.create_tween()
				tw.set_parallel(true)
				tw.tween_property(node, "scale", Vector2.ZERO, clear_dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
				tw.tween_property(node, "modulate:a", 0.0, clear_dur)
				tw.chain().tween_callback(node.queue_free)
			_tile_nodes.erase(tid)

	if BoardState.is_in_bounds(ep_pos):
		var ep_center := cell_center(ep_pos)
		var ring_col := Color(1.0, 0.92, 0.38, 0.98) if is_loop else Color(0.95, 0.95, 1.0, 0.9)
		var care_cells: Array = pulse.get("care_cells", [])
		var bloom_cells: Array = pulse.get("bloom_cells", [])
		var blocked_cells: Array = pulse.get("blocked_cells", [])
		var cracked_cells: Array = pulse.get("cracked_cells", [])
		var trig_cells: Array = pulse.get("triggered_cells", [])
		var popups: Array[Array] = []
		if trig_cells.size() > 0:
			ring_col = Color(1.0, 0.36, 0.22, 0.95)
			popups.append([LocalizationManager.tr_key("POPUP_MINUS_PULSE", {"val": 10}), Color(1.0, 0.42, 0.30), maxi(22, int(cell_px * 0.28))])
			_vfx.trigger_shake(self, 7.0)
		if blocked_cells.size() > 0:
			if trig_cells.is_empty():
				ring_col = Color(0.24, 0.94, 0.56, 0.95)
			popups.append([LocalizationManager.tr_key("POPUP_BLOCKED"), Color(0.35, 1.0, 0.65), maxi(22, int(cell_px * 0.28))])
		if cracked_cells.size() > 0:
			if trig_cells.is_empty() and blocked_cells.is_empty():
				ring_col = Color(0.98, 0.80, 0.30, 0.95)
			popups.append([LocalizationManager.tr_key("POPUP_ARMOR_CRACK"), Color(1.0, 0.88, 0.38), maxi(22, int(cell_px * 0.26))])
		if bloom_cells.size() > 0:
			if trig_cells.is_empty() and blocked_cells.is_empty() and cracked_cells.is_empty():
				ring_col = Color(1.0, 0.88, 0.28, 0.98)
			popups.append([LocalizationManager.tr_key("POPUP_PLUS_ENERGY", {"val": 20 * bloom_cells.size()}), Color(1.0, 0.92, 0.35), maxi(22, int(cell_px * 0.26))])
		if care_cells.size() > 0:
			if trig_cells.is_empty() and blocked_cells.is_empty() and cracked_cells.is_empty() and bloom_cells.is_empty():
				ring_col = Color(0.24, 0.94, 0.56, 0.95)
			popups.append([LocalizationManager.tr_key("POPUP_PLUS_SHIELD"), Color(0.40, 1.0, 0.68), maxi(22, int(cell_px * 0.26))])

		for p_idx in range(popups.size()):
			var item: Array = popups[p_idx]
			_vfx.spawn_floating_text(ep_center - Vector2(0, float(p_idx) * 34.0), str(item[0]), item[1], int(item[2]))

		_vfx.spawn_pulse_ring(ep_center, ring_col, cell_px, 2.35 if is_loop else 1.65)
		var score_y := float(cell_px) * 0.44 + float(popups.size()) * 28.0
		_vfx.spawn_floating_text(ep_center - Vector2(0, score_y), "+%d" % int(result.get("turn_score", 0)), Color(1.0, 0.96, 0.65), maxi(22, int(cell_px * 0.26)))

	# Healthy Veggie/Salad & Antioxidant Fruit bonus pops adjacent to non-endpoint chain tiles
	for hp in result.get("healthy_popped", []):
		var hpos: Vector2i = hp["pos"]
		var hkind := str(hp["kind"])
		var hpts := int(hp["score"])
		var hc := cell_center(hpos)
		_vfx.spawn_pulse_ring(hc, Color(0.28, 0.96, 0.56) if hkind == "care" else Color(1.0, 0.88, 0.26), cell_px, 1.35)
		_vfx.spawn_floating_text(hc - Vector2(0, float(cell_px) * 0.22), "+%d ★" % hpts, Color(0.45, 1.0, 0.68) if hkind == "care" else Color(1.0, 0.92, 0.35), maxi(20, int(cell_px * 0.22)))

	# Combo & Loop Celebratory Banners
	var banner_pos := board_origin + Vector2(board_pixel_size.x * 0.5, board_pixel_size.y * 0.24)
	if is_loop:
		_vfx.spawn_combo_banner(banner_pos, LocalizationManager.tr_key("BANNER_LOOP"), Color(1.0, 0.90, 0.28))
		AudioManager.play_sfx("combo_banner")
	elif streak >= 3:
		_vfx.spawn_combo_banner(banner_pos, LocalizationManager.tr_key("BANNER_FEVER"), Color(0.36, 1.0, 0.72))
		AudioManager.play_sfx("combo_banner")
	elif int(result.get("unique_len", 0)) >= 6:
		_vfx.spawn_combo_banner(banner_pos, LocalizationManager.tr_key("BANNER_SUPER"), Color(0.50, 0.94, 1.0))
		AudioManager.play_sfx("combo_banner")
	elif int(result.get("unique_len", 0)) >= 4:
		_vfx.spawn_combo_banner(banner_pos, LocalizationManager.tr_key("BANNER_SWEET"), Color(1.0, 0.80, 0.45))

	var spawns: Dictionary = {}
	for sp in result.get("refill", {}).get("spawns", []):
		spawns[int(sp["id"])] = int(sp["spawn_row"])

	var drop_tween := create_tween()
	drop_tween.set_parallel(true)

	for tid in new_ids.keys():
		var cell: Dictionary = new_ids[tid]
		var target_pos := cell_center(Vector2i(int(cell["col"]), int(cell["row"])))
		if _tile_nodes.has(tid) and is_instance_valid(_tile_nodes[tid]):
			var existing: Control = _tile_nodes[tid]
			existing.set_meta("col", int(cell["col"]))
			existing.set_meta("row", int(cell["row"]))
			_refresh_existing_tile_visual(existing, cell)
			if existing.position.distance_to(target_pos) > 1.0:
				drop_tween.tween_property(existing, "position", target_pos, drop_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(clear_dur * 0.5)
		else:
			var created := _create_tile_node(cell)
			var start_row := int(spawns.get(tid, -1))
			created.position = board_origin + Vector2((float(cell["col"]) + 0.5) * float(cell_px), (float(start_row) + 0.5) * float(cell_px))
			_tile_layer.add_child(created)
			_tile_nodes[tid] = created
			drop_tween.tween_property(created, "position", target_pos, drop_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(clear_dur * 0.5)

	drop_tween.chain().tween_callback(func():
		_is_animating = false
		if bool(result.get("reshuffled", false)):
			sync_board_immediate()
			_vfx.spawn_floating_text(board_origin + board_pixel_size * 0.5, LocalizationManager.tr_key("EVENT_RESHUFFLE"), Color(0.95, 1.0, 0.85), 24)
		if on_finished.is_valid():
			on_finished.call()
	)


func _refresh_existing_tile_visual(node: Control, cell: Dictionary) -> void:
	var restricted := int(cell.get("restricted_turns", 0)) > 0
	var sp := node.get_node_or_null("Sprite") as TextureRect
	if sp != null:
		var tkey := _resolve_tex_key(cell, false)
		node.set_meta("tex_key", tkey)
		if _textures.has(tkey):
			sp.texture = _textures[tkey]
		sp.modulate = Color(0.75, 0.72, 0.72, 0.90) if restricted else Color.WHITE
	var ov := node.get_node_or_null("LockOverlay") as TextureRect
	if restricted and ov == null and _tex_restricted != null:
		var lock_r := TextureRect.new()
		lock_r.name = "LockOverlay"
		lock_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var ov_px := float(cell_px) * 0.92
		lock_r.size = Vector2(ov_px, ov_px)
		lock_r.position = Vector2(-ov_px * 0.5, -ov_px * 0.5)
		lock_r.texture = _tex_restricted
		node.add_child(lock_r)
	elif not restricted and ov != null:
		ov.queue_free()


func start_victory_dance() -> void:
	_victory_dance = true
	_victory_dance_time = 0.0
	_hint_chain.clear()
	for tid in _tile_nodes.keys():
		var node: Control = _tile_nodes[tid]
		if not is_instance_valid(node):
			continue
		if str(node.get_meta("kind", "")) == "organ":
			var base_key := str(node.get_meta("base_organ", "heart"))
			var sp := node.get_node_or_null("Sprite") as TextureRect
			if sp != null and _textures.has(base_key + "_happy"):
				sp.texture = _textures[base_key + "_happy"]
			if DisplayServer.get_name() != "headless" and is_instance_valid(_vfx) and (int(node.get_meta("col", 0)) + int(node.get_meta("row", 0))) % 3 == 0:
				_vfx.spawn_tile_burst(node.position, base_key, cell_px, true)


func _process(delta: float) -> void:
	_anim_time += delta
	if _is_animating or _board_state == null:
		return

	if _victory_dance:
		_victory_dance_time += delta
		var base_y_v := -float(cell_px) * 0.475
		for tid in _tile_nodes.keys():
			var node: Control = _tile_nodes[tid]
			if not is_instance_valid(node):
				continue
			var sp := node.get_node_or_null("Sprite") as Control
			if sp == null:
				continue
			var c := int(node.get_meta("col", 0))
			var r := int(node.get_meta("row", 0))
			if GameManager.is_reduce_motion():
				sp.position.y = base_y_v
				sp.rotation = 0.0
				sp.scale = Vector2.ONE * 1.06
			else:
				var hop := absf(sin(_victory_dance_time * 7.0 + float(c) * 0.7)) * float(cell_px) * 0.14
				var sway := sin(_victory_dance_time * 5.5 + float(c) * 0.9 + float(r) * 0.5)
				sp.position.y = base_y_v - hop
				sp.rotation = sway * 0.18
				var sq := 1.08 + 0.08 * sin(_victory_dance_time * 11.0 + float(c + r) * 0.8)
				sp.scale = Vector2(sq, 2.16 - sq)
		return

	# Auto-Hint timer when player is idle on READY state
	if GameManager.play_state == GameManager.PlayState.READY and _active_chain.is_empty():
		_idle_hint_timer += delta
		if _idle_hint_timer >= hint_delay_sec:
			if _hint_chain.is_empty():
				_hint_chain = _board_state.find_sample_chain(3, 4)
			if not _hint_chain.is_empty() and is_instance_valid(_pulse_overlay):
				_pulse_overlay.queue_redraw()

	if GameManager.is_reduce_motion():
		return

	var amp := clampf(float(cell_px) * 0.018, 0.8, 2.2)
	var base_y := -float(cell_px) * 0.475
	for tid in _tile_nodes.keys():
		var node: Control = _tile_nodes[tid]
		if not is_instance_valid(node):
			continue
		var sp := node.get_node_or_null("Sprite") as Control
		if sp == null:
			continue
		var c := int(node.get_meta("col", 0))
		var r := int(node.get_meta("row", 0))
		var phase := _anim_time * 2.5 + float(c) * 0.55 + float(r) * 0.35
		sp.position.y = base_y + sin(phase) * amp
		sp.rotation = 0.0
		var sq := 1.0 + sin(phase * 1.2) * 0.022
		sp.scale = Vector2(sq, 2.0 - sq)


func _preview_tag_style(tag: String, is_loop: bool) -> Array:
	match tag:
		"care":
			return [Color(0.08, 0.76, 0.38, 0.98), LocalizationManager.tr_key("BADGE_PLUS_SHIELD")]
		"bloom":
			return [Color(0.90, 0.64, 0.08, 0.98), LocalizationManager.tr_key("BADGE_BLOOM")]
		"overload_blocked":
			return [Color(0.08, 0.74, 0.52, 0.98), LocalizationManager.tr_key("BADGE_BLOCK")]
		"overload_cracked":
			return [Color(0.88, 0.56, 0.10, 0.98), LocalizationManager.tr_key("BADGE_CRACK")]
		"overload_danger":
			return [Color(0.92, 0.22, 0.14, 0.98), "-10"]
		_:
			var col := Color(0.96, 0.78, 0.20, 0.72) if is_loop else Color(0.24, 0.68, 0.76, 0.60)
			return [col, ""]


func _draw() -> void:
	if board_pixel_size.x <= 0.0:
		return

	var tray_rect := Rect2(board_origin - Vector2(12, 12), board_pixel_size + Vector2(24, 24))
	draw_rect(tray_rect, Color(0.08, 0.25, 0.24, 0.24), true)
	var board_rect := get_board_rect()
	draw_rect(board_rect.grow(6.0), Color(0.96, 0.99, 0.96, 0.90), true)
	draw_rect(board_rect.grow(6.0), Color(0.12, 0.48, 0.42, 0.62), false, 3.0)

	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			var cr := Rect2(cell_top_left(Vector2i(c, r)), Vector2(float(cell_px), float(cell_px)))
			var is_even := ((c + r) % 2) == 0
			var col := Color(0.88, 0.95, 0.92, 0.78) if is_even else Color(0.95, 0.99, 0.97, 0.78)
			draw_rect(cr.grow(-2.0), col, true)

	if not _active_chain.is_empty() and _board_state != null:
		var head_cell := _board_state.get_cell(_active_chain[0])
		var organ_name := str(head_cell.get("organ", "heart"))
		var is_loop := ChainValidator.is_loop(_active_chain)
		var line_col: Color = Color(1.0, 0.84, 0.20, 0.96) if is_loop else ORGAN_COLORS.get(organ_name, Color(0.2, 0.8, 0.7, 0.9))

		for p in _active_chain:
			var cr := Rect2(cell_top_left(p), Vector2(float(cell_px), float(cell_px))).grow(-3.0)
			var fill_c := line_col
			fill_c.a = 0.26
			draw_rect(cr, fill_c, true)
			draw_rect(cr, line_col, false, 3.5)

		if _active_chain.size() >= 2:
			var pts := PackedVector2Array()
			for p in _active_chain:
				pts.append(cell_center(p))
			draw_polyline(pts, Color(1, 1, 1, 0.82), maxf(9.0, float(cell_px) * 0.17), true)
			draw_polyline(pts, line_col, maxf(6.0, float(cell_px) * 0.11), true)

	# Draw Endpoint Pulse rays & cell outlines underneath tile sprites so faces stay uncrossed
	if _board_state != null and _active_chain.size() >= 3 and bool(_endpoint_preview.get("valid", false)):
		var is_ep_loop := bool(_endpoint_preview.get("is_loop", false))
		var ep: Vector2i = _endpoint_preview.get("endpoint", _active_chain[_active_chain.size() - 1])
		var ep_center := cell_center(ep)
		for nb_info in _endpoint_preview.get("neighbors", []):
			var np: Vector2i = nb_info["pos"]
			var tag := str(nb_info["tag"])
			var st := _preview_tag_style(tag, is_ep_loop)
			var border_col: Color = st[0]
			var nr := Rect2(cell_top_left(np), Vector2(float(cell_px), float(cell_px))).grow(-3.0)
			draw_line(ep_center, cell_center(np), Color(border_col.r, border_col.g, border_col.b, 0.72), 4.0)
			draw_rect(nr, border_col, false, 5.0 if tag != "neutral" else 2.5)


func _draw_pulse_overlay() -> void:
	# 1. Idle Hint Shimmer & Guiding Pointer Dot
	if _active_chain.is_empty() and _hint_chain.size() >= 3 and _board_state != null:
		var pts := PackedVector2Array()
		for i in range(mini(3, _hint_chain.size())):
			var hp: Vector2i = _hint_chain[i]
			pts.append(cell_center(hp))
			var hr := Rect2(cell_top_left(hp), Vector2(float(cell_px), float(cell_px))).grow(-4.0)
			var pulse_a := 0.45 + 0.35 * sin(_anim_time * 4.5)
			_pulse_overlay.draw_rect(hr, Color(0.98, 0.78, 0.16, pulse_a), false, 4.0)
		_pulse_overlay.draw_polyline(pts, Color(1.0, 0.88, 0.32, 0.72), 6.0, true)
		var prog_t := fmod(_anim_time * 0.9, 1.0)
		var seg_f := prog_t * float(pts.size() - 1)
		var s_idx := clampi(int(floor(seg_f)), 0, pts.size() - 2)
		var local_t := seg_f - float(s_idx)
		var guide_pos := pts[s_idx].lerp(pts[s_idx + 1], local_t)
		_pulse_overlay.draw_circle(guide_pos, float(cell_px) * 0.16, Color(1.0, 1.0, 1.0, 0.92))
		_pulse_overlay.draw_circle(guide_pos, float(cell_px) * 0.11, Color(0.10, 0.72, 0.48, 0.95))

	# 2. Endpoint Pulse Halo & Crisp Pill Badges above tiles
	if _board_state == null or _active_chain.size() < 3 or not bool(_endpoint_preview.get("valid", false)):
		return
	var is_loop := bool(_endpoint_preview.get("is_loop", false))
	var ep: Vector2i = _endpoint_preview.get("endpoint", _active_chain[_active_chain.size() - 1])
	var ep_center := cell_center(ep)
	var ep_col := Color(1.0, 0.86, 0.22, 0.96) if is_loop else Color(1.0, 1.0, 1.0, 0.88)
	_pulse_overlay.draw_arc(ep_center, float(cell_px) * 0.46, 0.0, TAU, 36, ep_col, 4.5, true)

	for nb_info in _endpoint_preview.get("neighbors", []):
		var np: Vector2i = nb_info["pos"]
		var tag := str(nb_info["tag"])
		var st := _preview_tag_style(tag, is_loop)
		var border_col: Color = st[0]
		var badge_text: String = str(st[1])
		var nr := Rect2(cell_top_left(np), Vector2(float(cell_px), float(cell_px))).grow(-3.0)

		if badge_text != "" and _font_bold != null:
			var fsize := clampi(int(float(cell_px) * 0.19), 11, 21)
			var pill_h := float(fsize) + 10.0
			var pill := Rect2(nr.position.x + 5.0, nr.position.y - pill_h * 0.35, nr.size.x - 10.0, pill_h)
			_pulse_overlay.draw_rect(pill.grow(2.0), Color(1, 1, 1, 0.92), true)
			_pulse_overlay.draw_rect(pill, border_col, true)
			_pulse_overlay.draw_string(_font_bold, Vector2(pill.position.x + 3.0, pill.position.y + float(fsize) + 2.0), badge_text, HORIZONTAL_ALIGNMENT_CENTER, pill.size.x - 6.0, fsize, Color.WHITE)
