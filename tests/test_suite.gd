extends SceneTree
## Headless automated QA suite & 100-level solvability simulator for NADILOOPA v2.0.

var _ran: bool = false
var _failures: Array[String] = []
var _passes: int = 0

var _save_mgr: Node
var _loc_mgr: Node
var _audio_mgr: Node
var _game_mgr: Node


func _process(_delta: float) -> bool:
	if _ran:
		return false
	_ran = true

	_save_mgr = root.get_node("SaveManager")
	_loc_mgr = root.get_node("LocalizationManager")
	_audio_mgr = root.get_node("AudioManager")
	_game_mgr = root.get_node("GameManager")

	print("=== NADILOOPA v2.3 AUTOMATED QA SUITE START ===")
	_test_grid_bounds_and_84_slots()
	_test_chain_rules_backtrack_and_touch_signal()
	_test_nadi_loop_8way_and_bonus()
	_test_endpoint_orientation_and_pre_refill_pulse()
	_test_booster_hazard_armor_bloom_and_lock_expiry()
	_test_tactical_care_abilities()
	_test_harmony_fever_mode()
	_test_second_wind_revival()
	_test_gravity_refill_and_reshuffle()
	_test_scoring_moves_win_lose()
	_test_persistence_and_corrupt_recovery()
	_test_daily_quests_star_chests_and_rank()
	_test_bilingual_sprites_and_audio_assets()
	_test_endless_and_daily_modes()
	_test_all_100_levels_and_simulations()

	print("=== QA SUMMARY: %d assertions passed, %d failed ===" % [_passes, _failures.size()])
	for f in _failures:
		printerr("FAIL: " + f)

	quit(0 if _failures.is_empty() else 1)
	return true


func _assert_true(cond: bool, msg: String) -> void:
	if cond:
		_passes += 1
	else:
		_failures.append(msg)
		printerr("[ASSERT FAILED] " + msg)


func _assert_eq(a: Variant, b: Variant, msg: String) -> void:
	if a == b:
		_passes += 1
	else:
		var detail := "%s (got=%s, expected=%s)" % [msg, str(a), str(b)]
		_failures.append(detail)
		printerr("[ASSERT FAILED] " + detail)


func _test_grid_bounds_and_84_slots() -> void:
	BoardState.set_difficulty_grid("hard")
	var b := BoardState.new()
	_assert_eq(BoardState.COLS, 7, "Hard grid must have 7 columns")
	_assert_eq(BoardState.ROWS, 12, "Hard grid must have 12 rows")
	_assert_eq(BoardState.TOTAL_CELLS, 84, "Hard grid must have 84 cells")
	_assert_eq(b.cells.size(), 84, "BoardState.cells array must have 84 slots")
	_assert_eq(BoardState.ORGANS.size(), 7, "7 smiling organ families defined")
	_assert_true(BoardState.is_in_bounds(Vector2i(0, 0)), "(0,0) in bounds")
	_assert_true(BoardState.is_in_bounds(Vector2i(6, 11)), "(6,11) in bounds")
	_assert_true(not BoardState.is_in_bounds(Vector2i(-1, 0)), "(-1,0) out of bounds")
	_assert_true(not BoardState.is_in_bounds(Vector2i(7, 0)), "(7,0) out of bounds")
	_assert_true(not BoardState.is_in_bounds(Vector2i(0, 12)), "(0,12) out of bounds")
	_assert_eq(BoardState.get_orthogonal_neighbors(Vector2i(0, 0)).size(), 2, "Corner (0,0) has 2 clipped orthogonal neighbors")
	_assert_eq(BoardState.get_8way_neighbors(Vector2i(0, 0)).size(), 3, "Corner (0,0) has 3 clipped 8-way neighbors")
	_assert_eq(BoardState.get_8way_neighbors(Vector2i(3, 5)).size(), 8, "Center (3,5) has 8 8-way neighbors")

	# Verify adaptive Easy (5x7) & Medium (6x9) grids
	BoardState.set_difficulty_grid("easy")
	var be := BoardState.new()
	_assert_eq(BoardState.COLS, 5, "Easy grid has 5 columns")
	_assert_eq(BoardState.ROWS, 7, "Easy grid has 7 rows")
	_assert_eq(BoardState.TOTAL_CELLS, 35, "Easy grid has 35 cells")
	_assert_eq(be.cells.size(), 35, "Easy BoardState allocates 35 cells")
	var erng := RandomNumberGenerator.new()
	erng.seed = 101
	be.populate_initial(erng, {"heart": 25, "brain": 25, "lungs": 25, "muscle": 25}, [[5, 9]], [[6, 10]], [], [[1, 3]])
	_assert_true(be.has_any_valid_chain(3), "Easy 5x7 board remaps specials cleanly & guarantees playable chain")

	BoardState.set_difficulty_grid("medium")
	var bm := BoardState.new()
	_assert_eq(BoardState.COLS, 6, "Medium grid has 6 columns")
	_assert_eq(BoardState.ROWS, 9, "Medium grid has 9 rows")
	_assert_eq(BoardState.TOTAL_CELLS, 54, "Medium grid has 54 cells")
	_assert_eq(bm.cells.size(), 54, "Medium BoardState allocates 54 cells")

	BoardState.set_difficulty_grid("hard")


