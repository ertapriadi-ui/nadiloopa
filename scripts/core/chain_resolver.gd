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

	# Harmony Fever active bonus: clears +1 extra matching organ anywhere on board and doubles chain score!
	var fever_active := int(progress.get("fever_turns", 0)) > 0
	var fever_bonus_clears: Array[Vector2i] = []
	if fever_active:
		for r in range(BoardState.ROWS):
			for c in range(BoardState.COLS):
				var fp := Vector2i(c, r)
				if cleared_set.has(fp):
					continue
				var fcell := board.get_cell(fp)
				if fcell.get("kind", "") == "organ" and str(fcell.get("organ", "")) == organ_type:
					board.clear_cell(fp)
					cleared_set[fp] = true
					fever_bonus_clears.append(fp)
					cleared_organ_count += 1
					break
			if not fever_bonus_clears.is_empty():
				break

	# Combo streak multiplier (1.0x up to 2.0x on consecutive 4+ or loop chains)
	var streak := int(progress.get("combo_streak", 0))
	if unique_chain.size() >= 4 or is_loop_chain:
		streak = mini(5, streak + 1)
	else:
		streak = 0
	progress["combo_streak"] = streak
	var streak_mult := 1.0 + float(maxi(0, streak - 1)) * 0.2

	# Harmony Fever meter charge & activation (reaches 3/3 -> 2 turns of Harmony Fever!)
	var fever_triggered := false
	if fever_active:
		progress["fever_turns"] = maxi(0, int(progress.get("fever_turns", 0)) - 1)
	else:
		var charge_add := 2 if is_loop_chain else (1 if unique_chain.size() >= 4 else 0)
		if charge_add > 0:
			var next_charge := int(progress.get("fever_charge", 0)) + charge_add
			if next_charge >= 3:
				progress["fever_charge"] = 0
				progress["fever_turns"] = 2
				progress["fever_activations"] = int(progress.get("fever_activations", 0)) + 1
				fever_triggered = true
			else:
				progress["fever_charge"] = next_charge

	var base_tile_score := int(balance.get("base_tile_score", 25))
	var long_thresh := int(balance.get("long_chain_threshold", 5))
	var raw_chain_score := ScoreManager.calculate_chain_score(cleared_organ_count, base_tile_score)
	if is_loop_chain:
		raw_chain_score = int(round(float(raw_chain_score) * 1.5))
	var fever_mult := 2.0 if fever_active else 1.0
	var chain_score := int(round(float(raw_chain_score) * streak_mult * fever_mult))

	progress["collected"][organ_type] = int(progress["collected"].get(organ_type, 0)) + cleared_organ_count
	progress["best_chain_len"] = maxi(int(progress.get("best_chain_len", 0)), cleared_organ_count)
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
	if not healthy_popped.is_empty():
		progress["healthy_pops"] = int(progress.get("healthy_pops", 0)) + healthy_popped.size()

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

	# Tiered Mega-Explosions & Board-Reset Combos (v2.6.0):
	# - Tier 1 (6-7 unique): Vitality Burst — 3x3 shockwave around endpoint, clears up to 4 organs (+60 each) & destroys Overloads in 3x3 (+120 each)!
	# - Tier 2 (8-9 unique): Super Nova Splash — blasts entire row + column cross, destroys ALL Overloads in cross (+150 each), +400 bonus, +15 Energy, +1 Bonus Move!
	# - Tier 3 (10+ unique): Grand Harmony Mega Blast & Board Reset — destroys ALL Overloads on the ENTIRE board (+180 each), clears remaining tiles for a fresh Board Reset, +1200 bonus, refills Pulse to 100%, +25 Energy, +2 Bonus Moves!
	var ulen := unique_chain.size()
	var mega_tier := 3 if ulen >= 10 else (2 if ulen >= 8 else (1 if ulen >= 6 else 0))
	var vitality_burst_triggered := mega_tier >= 1
	var vitality_burst_cells: Array[Vector2i] = []
	var mega_cells: Array[Vector2i] = []
	var mega_overloads_destroyed: Array[Vector2i] = []
	var mega_bonus_score := 0
	var bonus_moves_gained := 0
	var board_reset_triggered := false

	if mega_tier == 1:
		for nb in BoardState.get_8way_neighbors(endpoint):
			if cleared_set.has(nb):
				continue
			var bcell := board.get_cell(nb)
			var bkind := str(bcell.get("kind", ""))
			if bkind == "overload":
				cleared_set[nb] = true
				board.clear_cell(nb)
				mega_overloads_destroyed.append(nb)
				mega_cells.append(nb)
				progress["overloads_neutralized"] = int(progress.get("overloads_neutralized", 0)) + 1
				mega_bonus_score += 120
			elif bkind == "organ" and vitality_burst_cells.size() < 4:
				var nb_org := str(bcell.get("organ", ""))
				cleared_set[nb] = true
				board.clear_cell(nb)
				vitality_burst_cells.append(nb)
				mega_cells.append(nb)
				if nb_org != "":
					progress["collected"][nb_org] = int(progress["collected"].get(nb_org, 0)) + 1
				mega_bonus_score += 60
	elif mega_tier == 2:
		# Super Nova: entire row & column cross-blast through endpoint
		var cross_targets: Array[Vector2i] = []
		for c in range(BoardState.COLS):
			cross_targets.append(Vector2i(c, endpoint.y))
		for r in range(BoardState.ROWS):
			if r != endpoint.y:
				cross_targets.append(Vector2i(endpoint.x, r))
		for tp in cross_targets:
			if cleared_set.has(tp):
				continue
			var tcell := board.get_cell(tp)
			var tkind := str(tcell.get("kind", ""))
			if tkind == "empty":
				continue
			cleared_set[tp] = true
			board.clear_cell(tp)
			mega_cells.append(tp)
			if tkind == "overload":
				mega_overloads_destroyed.append(tp)
				progress["overloads_neutralized"] = int(progress.get("overloads_neutralized", 0)) + 1
				mega_bonus_score += 150
			elif tkind == "organ":
				var torg := str(tcell.get("organ", ""))
				vitality_burst_cells.append(tp)
				if torg != "":
					progress["collected"][torg] = int(progress["collected"].get(torg, 0)) + 1
				mega_bonus_score += 75
			elif tkind == "care" or tkind == "bloom":
				if tkind == "care":
					progress["care_activated"] = int(progress.get("care_activated", 0)) + 1
				mega_bonus_score += 120
		mega_bonus_score += 400
		bonus_moves_gained = 1
		progress["care_energy"] = mini(100, int(progress.get("care_energy", 0)) + 15)
	elif mega_tier == 3:
		# Grand Harmony Mega Blast & Board Reset: obliterates all Overloads & refreshes entire board!
		board_reset_triggered = true
		for r in range(BoardState.ROWS):
			for c in range(BoardState.COLS):
				var gp := Vector2i(c, r)
				if cleared_set.has(gp):
					continue
				var gcell := board.get_cell(gp)
				var gkind := str(gcell.get("kind", ""))
				if gkind == "empty":
					continue
				cleared_set[gp] = true
				board.clear_cell(gp)
				mega_cells.append(gp)
				if gkind == "overload":
					mega_overloads_destroyed.append(gp)
					progress["overloads_neutralized"] = int(progress.get("overloads_neutralized", 0)) + 1
					mega_bonus_score += 180
				elif gkind == "organ":
					var gorg := str(gcell.get("organ", ""))
					if gorg != "":
						progress["collected"][gorg] = int(progress["collected"].get(gorg, 0)) + 1
					mega_bonus_score += 35
				elif gkind == "care" or gkind == "bloom":
					if gkind == "care":
						progress["care_activated"] = int(progress.get("care_activated", 0)) + 1
					mega_bonus_score += 100
		mega_bonus_score += 1200
		bonus_moves_gained = 2
		progress["pulse_meter"] = max_pulse
		progress["care_energy"] = mini(100, int(progress.get("care_energy", 0)) + 25)

	var turn_score: int = chain_score + healthy_bonus_score + mega_bonus_score + int(pulse_res["bonus_score"])
	progress["score"] = int(progress.get("score", 0)) + turn_score

	HazardSystem.tick_restrictions(board)
	progress["moves_left"] = maxi(0, int(progress.get("moves_left", 0)) - 1) + bonus_moves_gained

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
		"fever_active": fever_active,
		"fever_triggered": fever_triggered,
		"fever_turns": int(progress.get("fever_turns", 0)),
		"fever_charge": int(progress.get("fever_charge", 0)),
		"fever_bonus_clears": fever_bonus_clears,
		"vitality_burst_triggered": vitality_burst_triggered,
		"vitality_burst_cells": vitality_burst_cells,
		"mega_tier": mega_tier,
		"mega_cells": mega_cells,
		"mega_overloads_destroyed": mega_overloads_destroyed,
		"bonus_moves_gained": bonus_moves_gained,
		"board_reset_triggered": board_reset_triggered,
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
