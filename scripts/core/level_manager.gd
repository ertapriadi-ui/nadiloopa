class_name LevelManager
extends RefCounted
## Loads all 100 campaign levels plus generates Endless Zen waves and Daily Sanctuary stages.

const LEVELS_PATH: String = "res://data/levels/levels_v1.json"

var levels: Array[Dictionary] = []


func _init() -> void:
	load_levels()


func load_levels() -> void:
	levels.clear()
	if not FileAccess.file_exists(LEVELS_PATH):
		push_error("Missing levels file: %s" % LEVELS_PATH)
		return
	var f := FileAccess.open(LEVELS_PATH, FileAccess.READ)
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid levels JSON root")
		return
	var arr: Variant = parsed.get("levels", [])
	if typeof(arr) == TYPE_ARRAY:
		for item in arr:
			if typeof(item) == TYPE_DICTIONARY:
				levels.append(item)


func get_level_count() -> int:
	return levels.size()


func get_level(level_id: int) -> Dictionary:
	for lv in levels:
		if int(lv.get("id", -1)) == level_id:
			return lv
	return {}


static func build_daily_level(date_dict: Dictionary) -> Dictionary:
	var y := int(date_dict.get("year", 2026))
	var m := int(date_dict.get("month", 11))
	var d := int(date_dict.get("day", 18))
	var day_seed := y * 10000 + m * 100 + d
	var drng := RandomNumberGenerator.new()
	drng.seed = day_seed
	var organs: Array = BoardState.ORGANS.duplicate()
	for i in range(organs.size() - 1, 0, -1):
		var j := drng.randi_range(0, i)
		var tmp: String = str(organs[i])
		organs[i] = organs[j]
		organs[j] = tmp
	var o1: String = str(organs[0])
	var o2: String = str(organs[1])
	var w := {o1: 30, o2: 28, organs[2]: 21, organs[3]: 21}
	return {
		"id": 9001,
		"mode": "daily",
		"daily_date": "%04d-%02d-%02d" % [y, m, d],
		"title_en": "Daily Sanctuary (%02d/%02d)" % [m, d],
		"title_id": "Suaka Harian (%02d/%02d)" % [d, m],
		"is_boss": false,
		"seed": day_seed,
		"moves": 22,
		"initial_pulse": 100,
		"weights": w,
		"objectives": {"collect": {o1: 18, o2: 16}, "neutralize_overload": 2},
		"care_positions": [[1, 3], [5, 3], [2, 8], [4, 8]],
		"overload_positions": [[3, 4], [2, 6], [4, 6]],
		"armored_overload_positions": [[3, 8]],
		"bloom_positions": [[1, 6], [5, 6]],
		"min_care_on_board": 3,
		"min_overload_on_board": 2,
		"star_thresholds": [2800, 4200, 5800]
	}


static func build_endless_wave_def(wave: int, base_seed: int = 80000) -> Dictionary:
	var organs: Array = BoardState.ORGANS.duplicate()
	var erng := RandomNumberGenerator.new()
	erng.seed = base_seed + wave * 97
	for i in range(organs.size() - 1, 0, -1):
		var j := erng.randi_range(0, i)
		var tmp: String = str(organs[i])
		organs[i] = organs[j]
		organs[j] = tmp
	var o1: String = str(organs[0])
	var o2: String = str(organs[1])
	var target1 := 14 + mini(18, wave * 2)
	var target2 := 12 + mini(16, wave * 2)
	return {
		"id": 8000 + wave,
		"mode": "endless",
		"wave": wave,
		"title_en": "Zen Wave %d" % wave,
		"title_id": "Gelombang Zen %d" % wave,
		"is_boss": (wave % 5 == 0),
		"seed": base_seed + wave * 97,
		"moves": 18,
		"initial_pulse": 100,
		"weights": {o1: 30, o2: 28, organs[2]: 21, organs[3]: 21},
		"objectives": {"collect": {o1: target1, o2: target2}},
		"care_positions": [[1, 4], [5, 4], [3, 8]],
		"overload_positions": [[2, 5], [4, 5]] if wave == 1 else [[2, 5], [4, 5], [3, 7]],
		"armored_overload_positions": [[3, 4]] if wave >= 3 else [],
		"bloom_positions": [[1, 7], [5, 7]] if wave >= 2 else [[3, 6]],
		"min_care_on_board": 2,
		"min_overload_on_board": 2,
		"star_thresholds": [2000, 3500, 5000]
	}


static func build_board_for_level(level_def: Dictionary, rng: RandomNumberGenerator) -> BoardState:
	var board := BoardState.new()
	var weights: Dictionary = level_def.get("weights", {"heart": 25, "brain": 25, "lungs": 25, "kidneys": 25})
	board.populate_initial(
		rng,
		weights,
		level_def.get("care_positions", []),
		level_def.get("overload_positions", []),
		level_def.get("armored_overload_positions", []),
		level_def.get("bloom_positions", [])
	)
	return board


static func create_initial_progress(level_def: Dictionary) -> Dictionary:
	return {
		"collected": {"heart": 0, "brain": 0, "lungs": 0, "kidneys": 0, "stomach": 0, "liver": 0, "muscle": 0},
		"score": 0,
		"care_activated": 0,
		"overloads_neutralized": 0,
		"long_chains": 0,
		"loops_formed": 0,
		"combo_streak": 0,
		"care_energy": 25 if int(level_def.get("id", 1)) > 2 else 0,
		"pulse_meter": int(level_def.get("initial_pulse", 100)),
		"shield_charges": 0,
		"moves_left": int(level_def.get("moves", 16))
	}


static func are_objectives_complete(level_def: Dictionary, progress: Dictionary) -> bool:
	var objs: Dictionary = level_def.get("objectives", {})
	if objs.has("collect"):
		var col_req: Dictionary = objs["collect"]
		var col_prog: Dictionary = progress.get("collected", {})
		for organ in col_req.keys():
			if int(col_prog.get(organ, 0)) < int(col_req[organ]):
				return false
	if objs.has("score"):
		if int(progress.get("score", 0)) < int(objs["score"]):
			return false
	if objs.has("activate_care"):
		if int(progress.get("care_activated", 0)) < int(objs["activate_care"]):
			return false
	if objs.has("neutralize_overload"):
		if int(progress.get("overloads_neutralized", 0)) < int(objs["neutralize_overload"]):
			return false
	if objs.has("long_chains"):
		if int(progress.get("long_chains", 0)) < int(objs["long_chains"]):
			return false
	if objs.has("keep_pulse"):
		if int(progress.get("pulse_meter", 0)) < int(objs["keep_pulse"]):
			return false
	return true


static func validate_level_schema(level_def: Dictionary) -> Array[String]:
	var errs: Array[String] = []
	for req in ["id", "title_en", "title_id", "seed", "moves", "objectives", "weights", "star_thresholds"]:
		if not level_def.has(req):
			errs.append("Missing field: %s" % req)
	for pos_key in ["care_positions", "overload_positions", "armored_overload_positions", "bloom_positions"]:
		for rp in level_def.get(pos_key, []):
			if typeof(rp) != TYPE_ARRAY or rp.size() < 2:
				errs.append("Invalid position in %s" % pos_key)
			else:
				var p := Vector2i(int(rp[0]), int(rp[1]))
				if p.x < 0 or p.x >= 7 or p.y < 0 or p.y >= 12:
					errs.append("Out of canonical 7x12 bounds %s: %s" % [pos_key, str(p)])
	return errs
