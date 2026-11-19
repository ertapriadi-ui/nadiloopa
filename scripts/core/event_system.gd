class_name EventSystem
extends RefCounted
## Dynamic Dangerous Health Events representing real-world risks to the body's owner:
## Wildfire Haze, Junk Food Feast, Binge Drinking, All-Nighter, Screen Marathon, and Smoke Wave.

const EVENT_IDS: Array[String] = [
	"wildfire_haze",
	"junk_feast",
	"binge_drinking",
	"all_nighter",
	"screen_marathon",
	"smoke_wave"
]

const EVENT_CATALOG := {
	"wildfire_haze": {
		"title_key": "EVENT_WILDFIRE_TITLE",
		"desc_key": "EVENT_WILDFIRE_DESC",
		"sprite": "res://assets/sprites/events/event_wildfire_haze.png",
		"sfx_extra": "event_fire",
		"accent": Color(0.96, 0.38, 0.14),
		"score_penalty": 180,
		"pulse_penalty": 4,
		"energy_penalty": 0,
		"lock_count": 1,
		"lock_organs": ["lungs", "heart"],
		"spawn_hazard": "cigarette_smoke"
	},
	"junk_feast": {
		"title_key": "EVENT_JUNK_TITLE",
		"desc_key": "EVENT_JUNK_DESC",
		"sprite": "res://assets/sprites/events/event_junk_feast.png",
		"sfx_extra": "hazard_trigger",
		"accent": Color(0.96, 0.24, 0.24),
		"score_penalty": 150,
		"pulse_penalty": 4,
		"energy_penalty": 0,
		"lock_count": 1,
		"lock_organs": ["stomach", "liver"],
		"spawn_hazard": "fast_food"
	},
	"binge_drinking": {
		"title_key": "EVENT_DRINK_TITLE",
		"desc_key": "EVENT_DRINK_DESC",
		"sprite": "res://assets/sprites/events/event_binge_drinking.png",
		"sfx_extra": "event_dizzy",
		"accent": Color(0.76, 0.22, 0.88),
		"score_penalty": 220,
		"pulse_penalty": 6,
		"energy_penalty": 8,
		"lock_count": 2,
		"lock_organs": ["liver", "kidneys", "brain"],
		"spawn_hazard": ""
	},
	"all_nighter": {
		"title_key": "EVENT_NIGHT_TITLE",
		"desc_key": "EVENT_NIGHT_DESC",
		"sprite": "res://assets/sprites/events/event_all_nighter.png",
		"sfx_extra": "event_dizzy",
		"accent": Color(0.32, 0.36, 0.92),
		"score_penalty": 160,
		"pulse_penalty": 4,
		"energy_penalty": 15,
		"lock_count": 2,
		"lock_organs": ["brain", "heart"],
		"spawn_hazard": ""
	},
	"screen_marathon": {
		"title_key": "EVENT_SCREEN_TITLE",
		"desc_key": "EVENT_SCREEN_DESC",
		"sprite": "res://assets/sprites/events/event_screen_marathon.png",
		"sfx_extra": "event_dizzy",
		"accent": Color(0.14, 0.72, 0.96),
		"score_penalty": 150,
		"pulse_penalty": 3,
		"energy_penalty": 10,
		"lock_count": 2,
		"lock_organs": ["muscle", "brain"],
		"spawn_hazard": "sugary_drink"
	},
	"smoke_wave": {
		"title_key": "EVENT_SMOKE_TITLE",
		"desc_key": "EVENT_SMOKE_DESC",
		"sprite": "res://assets/sprites/events/event_smoke_wave.png",
		"sfx_extra": "event_fire",
		"accent": Color(0.58, 0.56, 0.64),
		"score_penalty": 140,
		"pulse_penalty": 5,
		"energy_penalty": 0,
		"lock_count": 1,
		"lock_organs": ["lungs", "heart"],
		"spawn_hazard": "cigarette_smoke"
	}
}


static func get_empty_event() -> Dictionary:
	return {
		"triggered": false,
		"id": "",
		"title_key": "",
		"desc_key": "",
		"sprite": "",
		"sfx_extra": "",
		"accent": Color(0.95, 0.36, 0.16),
		"score_lost": 0,
		"pulse_lost": 0,
		"energy_lost": 0,
		"locked_cells": [],
		"spawned_hazards": []
	}