func _test_chain_rules_backtrack_and_touch_signal() -> void:
	var b := BoardState.new()
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			b.set_organ(Vector2i(c, r), "brain")
	b.set_organ(Vector2i(1, 1), "heart")
	b.set_organ(Vector2i(2, 1), "heart")
	b.set_organ(Vector2i(2, 2), "heart")
	b.set_organ(Vector2i(3, 2), "heart")
	b.set_organ(Vector2i(1, 2), "lungs")
	b.set_special(Vector2i(0, 1), "care")
	b.set_special(Vector2i(4, 2), "overload")

	_assert_true(not ChainValidator.can_start_at(b, Vector2i(0, 1)), "Cannot start on Care")
	_assert_true(not ChainValidator.can_start_at(b, Vector2i(4, 2)), "Cannot start on Overload")
	_assert_true(ChainValidator.can_start_at(b, Vector2i(1, 1)), "Can start on unrestricted organ")

	var chain: Array[Vector2i] = []
	_assert_eq(ChainValidator.try_step(b, chain, Vector2i(1, 1)), "added", "Start tile added")
	_assert_eq(ChainValidator.try_step(b, chain, Vector2i(2, 2)), "invalid", "Diagonal step rejected")
	_assert_eq(ChainValidator.try_step(b, chain, Vector2i(1, 2)), "invalid", "Different organ rejected")
	_assert_eq(ChainValidator.try_step(b, chain, Vector2i(2, 1)), "added", "Orthogonal step added")
	_assert_eq(ChainValidator.try_step(b, chain, Vector2i(2, 2)), "added", "Second orthogonal step added")
	_assert_eq(ChainValidator.try_step(b, chain, Vector2i(3, 2)), "added", "Third orthogonal step added")
	_assert_eq(ChainValidator.try_step(b, chain, Vector2i(2, 1)), "invalid", "Non-loop revisit rejected when not orthogonal/eligible")
	_assert_eq(ChainValidator.try_step(b, chain, Vector2i(2, 2)), "backtrack", "Backtrack pops last tile")
	_assert_eq(chain.size(), 3, "Backtrack leaves length 3")
	_assert_true(ChainValidator.is_valid_commit(b, chain), "Length-3 valid")

	var short_chain: Array[Vector2i] = [Vector2i(1, 1), Vector2i(2, 1)]
	var lv := {"id": 1, "moves": 10, "initial_pulse": 100, "objectives": {"collect": {"heart": 10}}, "weights": {"heart": 25, "brain": 25, "lungs": 25, "kidneys": 25}}
	var prog := LevelManager.create_initial_progress(lv)
	var test_rng := RandomNumberGenerator.new()
	test_rng.seed = 42
	var cancel_res := ChainResolver.resolve_turn(b, short_chain, lv, prog, test_rng, _game_mgr.config.get("balance", {}))
	_assert_true(not bool(cancel_res.get("committed", true)), "Too-short chain must not commit")
	_assert_eq(int(prog["moves_left"]), 10, "Cancelled short chain spends 0 moves")

	# Dynamically instantiate BoardRenderer & TouchInputController to avoid -s pre-autoload compile error
	var br_script: GDScript = load("res://scripts/ui/board_renderer.gd")
	var tic_script: GDScript = load("res://scripts/ui/touch_input_controller.gd")
	var br: Control = br_script.new()
	var tic: Control = tic_script.new()
	root.add_child(br)
	root.add_child(tic)
	tic.call("bind", br)
	tic.call("set_board_state", b)
	tic.call("set_input_enabled", true)
	var received_empty := [false]
	tic.connect("chain_updated", func(ch: Array[Vector2i]):
		if ch.is_empty():
			received_empty[0] = true
	)
	var single_arr: Array[Vector2i] = [Vector2i(1, 1)]
	tic.set("_chain", single_arr)
	tic.set("_is_dragging", true)
	tic.call("_end_drag")
	_assert_true(received_empty[0], "TouchInputController short drag cancel emits typed empty Array[Vector2i]")
	tic.queue_free()
	br.queue_free()


func _test_nadi_loop_8way_and_bonus() -> void:
	var b := BoardState.new()
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			b.set_organ(Vector2i(c, r), "brain")
	# 2x2 Heart square at (2,4), (3,4), (3,5), (2,5) -> loop back to (2,4)
	b.set_organ(Vector2i(2, 4), "heart")
	b.set_organ(Vector2i(3, 4), "heart")
	b.set_organ(Vector2i(3, 5), "heart")
	b.set_organ(Vector2i(2, 5), "heart")
	# Put extra Hearts far away to test 3 bonus clears + diagonal Overload at (1,3) from endpoint (2,4)!
	b.set_organ(Vector2i(0, 0), "heart")
	b.set_organ(Vector2i(6, 0), "heart")
	b.set_organ(Vector2i(6, 11), "heart")
	b.set_special(Vector2i(1, 3), "overload", 1)

	var loop_chain: Array[Vector2i] = []
	ChainValidator.try_step(b, loop_chain, Vector2i(2, 4))
	ChainValidator.try_step(b, loop_chain, Vector2i(3, 4))
	ChainValidator.try_step(b, loop_chain, Vector2i(3, 5))
	ChainValidator.try_step(b, loop_chain, Vector2i(2, 5))
	var step_res := ChainValidator.try_step(b, loop_chain, Vector2i(2, 4))
	_assert_eq(step_res, "loop", "Closing 2x2 square detects Nadi Loop")
	_assert_true(ChainValidator.is_loop(loop_chain), "is_loop true on closed 5-step circuit")
	_assert_true(ChainValidator.is_valid_commit(b, loop_chain), "Closed Nadi Loop is valid commit")

	var bal: Dictionary = _game_mgr.config.get("balance", {})
	var prev := PulseSystem.preview_endpoint(b, loop_chain, 0, 85, bal)
	_assert_true(bool(prev["is_loop"]), "Preview recognizes Nadi Loop")
	_assert_eq(int(prev["neighbors"].size()), 8, "Nadi Loop previews 8-way neighbors")
	_assert_eq(int(prev["overload_blocked"]), 1, "Loop +1 Shield blocks diagonal Overload at (1,3)")

	# Armored 2-HP Overload preview must emit overload_cracked, and unshielded Loop must flag loop_danger
	var ba := BoardState.new()
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			ba.set_organ(Vector2i(c, r), "brain")
	ba.set_organ(Vector2i(2, 4), "heart")
	ba.set_organ(Vector2i(3, 4), "heart")
	ba.set_organ(Vector2i(3, 5), "heart")
	ba.set_organ(Vector2i(2, 5), "heart")
	ba.set_special(Vector2i(1, 4), "overload", 2)
	ba.set_special(Vector2i(1, 3), "overload", 1)
	var prev_ld := PulseSystem.preview_endpoint(ba, [Vector2i(2, 4), Vector2i(3, 4), Vector2i(3, 5), Vector2i(2, 5), Vector2i(2, 4)], 0, 90, bal)
	_assert_eq(str(prev_ld["summary_tag"]), "loop_danger", "Nadi Loop hitting extra unshielded Overload flags loop_danger")
	_assert_eq(int(prev_ld["overload_cracked"]), 1, "Preview counts cracked 2-HP Armored Overload")
	var prev_crack := PulseSystem.preview_endpoint(ba, [Vector2i(2, 5), Vector2i(3, 4), Vector2i(2, 4)], 1, 90, bal)
	_assert_eq(str(prev_crack["summary_tag"]), "overload_cracked", "Shielded endpoint next to 2-HP Overload flags overload_cracked")

	var lv := {"id": 25, "moves": 15, "initial_pulse": 85, "objectives": {"collect": {"heart": 20}}, "weights": {"heart": 25, "brain": 25, "lungs": 25, "kidneys": 25}}
	var prog := LevelManager.create_initial_progress(lv)
	var lrng := RandomNumberGenerator.new()
	lrng.seed = 321
	var res := ChainResolver.resolve_turn(b, loop_chain, lv, prog, lrng, bal)
	_assert_true(bool(res["is_loop"]), "Turn resolved as Nadi Loop")
	_assert_eq(int(res["loop_bonus_clears"].size()), 3, "Nadi Loop clears 3 bonus matching organs")
	_assert_eq(int(res["chain_len"]), 7, "4 unique square tiles + 3 bonus clears = 7 collected")
	_assert_eq(int(res["pulse"]["overloads_neutralized"]), 1, "Diagonal Overload neutralized by loop shield")
	_assert_eq(int(prog["pulse_meter"]), 95, "Loop restored +10 Pulse from 85 to 95")


