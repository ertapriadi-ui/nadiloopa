class_name BoardState
extends RefCounted
## Pure logical adaptive grid state (5x7 Easy, 6x9 Medium, 7x12 Hard), decoupled from rendering and input.

static var COLS: int = 7
static var ROWS: int = 12
static var TOTAL_CELLS: int = 84
static var current_difficulty: String = "hard"
const ORGANS: Array[String] = ["heart", "brain", "lungs", "kidneys", "stomach", "liver", "muscle"]
const HAZARD_TYPES: Array[String] = ["fast_food", "sugary_drink", "cigarette_smoke"]
const DIRS: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0)
]
const DIRS_8: Array[Vector2i] = [
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(1, 0),
	Vector2i(1, 1),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(-1, -1)
]

var cells: Array[Dictionary] = []
var _next_tile_id: int = 1


func _init() -> void:
	cells.resize(TOTAL_CELLS)
	for r in range(ROWS):
		for c in range(COLS):
			cells[idx(c, r)] = _make_empty_cell(c, r)


static func set_difficulty_grid(diff: String) -> void:
	match diff:
		"easy":
			current_difficulty = "easy"
			COLS = 5
			ROWS = 7
			TOTAL_CELLS = 35
		"medium":
			current_difficulty = "medium"
			COLS = 6
			ROWS = 9
			TOTAL_CELLS = 54
		_:
			current_difficulty = "hard"
			COLS = 7
			ROWS = 12
			TOTAL_CELLS = 84


static func idx(col: int, row: int) -> int:
	return row * COLS + col


static func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < COLS and pos.y >= 0 and pos.y < ROWS


static func get_orthogonal_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in DIRS:
		var np := pos + d
		if is_in_bounds(np):
			out.append(np)
	return out


static func get_8way_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in DIRS_8:
		var np := pos + d
		if is_in_bounds(np):
			out.append(np)
	return out


func _make_empty_cell(col: int, row: int) -> Dictionary:
	return {
		"id": 0,
		"col": col,
		"row": row,
		"kind": "empty",
		"organ": "",
		"hazard_type": "",
		"hp": 1,
		"restricted_turns": 0,
		"newly_restricted": false
	}


func make_organ_cell(col: int, row: int, organ_type: String) -> Dictionary:
	var tid := _next_tile_id
	_next_tile_id += 1
	return {
		"id": tid,
		"col": col,
		"row": row,
		"kind": "organ",
		"organ": organ_type,
		"hazard_type": "",
		"hp": 1,
		"restricted_turns": 0,
		"newly_restricted": false
	}


func set_organ(pos: Vector2i, organ_type: String, restricted_turns: int = 0) -> void:
	if not is_in_bounds(pos):
		return
	var cell := make_organ_cell(pos.x, pos.y, organ_type)
	cell["restricted_turns"] = restricted_turns
	cells[idx(pos.x, pos.y)] = cell


func set_special(pos: Vector2i, special_kind: String, hp: int = 1, hazard_type: String = "") -> void:
	if not is_in_bounds(pos):
		return
	var tid := _next_tile_id
	_next_tile_id += 1
	var htype := hazard_type
	if special_kind == "overload" and htype == "":
		htype = HAZARD_TYPES[tid % HAZARD_TYPES.size()]
	cells[idx(pos.x, pos.y)] = {
		"id": tid,
		"col": pos.x,
		"row": pos.y,
		"kind": special_kind,
		"organ": "",
		"hazard_type": htype,
		"hp": hp,
		"restricted_turns": 0,
		"newly_restricted": false
	}


func set_overload(pos: Vector2i, hp: int = 1, hazard_type: String = "") -> void:
	set_special(pos, "overload", hp, hazard_type)


func find_first_valid_chain(min_len: int = 3) -> Array[Vector2i]:
	return find_sample_chain(min_len, 4)


func clear_cell(pos: Vector2i) -> void:
	if not is_in_bounds(pos):
		return
	cells[idx(pos.x, pos.y)] = _make_empty_cell(pos.x, pos.y)


func get_cell(pos: Vector2i) -> Dictionary:
	if not is_in_bounds(pos):
		return {}
	return cells[idx(pos.x, pos.y)]


func clone() -> BoardState:
	var copy := BoardState.new()
	copy._next_tile_id = _next_tile_id
	for i in range(TOTAL_CELLS):
		copy.cells[i] = cells[i].duplicate(true)
	return copy


func count_kind(kind_name: String) -> int:
	var n := 0
	for c in cells:
		if c.get("kind", "") == kind_name:
			n += 1
	return n


func get_active_organs(weights: Dictionary) -> Array[String]:
	var active: Array[String] = []
	for o in ORGANS:
		if int(weights.get(o, 0)) > 0:
			active.append(o)
	if active.is_empty():
		return ["heart", "brain", "lungs", "kidneys"]
	return active


