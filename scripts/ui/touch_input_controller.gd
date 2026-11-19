class_name TouchInputController
extends Control
## Translates touch/mouse drag input on the 7x12 board into orthogonal chains & Nadi Loops.

signal chain_updated(chain: Array[Vector2i])
signal chain_committed(chain: Array[Vector2i])
signal chain_cancelled(reason: String)

var board_renderer: BoardRenderer
var board_state: BoardState
var input_enabled: bool = false

var _is_dragging: bool = false
var _active_touch_idx: int = -1
var _chain: Array[Vector2i] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func bind(renderer: BoardRenderer) -> void:
	board_renderer = renderer


func set_board_state(state: BoardState) -> void:
	board_state = state
	cancel_drag(false)


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled and _is_dragging:
		cancel_drag(false)


func cancel_drag(emit_cancel: bool = false) -> void:
	_is_dragging = false
	_active_touch_idx = -1
	_chain.clear()
	if emit_cancel:
		chain_cancelled.emit("cancelled")
	var empty_chain: Array[Vector2i] = []
	chain_updated.emit(empty_chain)


func _gui_input(event: InputEvent) -> void:
	if not input_enabled or board_renderer == null or board_state == null:
		return

	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and _active_touch_idx == -1:
			_active_touch_idx = st.index
			_begin_drag(st.position)
			accept_event()
		elif not st.pressed and st.index == _active_touch_idx:
			_end_drag()
			accept_event()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _is_dragging and sd.index == _active_touch_idx:
			_update_drag(sd.position)
			accept_event()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and _active_touch_idx == -1:
				_active_touch_idx = -99
				_begin_drag(mb.position)
				accept_event()
			elif not mb.pressed and _active_touch_idx == -99:
				_end_drag()
				accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _is_dragging and _active_touch_idx == -99:
			_update_drag(mm.position)
			accept_event()


func _begin_drag(local_pos: Vector2) -> void:
	board_renderer.reset_idle_hint()
	var cell_pos := board_renderer.local_to_cell(local_pos, true)
	if not BoardState.is_in_bounds(cell_pos):
		_active_touch_idx = -1
		return
	if not ChainValidator.can_start_at(board_state, cell_pos):
		_active_touch_idx = -1
		AudioManager.play_sfx("invalid_path", 1.0, -3.0)
		return
	_is_dragging = true
	_chain = [cell_pos]
	AudioManager.play_chain_step_sfx(1)
	chain_updated.emit(_chain.duplicate())


func _update_drag(local_pos: Vector2) -> void:
	board_renderer.reset_idle_hint()
	var cell_pos := board_renderer.local_to_cell(local_pos, false)
	if not BoardState.is_in_bounds(cell_pos):
		return
	if not _chain.is_empty():
		var last := _chain[_chain.size() - 1]
		if cell_pos != last:
			var center := board_renderer.cell_center(cell_pos)
			var half_cell := float(board_renderer.cell_px) * 0.48
			if absf(local_pos.x - center.x) > half_cell or absf(local_pos.y - center.y) > half_cell:
				return

	var res := ChainValidator.try_step(board_state, _chain, cell_pos)
	if res == "added":
		AudioManager.play_chain_step_sfx(_chain.size())
		chain_updated.emit(_chain.duplicate())
	elif res == "loop":
		AudioManager.play_sfx("loop_form")
		chain_updated.emit(_chain.duplicate())
	elif res == "backtrack":
		AudioManager.play_chain_step_sfx(maxi(1, _chain.size()))
		chain_updated.emit(_chain.duplicate())


func _end_drag() -> void:
	if not _is_dragging:
		_active_touch_idx = -1
		return
	_is_dragging = false
	_active_touch_idx = -1
	var committed := _chain.duplicate()
	_chain.clear()
	if ChainValidator.is_valid_commit(board_state, committed):
		AudioManager.play_sfx("valid_release")
		chain_committed.emit(committed)
	else:
		if committed.size() > 1:
			AudioManager.play_sfx("invalid_path", 1.0, -2.0)
		chain_cancelled.emit("too_short")
		var empty_chain: Array[Vector2i] = []
		chain_updated.emit(empty_chain)