func _test_endpoint_orientation_and_pre_refill_pulse() -> void:
	var b := BoardState.new()
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			b.set_organ(Vector2i(c, r), "lungs")
	b.set_organ(Vector2i(2, 5), "heart")
	b.set_organ(Vector2i(3, 5), "heart")
	b.set_organ(Vector2i(4, 5), "heart")
	b.set_special(Vector2i(1, 5), "care")
	b.set_special(Vector2i(5, 5), "overload")

	var bal: Dictionary = _game_mgr.config.get("balance", {})
	var prev_lr := PulseSystem.preview_endpoint(b, [Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5)], 0, 100, bal)
	var prev_rl := PulseSystem.preview_endpoint(b, [Vector2i(4, 5), Vector2i(3, 5), Vector2i(2, 5)], 0, 100, bal)
	_assert_eq(str(prev_lr["summary_tag"]), "overload_danger", "L->R endpoint previews Overload danger")
	_assert_eq(str(prev_rl["summary_tag"]), "care", "R->L endpoint previews Care activation")


func _test_booster_hazard_armor_bloom_and_lock_expiry() -> void:
	var b := BoardState.new()
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			b.set_organ(Vector2i(c, r), "kidneys")
	b.set_organ(Vector2i(1, 5), "heart")
	b.set_organ(Vector2i(2, 5), "heart")
	b.set_organ(Vector2i(3, 5), "heart")
	b.set_special(Vector2i(3, 4), "care")
	b.set_special(Vector2i(4, 5), "overload", 2) # Armored 2-HP Overload!
	b.set_special(Vector2i(3, 6), "bloom", 1)

	var bal: Dictionary = _game_mgr.config.get("balance", {})
	var lv := {"id": 35, "moves": 12, "initial_pulse": 90, "objectives": {"collect": {"heart": 50}}, "weights": {"heart": 25, "brain": 25, "lungs": 25, "kidneys": 25}}
	var prog := LevelManager.create_initial_progress(lv)
	prog["care_energy"] = 0
	var trng := RandomNumberGenerator.new()
	trng.seed = 123

	var res := ChainResolver.resolve_turn(b, [Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5)], lv, prog, trng, bal)
	_assert_eq(int(res["pulse"]["care_activated"]), 1, "Care activated first")
	_assert_eq(int(res["pulse"]["blooms_collected"]), 1, "Vitality Bloom collected")
	_assert_eq(int(res["pulse"]["overloads_cracked"]), 1, "Armored Overload cracked hp 2->1")
	_assert_eq(int(res["pulse"]["overloads_neutralized"]), 0, "Armored Overload requires 2nd hit to clear")
	_assert_true(int(prog["care_energy"]) >= 38, "Bloom (+20) + chain (+18) charged Care Energy")

	# Side-chain Healthy Veggie ("care") & Antioxidant ("bloom") pop bonus ("ikut pecah") test
	var bh := BoardState.new()
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			bh.set_organ(Vector2i(c, r), "brain")
	bh.set_organ(Vector2i(1, 5), "muscle")
	bh.set_organ(Vector2i(2, 5), "muscle")
	bh.set_organ(Vector2i(3, 5), "muscle")
	bh.set_special(Vector2i(1, 4), "bloom", 1) # Adjacent to non-endpoint (1,5), outside endpoint (3,5)
	bh.set_special(Vector2i(2, 4), "care", 1) # Also adjacent to (2,5), wait (3,5) is endpoint and (2,4) is NOT orthogonal to (3,5)!
	var lvh := {"id": 40, "moves": 10, "initial_pulse": 80, "objectives": {"collect": {"muscle": 20}}, "weights": {"muscle": 25, "brain": 25, "heart": 25, "lungs": 25}}
	var progh := LevelManager.create_initial_progress(lvh)
	progh["care_energy"] = 0
	var hrng := RandomNumberGenerator.new()
	hrng.seed = 99
	var hres := ChainResolver.resolve_turn(bh, [Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5)], lvh, progh, hrng, bal)
	_assert_eq(int(hres.get("healthy_popped", []).size()), 2, "Adjacent non-endpoint Healthy Veggies & Fruits pop with chain")
	_assert_eq(int(hres.get("healthy_bonus_score", 0)), 300, "Salad (120) + Antioxidant (180) grant +300 bonus points")
	_assert_eq(int(progh["pulse_meter"]), 90, "Both popped healthy tiles add +5 Pulse each (80 -> 90)")
	_assert_true(int(progh["care_energy"]) >= 38, "Both popped healthy tiles charge extra +10 Energy each")

	# Lock expiry test
	var b_haz := BoardState.new()
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			b_haz.set_organ(Vector2i(c, r), "brain")
	b_haz.set_organ(Vector2i(1, 8), "heart")
	b_haz.set_organ(Vector2i(2, 8), "heart")
	b_haz.set_organ(Vector2i(3, 8), "heart")
	b_haz.set_special(Vector2i(4, 8), "overload", 1)
	b_haz.set_organ(Vector2i(0, 11), "lungs")
	b_haz.set_organ(Vector2i(1, 11), "lungs")
	b_haz.set_organ(Vector2i(2, 11), "lungs")

	var prog2 := LevelManager.create_initial_progress(lv)
	ChainResolver.resolve_turn(b_haz, [Vector2i(1, 8), Vector2i(2, 8), Vector2i(3, 8)], lv, prog2, trng, bal)
	_assert_eq(int(prog2["pulse_meter"]), 80, "Unshielded Overload deducted 10 from 90")
	var safe_chain := b_haz.find_sample_chain(3)
	ChainResolver.resolve_turn(b_haz, safe_chain, lv, prog2, trng, bal)
	var locked_after := 0
	for cdict in b_haz.cells:
		if int(cdict.get("restricted_turns", 0)) > 0:
			locked_after += 1
	_assert_eq(locked_after, 0, "1-move Overload restrictions expired after 1 player move")


