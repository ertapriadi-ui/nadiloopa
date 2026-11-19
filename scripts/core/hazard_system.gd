class_name HazardSystem
extends RefCounted
## Handles Overload hazard penalties, 1-move organ cell restrictions, and restriction expiry.


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
			c["restricted_turns"] = maxi(0, int(c["restricted_turns"]) - 1)
