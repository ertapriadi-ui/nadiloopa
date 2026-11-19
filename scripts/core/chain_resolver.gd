class_name ChainResolver
extends RefCounted
## Orchestrates deterministic chain commit, Nadi Loop bonus, Endpoint Pulse, streak multiplier,
## Care Energy charging, restriction expiry, gravity/refill, and win/lose checks.


static func resolve_turn(board: BoardState, chain: Array[Vector2i], level_def: Dictionary, progress: Dictionary, rng: RandomNumberGenerator, balance: Dictionary) -> Dictionary:
	var min_len := 3
	if not ChainValidator.is_valid_commit(board, chain, min_len):
		return {"committed": false, "reason": "invalid_chain"}

	var snapshot := board.clone()
	var is_loop_chain := ChainValidator.is_loop(chain)
	var organ_type := str(snapshot.get_cell(chain[0]).get("organ", ""))
	var endpoint: Vector2i = chain[chain.size() - 1]

	# Deduplicate positions when a Nadi Loop returns to an earlier tile
	var unique_chain: Array[Vector2i] = []
	var cleared_set := {}
	for pos in chain:
		if not cleared_set.has(pos):
			cleared_set[pos] = true
			unique_chain.append(pos)
			board.clear_cell(pos)

	var cleared_organ_count := unique_chain.size()

	# Nadi Loop clears up to 3 bonus matching organ tiles anywhere on the board!
	var loop_bonus_clears: Array[Vector2i] = []
	if is_loop_chain:
		progress["loops_formed"] = int(progress.get("loops_formed", 0)) + 1
		for r in range(BoardState.ROWS):
			for c in range(BoardState.COLS):
				var p := Vector2i(c, r)
				if cleared_set.has(p):
					continue
				var cell := board.get_cell(p)
				if cell.get("kind", "") == "organ" and str(cell.get("organ", "")) == organ_type:
					board.clear_cell(p)
					cleared_set[p] = true
					loop_bonus_clears.append(p)
					cleared_organ_count += 1
					if loop_bonus_clears.size() >= 3:
						break
			if loop_bonus_clears.size() >= 3:
				break

	# Combo streak multiplier (1.0x up to 2.0x on consecutive 4+ or loop chains)
	var streak := int(progress.get("combo_streak", 0))
	if unique_chain.size() >= 4 or is_loop_chain:
		streak = mini(5, streak + 1)
	else:
		streak = 0
	progress["combo_streak"] = streak
	var streak_mult := 1.0 + float(maxi(0, streak - 1)) * 0.2

	var base_tile_score := int(balance.get("base_tile_score", 25))
	var long_thresh := int(balance.get("long_chain_threshold", 5))
	var raw_chain_score := ScoreManager.calculate_chain_score(cleared_organ_count, base_tile_score)
	if is_loop_chain:
		raw_chain_score = int(round(float(raw_chain_score) * 1.5))
	var chain_score := int(round(float(raw_chain_score) * streak_mult))

	progress["collected"][organ_type] = int(progress["collected"].get(organ_type, 0)) + cleared_organ_count
	if unique_chain.size() >= long_thresh or is_loop_chain:
		progress["long_chains"] = int(progress.get("long_chains", 0)) + 1

	# Healthy Veggie/Salad ("care") & Antioxidant Fruit ("bloom") adjacent to non-endpoint chain tiles
	# also pop with the chain ("ikut pecah") to grant extra Energy, Pulse & Bonus Points!
	var ep_nb_set := {}
	var ep_pulse_nbs := BoardState.get_8way_neighbors(endpoint) if is_loop_chain else BoardState.get_orthogonal_neighbors(endpoint)
	for enb in ep_pulse_nbs:
		ep_nb_set[enb] = true
	var healthy_bonus_score := 0
	var healthy_energy := 0
	var healthy_pulse_gain := 0
	var healthy_popped: Array[Dictionary] = []
	for ci in range(unique_chain.size()):
		var cp: Vector2i = unique_chain[ci]
		if cp == endpoint:
			continue
		for nb in BoardState.get_orthogonal_neighbors(cp):
			if cleared_set.has(nb) or ep_nb_set.has(nb):
				continue
			var ncell := snapshot.get_cell(nb)
			var nkind := str(ncell.get("kind", ""))
			if nkind == "care" or nkind == "bloom":
				cleared_set[nb] = true
				board.clear_cell(nb)
				var pts := 180 if nkind == "bloom" else 120
				healthy_bonus_score += pts
				healthy_energy += 10
				healthy_pulse_gain += 5
				if nkind == "care":
					progress["care_activated"] = int(progress.get("care_activated", 0)) + 1
				healthy_popped.append({"pos": nb, "kind": nkind, "score": pts})

	# Charge Care Energy (0..100) & apply healthy pop pulse bonus before Endpoint Pulse
	var energy_add := cleared_organ_count * 6 + healthy_energy + (15 if (unique_chain.size() >= long_thresh or is_loop_chain) else 0)
	var max_pulse := int(balance.get("max_pulse", 100))
	if healthy_pulse_gain > 0:
		progress["pulse_meter"] = mini(max_pulse, int(progress.get("pulse_meter", 100)) + healthy_pulse_gain)

	# Endpoint Pulse (8-way on Nadi Loop, 4-way normal)
	var pulse_res := PulseSystem.resolve_endpoint(
		board,
		snapshot,
		endpoint,
		cleared_set,
		int(progress.get("shield_charges", 0)),
		int(progress.get("pulse_meter", 100)),
		balance,
		is_loop_chain
	)
	progress["shield_charges"] = pulse_res["shield_charges"]
	progress["pulse_meter"] = pulse_res["pulse_meter"]
	progress["care_activated"] = int(progress.get("care_activated", 0)) + int(pulse_res["care_activated"])
	progress["overloads_neutralized"] = int(progress.get("overloads_neutralized", 0)) + int(pulse_res["overloads_neutralized"])
	energy_add += int(pulse_res.get("energy_gained", 0))
	progress["care_energy"] = mini(100, int(progress.get("care_energy", 0)) + energy_add)

	var turn_score: int = chain_score + healthy_bonus_score + int(pulse_res["bonus_score"])
	progress["score"] = int(progress.get("score", 0)) + turn_score

	HazardSystem.tick_restrictions(board)
	progress["moves_left"] = maxi(0, int(progress.get("moves_left", 0)) - 1)

	var weights: Dictionary = level_def.get("weights", {"heart": 25, "brain": 25, "lungs": 25, "kidneys": 25})
	var min_care := int(level_def.get("min_care_on_board", 0))
	var min_ov := int(level_def.get("min_overload_on_board", 0))
	var objs: Dictionary = level_def.get("objectives", {})
	var needs_care_goal := objs.has("activate_care") or objs.has("neutralize_overload")
	var active_min_care := min_care if needs_care_goal else 0
	var active_min_ov := min_ov if objs.has("neutralize_overload") else mini(min_ov, 1)
	var refill_info := board.apply_gravity_and_refill(rng, weights, active_min_care, active_min_ov)
	var reshuffled := board.ensure_playable_board(rng, min_len, weights)

	var status := "continue"
	var move_bonus := 0
	var stars := 0
	var lose_reason := ""

	if int(progress["pulse_meter"]) <= 0:
		status = "lose"
		lose_reason = "pulse"
	elif LevelManager.are_objectives_complete(level_def, progress):
		status = "win"
		move_bonus = ScoreManager.calculate_move_bonus(int(progress["moves_left"]), int(balance.get("remaining_move_bonus", 120)))
		progress["score"] = int(progress.get("score", 0)) + move_bonus
		stars = ScoreManager.calculate_stars(int(progress["score"]), level_def.get("star_thresholds", [1000, 2000, 3000]))
	elif int(progress["moves_left"]) <= 0:
		status = "lose"
		lose_reason = "moves"

	return {
		"committed": true,
		"is_loop": is_loop_chain,
		"organ": organ_type,
		"chain": chain.duplicate(),
		"chain_len": cleared_organ_count,
		"unique_len": unique_chain.size(),
		"loop_bonus_clears": loop_bonus_clears,
		"healthy_popped": healthy_popped,
		"healthy_bonus_score": healthy_bonus_score,
		"streak": streak,
		"streak_mult": streak_mult,
		"is_large_match": cleared_organ_count >= long_thresh,
		"chain_score": chain_score,
		"turn_score": turn_score,
		"move_bonus": move_bonus,
		"stars": stars,
		"pulse": pulse_res,
		"refill": refill_info,
		"reshuffled": reshuffled,
		"status": status,
		"lose_reason": lose_reason
	}