func _test_tactical_care_abilities() -> void:
	var b := BoardState.new()
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			b.set_organ(Vector2i(c, r), "brain")
	b.set_organ(Vector2i(1, 1), "lungs", 1)
	b.set_special(Vector2i(4, 4), "overload", 2)

	var lv := {"id": 15, "objectives": {"collect": {"heart": 12}}, "weights": {"heart": 25, "brain": 25, "lungs": 25, "kidneys": 25}}
	var prog := {"collected": {"heart": 0}, "care_energy": 100, "pulse_meter": 80, "shield_charges": 0}
	var rng := RandomNumberGenerator.new()
	rng.seed = 55

	var r_spark := BoosterSystem.cast_fruit_spark(b, lv, prog, rng)
	_assert_true(bool(r_spark["used"]), "Fruit Spark activated")
	_assert_eq(str(r_spark["organ"]), "heart", "Fruit Spark converts to needed objective organ")
	_assert_eq(int(r_spark["cells"].size()), 4, "Fruit Spark converted 4 cells")

	var r_flow := BoosterSystem.cast_clear_flow(b, prog, 100)
	_assert_true(bool(r_flow["used"]), "Clear Flow activated")
	_assert_eq(int(b.get_cell(Vector2i(1, 1))["restricted_turns"]), 0, "Clear Flow cleared restriction")
	_assert_eq(int(prog["pulse_meter"]), 92, "Clear Flow healed +12 Pulse")
	_assert_eq(int(b.get_cell(Vector2i(4, 4))["hp"]), 1, "Clear Flow weakened 2-HP Overload armor")

	var r_rest := BoosterSystem.cast_rest_shield(b, prog, rng, 2)
	_assert_true(bool(r_rest["used"]), "Rest Shield activated")
	_assert_eq(int(prog["shield_charges"]), 1, "Rest Shield granted +1 Shield")
	_assert_true(b.count_kind("care") >= 1, "Rest Shield spawned Care tile")

	# No-op guards
	var prog_full := {"care_energy": 100, "pulse_meter": 100, "shield_charges": 2}
	var b_clean := BoardState.new()
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			b_clean.set_organ(Vector2i(c, r), "heart")
	var r_flow_noop := BoosterSystem.cast_clear_flow(b_clean, prog_full, 100)
	_assert_true(not bool(r_flow_noop["used"]), "Clear Flow blocks no-op when board clean & Pulse 100")
	_assert_eq(int(prog_full["care_energy"]), 100, "Clear Flow no-op spends 0 Care Energy")
	var r_rest_noop := BoosterSystem.cast_rest_shield(b_clean, prog_full, rng, 2)
	_assert_true(not bool(r_rest_noop["used"]), "Rest Shield blocks cast at max shields 2/2")
	_assert_eq(int(prog_full["care_energy"]), 100, "Rest Shield no-op spends 0 Care Energy")


