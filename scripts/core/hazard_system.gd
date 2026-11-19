class_name HazardSystem
extends RefCounted
## Handles Overload hazard penalties, 1-move organ cell restrictions, restriction expiry,
## and Catastrophic Toxic 3-Combo Fat & Calorie Explosions.


static func find_eligible_restrict_targets(board: BoardState, hazard_pos: Vector2i, cleared_set: Dictionary, max_cells: int) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	for nb in BoardState.get_orthogonal_neighbors(hazard_pos):
		if cleared_set.has(nb):
			continue
		var c := board.get_cell(nb)
		if c.get("kind", "") == "organ" and int(c.get("restricted_turns", 0)) <= 0:
			targets.append(nb)
			if targets.size() >= max_cells:
				break
	return targets


static func apply_overload_hit(board: BoardState, hazard_pos: Vector2i, cleared_set: Dictionary, pulse_meter: int, penalty: int, max_restrict: int, restrict_turns: int) -> Dictionary:
	var new_pulse := maxi(0, pulse_meter - penalty)
	var restricted: Array[Vector2i] = find_eligible_restrict_targets(board, hazard_pos, cleared_set, max_restrict)
	for pos in restricted:
		var idx := BoardState.idx(pos.x, pos.y)
		board.cells[idx]["restricted_turns"] = restrict_turns
		board.cells[idx]["newly_restricted"] = true
	return {
		"pulse_meter": new_pulse,
		"pulse_delta": new_pulse - pulse_meter,
		"restricted_cells": restricted
	}


static func tick_restrictions(board: BoardState) -> void:
	for i in range(BoardState.TOTAL_CELLS):
		var c := board.cells[i]
		if bool(c.get("newly_restricted", false)):
			c["newly_restricted"] = false
		elif int(c.get("restricted_turns", 0)) > 0:
			c["restricted_turns"] = maxi(0, int(c.get("restricted_turns")) - 1)


static func find_toxic_warning_pairs(board: BoardState) -> Array[Array]:
	var pairs: Array[Array] = []
	if board == null:
		return pairs
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			var p := Vector2i(c, r)
			var cell := board.get_cell(p)
			if str(cell.get("kind", "")) != "overload":
				continue
			var p_idx := BoardState.idx(c, r)
			for nb in BoardState.get_8way_neighbors(p):
				var nb_idx := BoardState.idx(nb.x, nb.y)
				if nb_idx <= p_idx:
					continue
				var ncell := board.get_cell(nb)
				if str(ncell.get("kind", "")) == "overload":
					pairs.append([p, nb])
	return pairs


static func check_catastrophic_toxic_combo(board: BoardState, progress: Dictionary) -> Dictionary:
	## Detects 8-way adjacent Overload clusters containing all 3 toxic hazards
	## (fast_food + sugary_drink + cigarette_smoke) OR 4+ clustered hazards.
	## Triggers a Catastrophic Fat & Calorie Explosion (5x5 blast radius) that
	## drastically slashes Score (-30%, min 400 pts), damages Pulse, and injures nearby organs.
	var empty_res := {
		"triggered": false,
		"is_triple_toxic": false,
		"center": Vector2i(-1, -1),
		"cluster": [],
		"blast_cells": [],
		"injured_organs": [],
		"score_lost": 0,
		"raw_score_penalty": 0,
		"pulse_lost": 0,
		"shield_mitigated": false
	}
	if board == null:
		return empty_res

	var visited := {}
	var trigger_cluster: Array[Vector2i] = []
	var is_triple := false

	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			var start := Vector2i(c, r)
			if visited.has(start):
				continue
			var scell := board.get_cell(start)
			if str(scell.get("kind", "")) != "overload":
				continue
			var queue: Array[Vector2i] = [start]
			var cluster: Array[Vector2i] = []
			var types_seen := {}
			visited[start] = true
			while not queue.is_empty():
				var cur: Vector2i = queue.pop_front()
				cluster.append(cur)
				var ccell := board.get_cell(cur)
				var htype := str(ccell.get("hazard_type", "fast_food"))
				if htype == "":
					htype = "fast_food"
				types_seen[htype] = true
				for nb in BoardState.get_8way_neighbors(cur):
					if visited.has(nb):
						continue
					var ncell := board.get_cell(nb)
					if str(ncell.get("kind", "")) == "overload":
						visited[nb] = true
						queue.append(nb)
			if cluster.size() >= 3 and (types_seen.size() >= 3 or cluster.size() >= 4):
				trigger_cluster = cluster
				is_triple = types_seen.size() >= 3
				break
		if not trigger_cluster.is_empty():
			break

	if trigger_cluster.is_empty():
		return empty_res

	var sum_x := 0
	var sum_y := 0
	for p in trigger_cluster:
		sum_x += p.x
		sum_y += p.y
		board.clear_cell(p)
	var center := Vector2i(
		clampi(int(round(float(sum_x) / float(trigger_cluster.size()))), 0, BoardState.COLS - 1),
		clampi(int(round(float(sum_y) / float(trigger_cluster.size()))), 0, BoardState.ROWS - 1)
	)

	var blast_cells: Array[Vector2i] = []
	var injured_organs: Array[Vector2i] = []
	for dr in range(-2, 3):
		for dc in range(-2, 3):
			var bp := Vector2i(center.x + dc, center.y + dr)
			if not BoardState.is_in_bounds(bp):
				continue
			blast_cells.append(bp)
			var bcell := board.get_cell(bp)
			if str(bcell.get("kind", "")) == "organ" and injured_organs.size() < 5:
				var bidx := BoardState.idx(bp.x, bp.y)
				board.cells[bidx]["restricted_turns"] = maxi(2, int(board.cells[bidx].get("restricted_turns", 0)))
				board.cells[bidx]["newly_restricted"] = true
				injured_organs.append(bp)

	var cur_score := int(progress.get("score", 0))
	var raw_score_penalty := maxi(400, int(round(float(cur_score) * 0.30)))
	var score_lost := mini(cur_score, raw_score_penalty)
	progress["score"] = maxi(0, cur_score - score_lost)

	var shields := int(progress.get("shield_charges", 0))
	var shield_mitigated := false
	var pulse_loss := 18
	if shields > 0:
		progress["shield_charges"] = shields - 1
		pulse_loss = 8
		shield_mitigated = true
	var cur_pulse := int(progress.get("pulse_meter", 100))
	var new_pulse := maxi(0, cur_pulse - pulse_loss)
	progress["pulse_meter"] = new_pulse
	progress["catastrophic_blasts"] = int(progress.get("catastrophic_blasts", 0)) + 1

	return {
		"triggered": true,
		"is_triple_toxic": is_triple,
		"center": center,
		"cluster": trigger_cluster,
		"blast_cells": blast_cells,
		"injured_organs": injured_organs,
		"score_lost": score_lost,
		"raw_score_penalty": raw_score_penalty,
		"pulse_lost": cur_pulse - new_pulse,
		"shield_mitigated": shield_mitigated
	}