func pick_weighted_organ(rng: RandomNumberGenerator, weights: Dictionary) -> String:
	var active := get_active_organs(weights)
	var total := 0
	for o in active:
		total += maxi(1, int(weights.get(o, 25)))
	var roll := rng.randi_range(0, total - 1)
	var acc := 0
	for o in active:
		acc += maxi(1, int(weights.get(o, 25)))
		if roll < acc:
			return o
	return active[0]


func _remap_pos_for_grid(raw_pos: Array) -> Vector2i:
	var c := int(raw_pos[0])
	var r := int(raw_pos[1])
	if COLS != 7 or ROWS != 12:
		c = clampi(int(round(float(c) * float(COLS - 1) / 6.0)), 0, COLS - 1)
		r = clampi(int(round(float(r) * float(ROWS - 1) / 11.0)), 1, maxi(1, ROWS - 2))
		var probe := Vector2i(c, r)
		if get_cell(probe).get("kind", "") != "organ":
			var offs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1)]
			for off in offs:
				var alt: Vector2i = probe + off
				if is_in_bounds(alt) and get_cell(alt).get("kind", "") == "organ":
					return alt
	return Vector2i(clampi(c, 0, COLS - 1), clampi(r, 0, ROWS - 1))


func populate_initial(rng: RandomNumberGenerator, weights: Dictionary, care_positions: Array, overload_positions: Array, armored_positions: Array = [], bloom_positions: Array = []) -> void:
	for r in range(ROWS):
		for c in range(COLS):
			set_organ(Vector2i(c, r), pick_weighted_organ(rng, weights))

	for raw_pos in overload_positions:
		if typeof(raw_pos) == TYPE_ARRAY and raw_pos.size() >= 2:
			set_special(_remap_pos_for_grid(raw_pos), "overload", 1)

	for raw_pos in armored_positions:
		if typeof(raw_pos) == TYPE_ARRAY and raw_pos.size() >= 2:
			set_special(_remap_pos_for_grid(raw_pos), "overload", 2)

	for raw_pos in care_positions:
		if typeof(raw_pos) == TYPE_ARRAY and raw_pos.size() >= 2:
			set_special(_remap_pos_for_grid(raw_pos), "care", 1)

	for raw_pos in bloom_positions:
		if typeof(raw_pos) == TYPE_ARRAY and raw_pos.size() >= 2:
			set_special(_remap_pos_for_grid(raw_pos), "bloom", 1)

	ensure_playable_board(rng, 3, weights)


func find_connected_group(start: Vector2i) -> Array[Vector2i]:
	var start_cell := get_cell(start)
	if start_cell.get("kind", "") != "organ" or int(start_cell.get("restricted_turns", 0)) > 0:
		return []
	var target_organ: String = str(start_cell.get("organ", ""))
	var visited := {}
	var queue: Array[Vector2i] = [start]
	var group: Array[Vector2i] = []
	visited[start] = true

	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		group.append(cur)
		for nb in get_orthogonal_neighbors(cur):
			if visited.has(nb):
				continue
			var ncell := get_cell(nb)
			if ncell.get("kind", "") == "organ" and str(ncell.get("organ", "")) == target_organ and int(ncell.get("restricted_turns", 0)) <= 0:
				visited[nb] = true
				queue.append(nb)
	return group


func has_any_valid_chain(min_len: int = 3) -> bool:
	var checked := {}
	for r in range(ROWS):
		for c in range(COLS):
			var p := Vector2i(c, r)
			if checked.has(p):
				continue
			var cell := get_cell(p)
			if cell.get("kind", "") != "organ" or int(cell.get("restricted_turns", 0)) > 0:
				continue
			var grp := find_connected_group(p)
			for gp in grp:
				checked[gp] = true
			if grp.size() >= min_len:
				return true
	return false


func find_sample_chain(min_len: int = 3, max_len: int = 8) -> Array[Vector2i]:
	var checked := {}
	var fallback: Array[Vector2i] = []
	for r in range(ROWS):
		for c in range(COLS):
			var p := Vector2i(c, r)
			if checked.has(p):
				continue
			var cell := get_cell(p)
			if cell.get("kind", "") != "organ" or int(cell.get("restricted_turns", 0)) > 0:
				continue
			var grp := find_connected_group(p)
			for gp in grp:
				checked[gp] = true
			if grp.size() >= min_len:
				var walk := _dfs_walk_from(p, str(cell.get("organ", "")), max_len)
				if walk.size() >= min_len:
					# Prefer hint paths whose endpoint is not touching an overload hazard
					var has_haz := false
					for nb in get_orthogonal_neighbors(walk[walk.size() - 1]):
						if get_cell(nb).get("kind", "") == "overload":
							has_haz = true
							break
					if not has_haz:
						return walk
					if fallback.is_empty():
						fallback = walk
	return fallback