func _test_gravity_refill_and_reshuffle() -> void:
	var b1 := BoardState.new()
	var b2 := BoardState.new()
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			b1.set_organ(Vector2i(c, r), "heart")
			b2.set_organ(Vector2i(c, r), "heart")
	for p in [Vector2i(3, 9), Vector2i(3, 10), Vector2i(3, 11)]:
		b1.clear_cell(p)
		b2.clear_cell(p)
	var rng1 := RandomNumberGenerator.new()
	var rng2 := RandomNumberGenerator.new()
	rng1.seed = 7777
	rng2.seed = 7777
	var w := {"heart": 25, "brain": 25, "lungs": 25, "kidneys": 25}
	b1.apply_gravity_and_refill(rng1, w, 0)
	b2.apply_gravity_and_refill(rng2, w, 0)
	var same := true
	for i in range(BoardState.TOTAL_CELLS):
		if b1.cells[i].get("organ", "") != b2.cells[i].get("organ", ""):
			same = false
	_assert_true(same, "Seeded gravity/refill produces identical deterministic boards")

	var dead := BoardState.new()
	var pattern := ["heart", "brain", "lungs", "kidneys"]
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			dead.set_organ(Vector2i(c, r), pattern[(c + r * 2) % 4])
	_assert_true(not dead.has_any_valid_chain(3), "Checkerboard deadboard detected")
	dead.ensure_playable_board(rng1, 3, w)
	_assert_true(dead.has_any_valid_chain(3), "Deadboard reshuffled into playable state")


func _test_scoring_moves_win_lose() -> void:
	var s3 := ScoreManager.calculate_chain_score(3, 25)
	var s6 := ScoreManager.calculate_chain_score(6, 25)
	_assert_true(s6 > s3 * 2, "Long chains reward higher score")


func _test_persistence_and_corrupt_recovery() -> void:
	var tmp_path := "user://test_nadiloopa_save_v2_qa.json"
	var tmp_bak := tmp_path + ".bak"
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))
	if FileAccess.file_exists(tmp_bak):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_bak))

	_save_mgr.set_test_save_path(tmp_path)
	_save_mgr.load_save()
	_save_mgr.set_setting("language", "id")
	_save_mgr.record_level_win(1, 3, 2100)
	_save_mgr.record_level_win(50, 2, 4800)
	_save_mgr.record_endless_run(7, 12500)
	_save_mgr.record_daily_win("2026-11-17")
	_assert_eq(int(_save_mgr.data.get("daily_streak", 0)), 1, "First daily win sets streak 1")
	_save_mgr.record_daily_win("2026-11-18")
	_assert_eq(int(_save_mgr.data.get("daily_streak", 0)), 2, "Consecutive daily win increments streak to 2")
	_save_mgr.record_daily_win("2026-11-20")
	_assert_eq(int(_save_mgr.data.get("daily_streak", 0)), 1, "Skipped day resets daily streak to 1")
	_save_mgr.unlock_achievement("ACH_HALFWAY")
	_save_mgr.save_to_disk()

	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	f.store_string("{corrupt_json")
	f.close()

	_save_mgr.load_save()
	_assert_true(_save_mgr.last_load_recovered_from_corruption, "Corrupt primary save flagged recovery")
	_assert_eq(str(_save_mgr.get_setting("language", "en")), "id", "Recovered settings intact")
	_assert_true(_save_mgr.get_unlocked_level() >= 51, "Recovered 100-level progression up to 51")
	_assert_true(_save_mgr.has_achievement("ACH_HALFWAY"), "Recovered unlocked achievements")

	_save_mgr.reset_progress_keep_settings()
	_assert_eq(_save_mgr.get_unlocked_level(), 1, "Reset progress returns unlocked level to 1")
	_assert_eq(str(_save_mgr.get_setting("language", "en")), "id", "Reset progress keeps language")

	_save_mgr.clear_test_save_path()
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))
	if FileAccess.file_exists(tmp_bak):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_bak))
	_save_mgr.load_save()


func _test_bilingual_sprites_and_audio_assets() -> void:
	var missing: Array[String] = _loc_mgr.validate_parity()
	_assert_eq(missing.size(), 0, "Zero missing translation keys between EN and ID: " + str(missing))

	for o in BoardState.ORGANS:
		_assert_true(FileAccess.file_exists("res://assets/sprites/tiles/organ_%s.png" % o), "Organ sprite exists: %s" % o)
		_assert_true(FileAccess.file_exists("res://assets/sprites/tiles/organ_%s_happy.png" % o), "Organ happy sprite exists: %s" % o)
	for sp in ["special_care", "special_bloom", "special_overload", "special_overload_soda", "special_overload_snack", "special_overload_armor", "icon_ability_spark", "icon_ability_flow", "icon_ability_rest"]:
		_assert_true(FileAccess.file_exists("res://assets/sprites/tiles/%s.png" % sp), "Special sprite exists: %s" % sp)

	var sfx_list: Array = _audio_mgr.get_registered_sfx_names()
	_assert_true(sfx_list.size() >= 21, "At least 21 SFX events registered (%d)" % sfx_list.size())
	for k in sfx_list:
		_assert_true(FileAccess.file_exists(_audio_mgr.SFX_PATHS[k]), "SFX file exists: %s" % k)
	var mus_list: Array = _audio_mgr.get_registered_music_names()
	_assert_true(mus_list.size() >= 4, "4 original music tracks registered (%d)" % mus_list.size())
	for k in mus_list:
		_assert_true(FileAccess.file_exists(_audio_mgr.MUSIC_TRACKS[k]), "Music file exists: %s" % k)


func _test_endless_and_daily_modes() -> void:
	var ew := LevelManager.build_endless_wave_def(5)
	_assert_true(bool(ew["is_boss"]), "Endless Wave 5 marked boss")
	var dl := LevelManager.build_daily_level({"year": 2026, "month": 11, "day": 18})
	_assert_eq(str(dl["daily_date"]), "2026-11-18", "Daily date deterministic")
	var drng := RandomNumberGenerator.new()
	drng.seed = int(dl["seed"])
	var db := LevelManager.build_board_for_level(dl, drng)
	_assert_true(db.has_any_valid_chain(3), "Daily Challenge board playable")


