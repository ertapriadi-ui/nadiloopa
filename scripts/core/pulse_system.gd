class_name PulseSystem
extends RefCounted
## Deterministic Endpoint Pulse evaluation and pre-refill resolution.
## Supports normal 4-way Endpoint Pulse and 8-way Nadi Loop Super Pulse:
##   Pass A: Care boosters & Vitality Blooms activate FIRST.
##   Pass B: Overload hazards (normal hp=1 & Armored hp=2) evaluate SECOND.


static func preview_endpoint(board: BoardState, chain: Array[Vector2i], current_shields: int, current_pulse: int, balance: Dictionary) -> Dictionary:
	if board == null or chain.size() < 3:
		return {
			"valid": false,
			"is_loop": false,
			"endpoint": Vector2i(-1, -1),
			"neighbors": [],
			"care_hits": 0,
			"bloom_hits": 0,
			"overload_blocked": 0,
			"overload_cracked": 0,
			"overload_unshielded": 0,
			"net_pulse_delta": 0,
			"summary_tag": "none"
		}

	var is_loop_chain := ChainValidator.is_loop(chain)
	var endpoint: Vector2i = chain[chain.size() - 1]
	var neighbors := BoardState.get_8way_neighbors(endpoint) if is_loop_chain else BoardState.get_orthogonal_neighbors(endpoint)

	var max_pulse := int(balance.get("max_pulse", 100))
	var care_restore := int(balance.get("care_pulse_restore", 8))
	var shield_max := int(balance.get("care_shield_max", 2))
	var overload_pen := int(balance.get("overload_pulse_penalty", 10))

	var sim_shields := mini(shield_max, current_shields + (1 if is_loop_chain else 0))
	var sim_pulse := mini(max_pulse, current_pulse + (10 if is_loop_chain else 0))

	var care_cells: Array[Vector2i] = []
	var bloom_cells: Array[Vector2i] = []
	for nb in neighbors:
		var kind := str(board.get_cell(nb).get("kind", ""))
		if kind == "care":
			care_cells.append(nb)
		elif kind == "bloom":
			bloom_cells.append(nb)

	# Pass A: Care & Bloom first
	for _cp in care_cells:
		var res := BoosterSystem.activate_care(sim_shields, sim_pulse, care_restore, max_pulse, shield_max)
		sim_shields = res["shield_charges"]
		sim_pulse = res["pulse_meter"]
	for _bp in bloom_cells:
		sim_pulse = mini(max_pulse, sim_pulse + 6)

	# Pass B: Overload second
	var blocked := 0
	var cracked := 0
	var unshielded := 0
	var neighbor_tags: Array[Dictionary] = []
	for nb in neighbors:
		var c := board.get_cell(nb)
		var kind := str(c.get("kind", ""))
		if kind == "care":
			neighbor_tags.append({"pos": nb, "tag": "care"})
		elif kind == "bloom":
			neighbor_tags.append({"pos": nb, "tag": "bloom"})
		elif kind == "overload":
			if sim_shields > 0:
				sim_shields -= 1
				blocked += 1
				if int(c.get("hp", 1)) > 1:
					cracked += 1
					neighbor_tags.append({"pos": nb, "tag": "overload_cracked"})
				else:
					neighbor_tags.append({"pos": nb, "tag": "overload_blocked"})
			else:
				sim_pulse = maxi(0, sim_pulse - overload_pen)
				unshielded += 1
				neighbor_tags.append({"pos": nb, "tag": "overload_danger"})
		else:
			neighbor_tags.append({"pos": nb, "tag": "neutral"})

	var tag := "neutral"
	if is_loop_chain and unshielded > 0:
		tag = "loop_danger"
	elif is_loop_chain:
		tag = "loop"
	elif care_cells.size() > 0 and (blocked > 0 or unshielded > 0):
		tag = "care_and_overload"
	elif unshielded > 0:
		tag = "overload_danger"
	elif cracked > 0 and blocked == cracked:
		tag = "overload_cracked"
	elif blocked > 0:
		tag = "overload_blocked"
	elif care_cells.size() > 0:
		tag = "care"
	elif bloom_cells.size() > 0:
		tag = "bloom"

	return {
		"valid": true,
		"is_loop": is_loop_chain,
		"endpoint": endpoint,
		"neighbors": neighbor_tags,
		"care_hits": care_cells.size(),
		"bloom_hits": bloom_cells.size(),
		"overload_blocked": blocked,
		"overload_cracked": cracked,
		"overload_unshielded": unshielded,
		"net_pulse_delta": sim_pulse - current_pulse,
		"summary_tag": tag
	}