func _dfs_walk_from(start: Vector2i, target_organ: String, max_len: int) -> Array[Vector2i]:
	var path: Array[Vector2i] = [start]
	var used := {start: true}
	var cur := start
	while path.size() < max_len:
		var added := false
		for nb in get_orthogonal_neighbors(cur):
			if used.has(nb):
				continue
			var nc := get_cell(nb)
			if nc.get("kind", "") == "organ" and str(nc.get("organ", "")) == target_organ and int(nc.get("restricted_turns", 0)) <= 0:
				path.append(nb)
				used[nb] = true
				cur = nb
				added = true
				break
		if not added:
			break
	return path


func apply_gravity_and_refill(rng: RandomNumberGenerator, weights: Dictionary, min_care_on_board: int = 0, min_overload_on_board: int = 0) -> Dictionary:
	var moves: Array[Dictionary] = []
	var spawns: Array[Dictionary] = []

	for c in range(COLS):
		var write_row := ROWS - 1
		for r in range(ROWS - 1, -1, -1):
			var cur_pos := Vector2i(c, r)
			var cell := get_cell(cur_pos)
			if cell.get("kind", "empty") != "empty":
				if write_row != r:
					var moved := cell.duplicate(true)
					moved["col"] = c
					moved["row"] = write_row
					cells[idx(c, write_row)] = moved
					cells[idx(c, r)] = _make_empty_cell(c, r)
					moves.append({"id": moved["id"], "from": Vector2i(c, r), "to": Vector2i(c, write_row)})
				write_row -= 1

		var spawn_offset := 1
		for r in range(write_row, -1, -1):
			var organ_type := pick_weighted_organ(rng, weights)
			var new_cell := make_organ_cell(c, r, organ_type)
			cells[idx(c, r)] = new_cell
			spawns.append({"id": new_cell["id"], "col": c, "row": r, "spawn_row": -spawn_offset})
			spawn_offset += 1

	var current_care := count_kind("care")
	if min_care_on_board > 0 and current_care < min_care_on_board:
		var needed := min_care_on_board - current_care
		var candidates: Array[Vector2i] = []
		for r in range(0, mini(6, ROWS)):
			for c in range(COLS):
				var cell := get_cell(Vector2i(c, r))
				if cell.get("kind", "") == "organ" and int(cell.get("restricted_turns", 0)) == 0:
					candidates.append(Vector2i(c, r))
		while needed > 0 and not candidates.is_empty():
			var pick_i := rng.randi_range(0, candidates.size() - 1)
			var pos: Vector2i = candidates[pick_i]
			candidates.remove_at(pick_i)
			set_special(pos, "care", 1)
			needed -= 1

	var current_ov := count_kind("overload")
	if min_overload_on_board > 0 and current_ov < min_overload_on_board:
		var needed_ov := min_overload_on_board - current_ov
		var ov_candidates: Array[Vector2i] = []
		for r in range(0, mini(5, ROWS)):
			for c in range(COLS):
				var cell := get_cell(Vector2i(c, r))
				if cell.get("kind", "") == "organ" and int(cell.get("restricted_turns", 0)) == 0:
					ov_candidates.append(Vector2i(c, r))
		while needed_ov > 0 and not ov_candidates.is_empty():
			var pick_i := rng.randi_range(0, ov_candidates.size() - 1)
			var pos: Vector2i = ov_candidates[pick_i]
			ov_candidates.remove_at(pick_i)
			set_special(pos, "overload", 1)
			needed_ov -= 1

	return {"moves": moves, "spawns": spawns}


func ensure_playable_board(rng: RandomNumberGenerator, min_len: int = 3, weights: Dictionary = {}) -> bool:
	if has_any_valid_chain(min_len):
		return false

	var active := get_active_organs(weights)
	var organ_slots: Array[Vector2i] = []
	var organ_values: Array[String] = []
	for r in range(ROWS):
		for c in range(COLS):
			var cell := get_cell(Vector2i(c, r))
			if cell.get("kind", "") == "organ" and int(cell.get("restricted_turns", 0)) <= 0:
				organ_slots.append(Vector2i(c, r))
				organ_values.append(str(cell.get("organ", active[0])))

	for attempt in range(8):
		for i in range(organ_values.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp := organ_values[i]
			organ_values[i] = organ_values[j]
			organ_values[j] = tmp
		for k in range(organ_slots.size()):
			set_organ(organ_slots[k], organ_values[k], 0)
		if has_any_valid_chain(min_len):
			return true

	for r in range(ROWS):
		for c in range(COLS - 2):
			var p0 := Vector2i(c, r)
			var p1 := Vector2i(c + 1, r)
			var p2 := Vector2i(c + 2, r)
			if _is_open_organ(p0) and _is_open_organ(p1) and _is_open_organ(p2):
				var chosen := active[rng.randi_range(0, active.size() - 1)]
				set_organ(p0, chosen, 0)
				set_organ(p1, chosen, 0)
				set_organ(p2, chosen, 0)
				return true
	return true


func _is_open_organ(pos: Vector2i) -> bool:
	var c := get_cell(pos)
	return c.get("kind", "") == "organ" and int(c.get("restricted_turns", 0)) <= 0