func _test_all_100_levels_and_simulations() -> void:
	var lm := LevelManager.new()
	_assert_eq(lm.get_level_count(), 100, "Exactly 100 levels defined")

	var bal: Dictionary = _game_mgr.config.get("balance", {})
	var report_levels: Array = []
	var all_pass := 0
	var ratio_sum := 0.0
	var star3_hits := 0

	for i in range(1, 101):
		var lv := lm.get_level(i)
		var schema_errs := LevelManager.validate_level_schema(lv)
		_assert_eq(schema_errs.size(), 0, "Level %d schema valid" % i)

		var wins := 0
		var total_moves_used := 0
		var total_score_sum := 0
		var canonical_won := false

		for run_idx in range(3):
			var sim_seed := int(lv.get("seed", 1000 + i)) + run_idx * 17
			var sim_rng := RandomNumberGenerator.new()
			sim_rng.seed = sim_seed
			var b := LevelManager.build_board_for_level(lv, sim_rng)
			var prog := LevelManager.create_initial_progress(lv)
			var moves_used := 0
			var status := "continue"

			while status == "continue" and int(prog["moves_left"]) > 0 and int(prog["pulse_meter"]) > 0:
				if int(prog.get("pulse_meter", 100)) < 75 and int(prog.get("care_energy", 0)) >= BoosterSystem.COST_CLEAR_FLOW:
					BoosterSystem.cast_clear_flow(b, prog, 100)
				if int(prog.get("shield_charges", 0)) == 0 and int(prog.get("care_energy", 0)) >= BoosterSystem.COST_REST_SHIELD and lv.get("objectives", {}).has("neutralize_overload"):
					BoosterSystem.cast_rest_shield(b, prog, sim_rng, 2)
				if int(prog.get("care_energy", 0)) >= BoosterSystem.COST_FRUIT_SPARK:
					BoosterSystem.cast_fruit_spark(b, lv, prog, sim_rng)
				var chosen := _pick_smart_bot_chain(b, lv, prog, bal)
				if chosen.is_empty():
					break
				var res := ChainResolver.resolve_turn(b, chosen, lv, prog, sim_rng, bal)
				moves_used += 1
				status = str(res.get("status", "continue"))

			if status == "win":
				wins += 1
				if run_idx == 0:
					canonical_won = true
			total_moves_used += moves_used
			total_score_sum += int(prog.get("score", 0))

		var win_rate := float(wins) / 3.0
		_assert_true(canonical_won, "Level %d canonical seed solvable by smart bot" % i)
		_assert_true(win_rate >= 0.66, "Level %d bot win rate >= 66%% (got %.0f%%)" % [i, win_rate * 100.0])
		if wins == 3:
			all_pass += 1

		var avg_m := float(total_moves_used) / 3.0
		var budget := maxi(1, int(lv.get("moves", 1)))
		ratio_sum += avg_m / float(budget)
		var avg_s := int(round(float(total_score_sum) / 3.0))
		var st_arr: Array = lv.get("star_thresholds", [1000, 2000, 3000])
		if avg_s >= int(st_arr[2]):
			star3_hits += 1

		report_levels.append({
			"level_id": i,
			"chapter": int(lv.get("chapter", 1)),
			"title_en": lv.get("title_en", ""),
			"wins_of_3": wins,
			"win_rate": snappedf(win_rate, 0.01),
			"canonical_seed_won": canonical_won,
			"avg_moves_used": snappedf(avg_m, 0.1),
			"move_budget": budget,
			"move_usage_pct": snappedf((avg_m / float(budget)) * 100.0, 0.1),
			"avg_score": avg_s,
			"star_thresholds": st_arr
		})

	var avg_pct := (ratio_sum / 100.0) * 100.0
	print("100-Level Simulation Complete: %d/100 levels won 3/3 runs; avg move usage %.1f%%; %d/100 hit 3-star bar." % [all_pass, avg_pct, star3_hits])
	var out_report := {
		"generated_by": "tests/test_suite.gd",
		"total_levels": 100,
		"runs_per_level": 3,
		"perfect_100pct_levels": all_pass,
		"avg_move_usage_pct": snappedf(avg_pct, 0.1),
		"bot_3star_levels": star3_hits,
		"levels": report_levels
	}
	var rf := FileAccess.open("res://docs/sim_logs/level_verification_report.json", FileAccess.WRITE)
	if rf != null:
		rf.store_string(JSON.stringify(out_report, "\t", true))
		rf.close()


func _pick_smart_bot_chain(board: BoardState, lv: Dictionary, prog: Dictionary, bal: Dictionary) -> Array[Vector2i]:
	var candidates := _enumerate_candidate_chains(board, 9)
	if candidates.is_empty():
		return []

	var objs: Dictionary = lv.get("objectives", {})
	var col_req: Dictionary = objs.get("collect", {})
	var col_prog: Dictionary = prog.get("collected", {})
	var need_care := int(objs.get("activate_care", 0)) > int(prog.get("care_activated", 0))
	var need_neutralize := int(objs.get("neutralize_overload", 0)) > int(prog.get("overloads_neutralized", 0))
	var need_long := int(objs.get("long_chains", 0)) > int(prog.get("long_chains", 0))
	var shields := int(prog.get("shield_charges", 0))
	var pulse := int(prog.get("pulse_meter", 100))

	var best_chain: Array[Vector2i] = candidates[0]
	var best_score := -999999.0

	for ch in candidates:
		var organ := str(board.get_cell(ch[0]).get("organ", ""))
		var prev := PulseSystem.preview_endpoint(board, ch, shields, pulse, bal)
		var sc := float(ch.size()) * 14.0

		if col_req.has(organ):
			var rem := int(col_req[organ]) - int(col_prog.get(organ, 0))
			if rem > 0:
				sc += float(mini(ch.size(), rem)) * 45.0

		if need_long and ch.size() >= 5:
			sc += 220.0

		var care_hits := int(prev.get("care_hits", 0))
		var blocked := int(prev.get("overload_blocked", 0))
		var danger := int(prev.get("overload_unshielded", 0))

		if care_hits > 0:
			sc += (260.0 if (need_care or (need_neutralize and shields == 0)) else 95.0) * float(care_hits)
		if blocked > 0:
			sc += (320.0 if need_neutralize else 110.0) * float(blocked)
		if danger > 0:
			sc -= 380.0 * float(danger)

		if sc > best_score:
			best_score = sc
			best_chain = ch

	return best_chain


