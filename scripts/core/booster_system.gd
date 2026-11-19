class_name BoosterSystem
extends RefCounted
## Handles Care Shield activation plus 3 earned Tactical Care Abilities (Care Energy powered, zero IAP).

const COST_FRUIT_SPARK: int = 30
const COST_CLEAR_FLOW: int = 25
const COST_REST_SHIELD: int = 40
const COST_DETOX_BOMB: int = 35


static func activate_care(shield_charges: int, pulse_meter: int, care_pulse_restore: int, max_pulse: int, shield_max: int) -> Dictionary:
	var new_shields := mini(shield_max, shield_charges + 1)
	var new_pulse := mini(max_pulse, pulse_meter + care_pulse_restore)
	return {
		"shield_charges": new_shields,
		"pulse_meter": new_pulse,
		"shield_gained": new_shields - shield_charges,
		"pulse_restored": new_pulse - pulse_meter
	}


static func _pick_target_organ(board: BoardState, level_def: Dictionary, progress: Dictionary) -> String:
	var objs: Dictionary = level_def.get("objectives", {})
	var col_req: Dictionary = objs.get("collect", {})
	var col_prog: Dictionary = progress.get("collected", {})
	var best_organ := ""
	var max_rem := 0
	for o in col_req.keys():
		var rem := int(col_req[o]) - int(col_prog.get(o, 0))
		if rem > max_rem:
			max_rem = rem
			best_organ = str(o)
	if best_organ != "":
		return best_organ
	var active := board.get_active_organs(level_def.get("weights", {}))
	return active[0]