static func maybe_trigger_event(board: BoardState, level_def: Dictionary, progress: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var level_id := int(level_def.get("id", 1))
	var is_special_mode := bool(level_def.get("is_endless", false)) or bool(level_def.get("is_daily", false))
	if level_id < 3 and not is_special_mode:
		return get_empty_event()

	var turns_taken := int(progress.get("turns_taken", 0))
	if turns_taken <= 0 or (turns_taken % 6) != 0:
		return get_empty_event()

	# Deterministic varied selection avoiding back-to-back repeat
	var last_id := str(progress.get("last_health_event", ""))
	var pool: Array[String] = []
	for eid in EVENT_IDS:
		if eid != last_id:
			pool.append(eid)
	if pool.is_empty():
		pool = EVENT_IDS.duplicate()
	var pick_idx := rng.randi_range(0, pool.size() - 1) if rng != null else (turns_taken % pool.size())
	var chosen_id: String = pool[pick_idx]
	return trigger_event(board, chosen_id, progress, rng)


static func trigger_event(board: BoardState, event_id: String, progress: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if board == null or not EVENT_CATALOG.has(event_id):
		return get_empty_event()

	var cfg: Dictionary = EVENT_CATALOG[event_id]
	var cur_score := int(progress.get("score", 0))
	var score_lost := mini(cur_score, int(cfg.get("score_penalty", 0)))
	progress["score"] = maxi(0, cur_score - score_lost)

	# Shield mitigates half of pulse loss without breaking the shield
	var raw_pulse_pen := int(cfg.get("pulse_penalty", 0))
	if int(progress.get("shield_charges", 0)) > 0 and raw_pulse_pen > 1:
		raw_pulse_pen = int(ceil(float(raw_pulse_pen) * 0.5))
	var cur_pulse := int(progress.get("pulse_meter", 100))
	# Never kill the player solely from a random health event (keep >= 5 pulse)
	var new_pulse := maxi(mini(cur_pulse, 5), cur_pulse - raw_pulse_pen)
	var pulse_lost := maxi(0, cur_pulse - new_pulse)
	progress["pulse_meter"] = new_pulse

	var cur_energy := int(progress.get("care_energy", 0))
	var energy_lost := mini(cur_energy, int(cfg.get("energy_penalty", 0)))
	progress["care_energy"] = maxi(0, cur_energy - energy_lost)

	# Lock preferred organ tiles (fallback to any unlocked organ)
	var lock_count := int(cfg.get("lock_count", 0))
	var preferred_organs: Array = cfg.get("lock_organs", [])
	var locked_cells: Array[Vector2i] = []
	if lock_count > 0:
		var pref_candidates: Array[Vector2i] = []
		var any_candidates: Array[Vector2i] = []
		for r in range(BoardState.ROWS):
			for c in range(BoardState.COLS):
				var p := Vector2i(c, r)
				var cell := board.get_cell(p)
				if str(cell.get("kind", "")) == "organ" and int(cell.get("restricted_turns", 0)) <= 0:
					any_candidates.append(p)
					if preferred_organs.has(str(cell.get("organ", ""))):
						pref_candidates.append(p)
		var source_list: Array[Vector2i] = pref_candidates if not pref_candidates.is_empty() else any_candidates
		while locked_cells.size() < lock_count and not source_list.is_empty():
			var idx_pick := rng.randi_range(0, source_list.size() - 1) if rng != null else 0
			var target: Vector2i = source_list[idx_pick]
			source_list.remove_at(idx_pick)
			var bidx := BoardState.idx(target.x, target.y)
			board.cells[bidx]["restricted_turns"] = 2
			board.cells[bidx]["newly_restricted"] = true
			locked_cells.append(target)

	# Optionally convert 1 unlocked organ into a thematic hazard if board has < 3 overloads
	var spawned_hazards: Array[Vector2i] = []
	var spawn_htype := str(cfg.get("spawn_hazard", ""))
	if spawn_htype != "" and board.count_kind("overload") < 3:
		var open_organs: Array[Vector2i] = []
		for r in range(BoardState.ROWS):
			for c in range(BoardState.COLS):
				var p := Vector2i(c, r)
				var cell := board.get_cell(p)
				if str(cell.get("kind", "")) == "organ" and int(cell.get("restricted_turns", 0)) <= 0:
					# Avoid placing directly adjacent to 2+ existing overloads to prevent unfair instant wipe
					var adj_ov := 0
					for nb in BoardState.get_8way_neighbors(p):
						if str(board.get_cell(nb).get("kind", "")) == "overload":
							adj_ov += 1
					if adj_ov == 0:
						open_organs.append(p)
		if not open_organs.is_empty():
			var s_idx := rng.randi_range(0, open_organs.size() - 1) if rng != null else 0
			var sp: Vector2i = open_organs[s_idx]
			board.set_special(sp, "overload", 1, spawn_htype)
			spawned_hazards.append(sp)

	progress["last_health_event"] = event_id
	progress["health_events_triggered"] = int(progress.get("health_events_triggered", 0)) + 1

	return {
		"triggered": true,
		"id": event_id,
		"title_key": str(cfg.get("title_key", "")),
		"desc_key": str(cfg.get("desc_key", "")),
		"sprite": str(cfg.get("sprite", "")),
		"sfx_extra": str(cfg.get("sfx_extra", "hazard_trigger")),
		"accent": cfg.get("accent", Color(0.95, 0.36, 0.16)),
		"score_lost": score_lost,
		"pulse_lost": pulse_lost,
		"energy_lost": energy_lost,
		"locked_cells": locked_cells,
		"spawned_hazards": spawned_hazards
	}