func _enumerate_candidate_chains(board: BoardState, max_depth: int = 8) -> Array[Array]:
	var results: Array[Array] = []
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			var p := Vector2i(c, r)
			if not ChainValidator.can_start_at(board, p):
				continue
			var organ := str(board.get_cell(p).get("organ", ""))
			var path: Array[Vector2i] = [p]
			var used := {p: true}
			_dfs_collect(board, organ, path, used, results, max_depth)
	return results


func _dfs_collect(board: BoardState, organ: String, path: Array[Vector2i], used: Dictionary, results: Array[Array], max_depth: int) -> void:
	if path.size() >= 3:
		results.append(path.duplicate())
	if path.size() >= max_depth or results.size() > 500:
		return
	var cur: Vector2i = path[path.size() - 1]
	var tries := 0
	for nb in BoardState.get_orthogonal_neighbors(cur):
		if used.has(nb):
			continue
		var nc := board.get_cell(nb)
		if nc.get("kind", "") == "organ" and int(nc.get("restricted_turns", 0)) <= 0 and str(nc.get("organ", "")) == organ:
			used[nb] = true
			path.append(nb)
			_dfs_collect(board, organ, path, used, results, max_depth)
			path.pop_back()
			used.erase(nb)
			tries += 1
			if tries >= 2 and path.size() >= 4:
				break


func _test_harmony_fever_mode() -> void:
	BoardState.set_difficulty_grid("hard")
	var b := BoardState.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2301
	var lv := {
		"id": 9901,
		"moves": 12,
		"objectives": {"score": 999999},
		"star_thresholds": [500, 1000, 1500],
		"weights": {"heart": 50, "brain": 50}
	}
	var prog := LevelManager.create_initial_progress(lv)
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			b.set_organ(Vector2i(c, r), "brain")
	# 4-tile heart chain -> +1 Fever charge
	for x in range(4):
		b.set_organ(Vector2i(x, 0), "heart")
	var ch4: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	var r1 := ChainResolver.resolve_turn(b, ch4, lv, prog, rng, _game_mgr.config.get("balance", {}))
	_assert_true(bool(r1.get("committed", false)), "4-tile chain commits cleanly")
	_assert_eq(int(prog.get("fever_charge", 0)), 1, "4-tile chain adds +1 Harmony Fever charge")
	_assert_true(not bool(r1.get("fever_triggered", false)), "Fever not triggered at 1/3 charge")
	_assert_eq(int(prog.get("best_chain_len", 0)), 4, "best_chain_len records 4")

	# Closed 5-step Nadi Loop -> +2 Fever charge -> hits 3/3 and triggers 2 turns of Harmony Fever
	b.set_organ(Vector2i(1, 3), "heart")
	b.set_organ(Vector2i(2, 3), "heart")
	b.set_organ(Vector2i(2, 4), "heart")
	b.set_organ(Vector2i(1, 4), "heart")
	var loop_ch: Array[Vector2i] = [Vector2i(1, 3), Vector2i(2, 3), Vector2i(2, 4), Vector2i(1, 4), Vector2i(1, 3)]
	var r2 := ChainResolver.resolve_turn(b, loop_ch, lv, prog, rng, _game_mgr.config.get("balance", {}))
	_assert_true(bool(r2.get("fever_triggered", false)), "Loop reaching 3/3 charge triggers Harmony Fever")
	_assert_eq(int(prog.get("fever_turns", 0)), 2, "Harmony Fever grants 2 active turns")
	_assert_eq(int(prog.get("fever_activations", 0)), 1, "fever_activations incremented to 1")
	_assert_eq(int(prog.get("fever_charge", 0)), 0, "fever_charge resets to 0 on activation")

	# Next turn during Fever: 2.0x score + 1 bonus matching organ tile cleared + turns decrement to 1
	b.set_organ(Vector2i(0, 6), "heart")
	b.set_organ(Vector2i(1, 6), "heart")
	b.set_organ(Vector2i(2, 6), "heart")
	b.set_organ(Vector2i(5, 8), "heart")
	var ch3: Array[Vector2i] = [Vector2i(0, 6), Vector2i(1, 6), Vector2i(2, 6)]
	var r3 := ChainResolver.resolve_turn(b, ch3, lv, prog, rng, _game_mgr.config.get("balance", {}))
	_assert_true(bool(r3.get("fever_active", false)), "Turn executed during active Harmony Fever")
	_assert_true(r3.get("fever_bonus_clears", []).size() >= 1, "Harmony Fever pops +1 bonus matching organ tile")
	_assert_eq(int(prog.get("fever_turns", 0)), 1, "Harmony Fever turns decrement from 2 to 1")

	# 6-tile chain triggers Vitality Burst 3x3 shockwave around endpoint
	for r in range(BoardState.ROWS):
		for c in range(BoardState.COLS):
			b.set_organ(Vector2i(c, r), "brain")
	var ch6: Array[Vector2i] = [
		Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
		Vector2i(3, 2), Vector2i(3, 3), Vector2i(3, 4)
	]
	for p in ch6:
		b.set_organ(p, "heart")
	var r6 := ChainResolver.resolve_turn(b, ch6, lv, prog, rng, _game_mgr.config.get("balance", {}))
	_assert_true(bool(r6.get("vitality_burst_triggered", false)), "6+ chain triggers Vitality Burst 3x3 shockwave")
	_assert_true(r6.get("vitality_burst_cells", []).size() >= 3, "Vitality Burst clears surrounding 3x3 organ tiles")