static func cast_fruit_spark(board: BoardState, level_def: Dictionary, progress: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var energy := int(progress.get("care_energy", 0))
	if energy < COST_FRUIT_SPARK:
		return {"used": false, "reason": "insufficient_energy"}
	var target_organ := _pick_target_organ(board, level_def, progress)
	var candidates: Array[Vector2i] = []
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			var p := Vector2i(c, r)
			var cell := board.get_cell(p)
			if cell.get("kind", "") == "organ" and int(cell.get("restricted_turns", 0)) == 0 and str(cell.get("organ", "")) != target_organ:
				candidates.append(p)
	if candidates.is_empty():
		return {"used": false, "reason": "no_targets"}
	var converted: Array[Vector2i] = []
	for _i in range(mini(4, candidates.size())):
		var idx := rng.randi_range(0, candidates.size() - 1)
		var pos: Vector2i = candidates[idx]
		candidates.remove_at(idx)
		board.set_organ(pos, target_organ, 0)
		converted.append(pos)
	progress["care_energy"] = energy - COST_FRUIT_SPARK
	board.ensure_playable_board(rng, 3, level_def.get("weights", {}))
	return {"used": true, "ability": "spark", "organ": target_organ, "cells": converted}


static func cast_clear_flow(board: BoardState, progress: Dictionary, max_pulse: int = 100) -> Dictionary:
	var energy := int(progress.get("care_energy", 0))
	if energy < COST_CLEAR_FLOW:
		return {"used": false, "reason": "insufficient_energy"}
	var pulse_low := int(progress.get("pulse_meter", 100)) < max_pulse
	var has_work := pulse_low
	if not has_work:
		for i in range(BoardState.TOTAL_CELLS):
			var cc := board.cells[i]
			if int(cc.get("restricted_turns", 0)) > 0 or (cc.get("kind", "") == "overload" and int(cc.get("hp", 1)) > 1):
				has_work = true
				break
	if not has_work:
		return {"used": false, "reason": "no_effect"}
	var cleared: Array[Vector2i] = []
	var weakened := Vector2i(-1, -1)
	for i in range(BoardState.TOTAL_CELLS):
		var c := board.cells[i]
		if int(c.get("restricted_turns", 0)) > 0:
			c["restricted_turns"] = 0
			c["newly_restricted"] = false
			cleared.append(Vector2i(int(c["col"]), int(c["row"])))
		elif weakened.x == -1 and c.get("kind", "") == "overload" and int(c.get("hp", 1)) > 1:
			c["hp"] = 1
			weakened = Vector2i(int(c["col"]), int(c["row"]))
	progress["care_energy"] = energy - COST_CLEAR_FLOW
	progress["pulse_meter"] = mini(max_pulse, int(progress.get("pulse_meter", 100)) + 12)
	return {"used": true, "ability": "flow", "cleared": cleared, "weakened": weakened}


static func cast_rest_shield(board: BoardState, progress: Dictionary, rng: RandomNumberGenerator, shield_max: int = 2) -> Dictionary:
	var energy := int(progress.get("care_energy", 0))
	if energy < COST_REST_SHIELD:
		return {"used": false, "reason": "insufficient_energy"}
	if int(progress.get("shield_charges", 0)) >= shield_max:
		return {"used": false, "reason": "max_shields"}
	progress["care_energy"] = energy - COST_REST_SHIELD
	progress["shield_charges"] = mini(shield_max, int(progress.get("shield_charges", 0)) + 1)

	var candidates: Array[Vector2i] = []
	for r in range(1, maxi(2, BoardState.ROWS - 1)):
		for c in range(0, BoardState.COLS):
			var p := Vector2i(c, r)
			var cell := board.get_cell(p)
			if cell.get("kind", "") == "organ" and int(cell.get("restricted_turns", 0)) == 0:
				candidates.append(p)
	var placed := Vector2i(-1, -1)
	if not candidates.is_empty():
		placed = candidates[rng.randi_range(0, candidates.size() - 1)]
		board.set_special(placed, "care", 1)
	return {"used": true, "ability": "rest", "care_pos": placed}


static func cast_detox_bomb(board: BoardState, level_def: Dictionary, progress: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var energy := int(progress.get("care_energy", 0))
	if energy < COST_DETOX_BOMB:
		return {"used": false, "reason": "insufficient_energy"}

	var overloads: Array[Vector2i] = []
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			var p := Vector2i(c, r)
			if str(board.get_cell(p).get("kind", "")) == "overload":
				overloads.append(p)

	var blast_centers: Array[Vector2i] = []
	var overloads_destroyed: Array[Vector2i] = []
	var splash_cells: Array[Vector2i] = []
	var cleared_set := {}
	var score_gain := 0

	if not overloads.is_empty():
		for idx in range(mini(4, overloads.size())):
			var op: Vector2i = overloads[idx]
			blast_centers.append(op)
			overloads_destroyed.append(op)
			cleared_set[op] = true
			board.clear_cell(op)
			progress["overloads_neutralized"] = int(progress.get("overloads_neutralized", 0)) + 1
			score_gain += 220
			var splashed_here := 0
			for nb in BoardState.get_8way_neighbors(op):
				if splashed_here >= 2 or cleared_set.has(nb):
					continue
				var ncell := board.get_cell(nb)
				if str(ncell.get("kind", "")) == "organ":
					var org := str(ncell.get("organ", ""))
					cleared_set[nb] = true
					board.clear_cell(nb)
					splash_cells.append(nb)
					if org != "":
						progress["collected"][org] = int(progress["collected"].get(org, 0)) + 1
					score_gain += 65
					splashed_here += 1
	else:
		# No hazards on board: detonate a juicy 3x3 center shockwave!
		var center_p := Vector2i(BoardState.COLS / 2, BoardState.ROWS / 2)
		blast_centers.append(center_p)
		var ring_pts: Array[Vector2i] = [center_p]
		ring_pts.append_array(BoardState.get_8way_neighbors(center_p))
		for bp in ring_pts:
			if cleared_set.has(bp):
				continue
			var bcell := board.get_cell(bp)
			var bkind := str(bcell.get("kind", ""))
			if bkind == "organ":
				var org := str(bcell.get("organ", ""))
				cleared_set[bp] = true
				board.clear_cell(bp)
				splash_cells.append(bp)
				if org != "":
					progress["collected"][org] = int(progress["collected"].get(org, 0)) + 1
				score_gain += 70
			elif bkind == "care" or bkind == "bloom":
				cleared_set[bp] = true
				board.clear_cell(bp)
				splash_cells.append(bp)
				if bkind == "care":
					progress["care_activated"] = int(progress.get("care_activated", 0)) + 1
				score_gain += 140

	progress["care_energy"] = energy - COST_DETOX_BOMB
	progress["score"] = int(progress.get("score", 0)) + score_gain

	var weights: Dictionary = level_def.get("weights", {"heart": 25, "brain": 25, "lungs": 25, "kidneys": 25})
	var min_care := int(level_def.get("min_care_on_board", 0))
	var min_ov := int(level_def.get("min_overload_on_board", 0))
	var refill := board.apply_gravity_and_refill(rng, weights, min_care, min_ov)
	board.ensure_playable_board(rng, 3, weights)

	return {
		"used": true,
		"ability": "bomb",
		"blast_centers": blast_centers,
		"overloads_destroyed": overloads_destroyed,
		"splash_cells": splash_cells,
		"score_gained": score_gain,
		"refill": refill
	}


static func apply_second_wind(progress: Dictionary, max_pulse: int = 100, shield_max: int = 2) -> Dictionary:
	if bool(progress.get("second_wind_used", false)):
		return {"used": false, "reason": "already_used"}
	progress["second_wind_used"] = true
	progress["moves_left"] = int(progress.get("moves_left", 0)) + 3
	progress["pulse_meter"] = mini(max_pulse, maxi(25, int(progress.get("pulse_meter", 0)) + 25))
	progress["shield_charges"] = mini(shield_max, int(progress.get("shield_charges", 0)) + 1)
	return {
		"used": true,
		"moves_added": 3,
		"pulse_meter": int(progress["pulse_meter"]),
		"shield_charges": int(progress["shield_charges"])
	}