static func resolve_endpoint(board: BoardState, snapshot: BoardState, endpoint: Vector2i, cleared_set: Dictionary, shield_charges: int, pulse_meter: int, balance: Dictionary, is_loop_chain: bool = false) -> Dictionary:
	var neighbors := BoardState.get_8way_neighbors(endpoint) if is_loop_chain else BoardState.get_orthogonal_neighbors(endpoint)
	var max_pulse := int(balance.get("max_pulse", 100))
	var care_restore := int(balance.get("care_pulse_restore", 8))
	var shield_max := int(balance.get("care_shield_max", 2))
	var overload_pen := int(balance.get("overload_pulse_penalty", 10))
	var max_restrict := int(balance.get("overload_restrict_max_cells", 2))
	var restrict_turns := int(balance.get("overload_restrict_turns", 1))
	var care_bonus := int(balance.get("care_score_bonus", 150))
	var neutralize_bonus := int(balance.get("overload_neutralize_bonus", 120))

	var cur_shields := mini(shield_max, shield_charges + (1 if is_loop_chain else 0))
	var cur_pulse := mini(max_pulse, pulse_meter + (10 if is_loop_chain else 0))
	var bonus_score := 0
	var energy_gained := 0
	var care_activated := 0
	var blooms_collected := 0
	var overloads_neutralized := 0
	var overloads_cracked := 0
	var overloads_triggered := 0
	var care_cells: Array[Vector2i] = []
	var bloom_cells: Array[Vector2i] = []
	var blocked_cells: Array[Vector2i] = []
	var cracked_cells: Array[Vector2i] = []
	var triggered_cells: Array[Vector2i] = []
	var newly_restricted_cells: Array[Vector2i] = []

	# Pass A: Care & Bloom from pre-refill snapshot first
	for nb in neighbors:
		var scell := snapshot.get_cell(nb)
		var skind := str(scell.get("kind", ""))
		if skind == "care":
			var bres := BoosterSystem.activate_care(cur_shields, cur_pulse, care_restore, max_pulse, shield_max)
			cur_shields = bres["shield_charges"]
			cur_pulse = bres["pulse_meter"]
			board.clear_cell(nb)
			cleared_set[nb] = true
			care_activated += 1
			bonus_score += care_bonus
			care_cells.append(nb)
		elif skind == "bloom":
			cur_pulse = mini(max_pulse, cur_pulse + 6)
			board.clear_cell(nb)
			cleared_set[nb] = true
			blooms_collected += 1
			energy_gained += 20
			bonus_score += 250
			bloom_cells.append(nb)

	# Pass B: Overload hazards second
	for nb in neighbors:
		var scell := snapshot.get_cell(nb)
		if scell.get("kind", "") == "overload":
			if cur_shields > 0:
				cur_shields -= 1
				var hp := int(scell.get("hp", 1))
				if hp > 1:
					board.cells[BoardState.idx(nb.x, nb.y)]["hp"] = hp - 1
					overloads_cracked += 1
					bonus_score += 80
					cracked_cells.append(nb)
				else:
					board.clear_cell(nb)
					cleared_set[nb] = true
					overloads_neutralized += 1
					bonus_score += neutralize_bonus
					blocked_cells.append(nb)
			else:
				var hres := HazardSystem.apply_overload_hit(board, nb, cleared_set, cur_pulse, overload_pen, max_restrict, restrict_turns)
				cur_pulse = hres["pulse_meter"]
				overloads_triggered += 1
				triggered_cells.append(nb)
				for rp in hres["restricted_cells"]:
					newly_restricted_cells.append(rp)

	return {
		"is_loop": is_loop_chain,
		"endpoint": endpoint,
		"neighbors": neighbors,
		"shield_charges": cur_shields,
		"pulse_meter": cur_pulse,
		"bonus_score": bonus_score,
		"energy_gained": energy_gained,
		"care_activated": care_activated,
		"blooms_collected": blooms_collected,
		"overloads_neutralized": overloads_neutralized,
		"overloads_cracked": overloads_cracked,
		"overloads_triggered": overloads_triggered,
		"care_cells": care_cells,
		"bloom_cells": bloom_cells,
		"blocked_cells": blocked_cells,
		"cracked_cells": cracked_cells,
		"triggered_cells": triggered_cells,
		"newly_restricted_cells": newly_restricted_cells
	}