func _test_second_wind_revival() -> void:
	var lv := {"id": 9902, "moves": 10, "objectives": {"score": 1000}, "star_thresholds": [500, 1000, 1500]}
	var prog := LevelManager.create_initial_progress(lv)
	prog["moves_left"] = 0
	prog["pulse_meter"] = 20
	prog["shield_charges"] = 0

	var res1 := BoosterSystem.apply_second_wind(prog, 100, 2)
	_assert_true(bool(res1.get("used", false)), "First Second Wind revival succeeds")
	_assert_eq(int(prog.get("moves_left", 0)), 3, "Second Wind adds +3 moves")
	_assert_eq(int(prog.get("pulse_meter", 0)), 45, "Second Wind restores +25 pulse")
	_assert_eq(int(prog.get("shield_charges", 0)), 1, "Second Wind grants +1 shield")
	_assert_true(bool(prog.get("second_wind_used", false)), "second_wind_used flag set to true")

	var res2 := BoosterSystem.apply_second_wind(prog, 100, 2)
	_assert_true(not bool(res2.get("used", false)), "Second Wind cannot be used twice on the same stage")
	_assert_eq(str(res2.get("reason", "")), "already_used", "Second Wind returns already_used reason")
	_assert_eq(int(prog.get("moves_left", 0)), 3, "Moves unchanged on rejected second revival")


func _test_daily_quests_star_chests_and_rank() -> void:
	var tmp_path := "user://test_nadiloopa_v23_quests.json"
	var tmp_bak := tmp_path + ".bak"
	_save_mgr.set_test_save_path(tmp_path)
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))
	if FileAccess.file_exists(tmp_bak):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_bak))

	_save_mgr.data = _save_mgr.create_default_data()
	_save_mgr.save_to_disk()
	_assert_eq(_save_mgr.get_sanctuary_charms(), 2, "New profile starts with 2 Sanctuary Charms")
	var r0: Dictionary = _save_mgr.get_sanctuary_rank()
	_assert_eq(int(r0.get("rank", 0)), 1, "New profile starts at Sanctuary Rank 1")
	_assert_eq(str(r0.get("tier_key", "")), "RANK_SEEDLING", "Rank 1 tier is RANK_SEEDLING")
	_assert_true(_save_mgr.is_board_theme_unlocked("garden"), "Garden theme unlocked at Rank 1")
	_assert_true(not _save_mgr.is_board_theme_unlocked("sunset"), "Sunset theme locked at Rank 1")

	var test_date := "2026-11-18"
	_save_mgr.record_daily_quest_progress(test_date, 35, 2, 6)
	_assert_eq(_save_mgr.get_unclaimed_rewards_count(test_date), 3, "All 3 Daily Quests become claimable")
	_assert_true(_save_mgr.claim_daily_quest(test_date, 0), "Claim Daily Quest 0 succeeds")
	_assert_true(not _save_mgr.claim_daily_quest(test_date, 0), "Duplicate Daily Quest 0 claim rejected")
	_assert_true(_save_mgr.claim_daily_quest(test_date, 1), "Claim Daily Quest 1 succeeds")
	_assert_true(_save_mgr.claim_daily_quest(test_date, 2), "Claim Daily Quest 2 succeeds")
	_assert_eq(_save_mgr.get_sanctuary_charms(), 5, "Claiming 3 daily quests grants +3 Charms (total 5)")

	# Earn 15 campaign stars (5 levels x 3 stars) to unlock Star Milestone Chest
	for lid in range(1, 6):
		_save_mgr.record_level_win(lid, 3, 2500)
	var chest: Dictionary = _save_mgr.get_star_chest_info()
	_assert_true(bool(chest.get("claimable", false)), "Star Milestone Chest unlocks at 15 stars")
	_assert_true(_save_mgr.claim_star_chest(), "Claim Star Milestone Chest succeeds")
	_assert_eq(_save_mgr.get_sanctuary_charms(), 7, "Star Chest grants +2 Charms (total 7)")
	_assert_eq(int(_save_mgr.get_star_chest_info().get("next_milestone", 0)), 30, "Next Star Chest milestone advances to 30")

	_assert_true(_save_mgr.spend_sanctuary_charm(), "Spend 1 Sanctuary Charm succeeds")
	_assert_eq(_save_mgr.get_sanctuary_charms(), 6, "Sanctuary Charms decrements to 6")

	# Verify Sunset theme unlocks at Rank 3+, and haptics/board_theme persist with checksum
	_save_mgr.set_setting("haptics", false)
	_save_mgr.set_setting("board_theme", "sunset")
	_save_mgr.load_save()
	_assert_true(not _save_mgr.last_load_recovered_from_corruption, "v2.4 save data passes SHA-256 checksum cleanly")
	_assert_eq(_save_mgr.get_sanctuary_charms(), 6, "Sanctuary Charms persists across reload")
	_assert_eq(bool(_save_mgr.get_setting("haptics", true)), false, "Haptics setting persists across reload")
	_assert_eq(str(_save_mgr.get_setting("board_theme", "garden")), "sunset", "Board theme setting persists across reload")
	var r1: Dictionary = _save_mgr.get_sanctuary_rank()
	_assert_true(int(r1.get("rank", 1)) >= 3, "Sanctuary Rank advances with campaign stars")
	_assert_true(_save_mgr.is_board_theme_unlocked("sunset"), "Sunset theme unlocks at Rank 3+")

	# Cleanup isolated test save files
	_save_mgr.clear_test_save_path()
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))
	if FileAccess.file_exists(tmp_bak):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_bak))
	_save_mgr.load_save()

