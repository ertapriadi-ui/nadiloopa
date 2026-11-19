extends Node
## Versioned local save persistence (100 levels, Endless, Daily Streak, Achievements, backup & corrupt recovery).

signal progress_changed
signal settings_changed

const SCHEMA_VERSION: int = 2
const MAX_LEVELS: int = 100
const SAVE_PATH: String = "user://nadiloopa_save_v1.json"
const BACKUP_PATH: String = "user://nadiloopa_save_v1.bak.json"

var data: Dictionary = {}
var last_load_recovered_from_corruption: bool = false
var _save_path_override: String = ""


func _ready() -> void:
	load_save()


func get_save_path() -> String:
	return _save_path_override if _save_path_override != "" else SAVE_PATH


func get_backup_path() -> String:
	if _save_path_override != "":
		return _save_path_override + ".bak"
	return BACKUP_PATH


func set_test_save_path(path: String) -> void:
	_save_path_override = path


func clear_test_save_path() -> void:
	_save_path_override = ""


func create_default_data() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"checksum": "",
		"unlocked_level": 1,
		"level_stars": {},
		"level_best_scores": {},
		"best_endless_wave": 0,
		"best_endless_score": 0,
		"daily_streak": 0,
		"last_daily_date": "",
		"achievements": {},
		"stats": {
			"total_chains": 0,
			"total_loops": 0,
			"total_abilities_used": 0,
			"total_overloads_cleared": 0
		},
		"settings": {
			"language": "en",
			"difficulty": "hard",
			"music_volume": 0.78,
			"sfx_volume": 0.85,
			"music_muted": false,
			"sfx_muted": false,
			"reduce_motion": false,
			"screen_shake": true
		}
	}


func _compute_checksum(payload: Dictionary) -> String:
	var s: Dictionary = payload.get("settings", {})
	var st_dict: Dictionary = payload.get("stats", {})
	var parts := PackedStringArray([
		"v=%d" % int(payload.get("schema_version", SCHEMA_VERSION)),
		"u=%d" % clampi(int(payload.get("unlocked_level", 1)), 1, MAX_LEVELS),
		"ew=%d" % maxi(0, int(payload.get("best_endless_wave", 0))),
		"es=%d" % maxi(0, int(payload.get("best_endless_score", 0))),
		"ds=%d" % maxi(0, int(payload.get("daily_streak", 0))),
		"dd=%s" % str(payload.get("last_daily_date", "")),
		"stc=%d:%d:%d:%d" % [
			int(st_dict.get("total_chains", 0)),
			int(st_dict.get("total_loops", 0)),
			int(st_dict.get("total_abilities_used", 0)),
			int(st_dict.get("total_overloads_cleared", 0))
		],
		"lang=%s" % str(s.get("language", "en")),
		"mv=%d" % roundi(float(s.get("music_volume", 0.78)) * 1000.0),
		"sv=%d" % roundi(float(s.get("sfx_volume", 0.85)) * 1000.0),
		"mm=%d" % (1 if bool(s.get("music_muted", false)) else 0),
		"sm=%d" % (1 if bool(s.get("sfx_muted", false)) else 0),
		"rm=%d" % (1 if bool(s.get("reduce_motion", false)) else 0),
		"ss=%d" % (1 if bool(s.get("screen_shake", true)) else 0),
	])
	if s.has("difficulty"):
		parts.append("diff=%s" % str(s.get("difficulty", "hard")))
	var stars_in: Variant = payload.get("level_stars", {})
	var scores_in: Variant = payload.get("level_best_scores", {})
	for lid in range(1, MAX_LEVELS + 1):
		var k := str(lid)
		var st := int(stars_in.get(k, 0)) if typeof(stars_in) == TYPE_DICTIONARY else 0
		var sc := int(scores_in.get(k, 0)) if typeof(scores_in) == TYPE_DICTIONARY else 0
		if st > 0 or sc > 0:
			parts.append("L%d:%d:%d" % [lid, st, sc])
	var ach_in: Variant = payload.get("achievements", {})
	if typeof(ach_in) == TYPE_DICTIONARY:
		var ach_dict: Dictionary = ach_in
		var ak: Array = ach_dict.keys()
		ak.sort()
		for a_id in ak:
			if bool(ach_dict[a_id]):
				parts.append("A:%s" % str(a_id))
	return "|".join(parts).sha256_text()


func _validate_and_normalize(raw_dict: Variant) -> Dictionary:
	if typeof(raw_dict) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = raw_dict
	var sv := int(d.get("schema_version", -1))
	if sv != 1 and sv != SCHEMA_VERSION:
		return {}
	if not d.has("settings") or typeof(d["settings"]) != TYPE_DICTIONARY:
		return {}

	var expected_checksum: String = str(d.get("checksum", ""))
	if expected_checksum != "" and sv == SCHEMA_VERSION:
		if _compute_checksum(d) != expected_checksum:
			return {}

	var clean := create_default_data()
	clean["unlocked_level"] = clampi(int(d.get("unlocked_level", 1)), 1, MAX_LEVELS)

	var stars_in: Variant = d.get("level_stars", {})
	if typeof(stars_in) == TYPE_DICTIONARY:
		for k in stars_in.keys():
			var lid := int(k)
			if lid >= 1 and lid <= MAX_LEVELS:
				clean["level_stars"][str(lid)] = clampi(int(stars_in[k]), 0, 3)

	var scores_in: Variant = d.get("level_best_scores", {})
	if typeof(scores_in) == TYPE_DICTIONARY:
		for k in scores_in.keys():
			var lid := int(k)
			if lid >= 1 and lid <= MAX_LEVELS:
				clean["level_best_scores"][str(lid)] = maxi(0, int(scores_in[k]))

	clean["best_endless_wave"] = maxi(0, int(d.get("best_endless_wave", 0)))
	clean["best_endless_score"] = maxi(0, int(d.get("best_endless_score", 0)))
	clean["daily_streak"] = maxi(0, int(d.get("daily_streak", 0)))
	clean["last_daily_date"] = str(d.get("last_daily_date", ""))

	var ach_in: Variant = d.get("achievements", {})
	if typeof(ach_in) == TYPE_DICTIONARY:
		for k in ach_in.keys():
			if bool(ach_in[k]):
				clean["achievements"][str(k)] = true

	var st_in: Variant = d.get("stats", {})
	if typeof(st_in) == TYPE_DICTIONARY:
		for sk in ["total_chains", "total_loops", "total_abilities_used", "total_overloads_cleared"]:
			clean["stats"][sk] = maxi(0, int(st_in.get(sk, 0)))

	var s_in: Dictionary = d["settings"]
	var lang: String = str(s_in.get("language", "en"))
	if lang != "en" and lang != "id":
		lang = "en"
	clean["settings"]["language"] = lang
	var diff: String = str(s_in.get("difficulty", "hard"))
	if diff != "easy" and diff != "medium" and diff != "hard":
		diff = "hard"
	clean["settings"]["difficulty"] = diff
	clean["settings"]["music_volume"] = clampf(float(s_in.get("music_volume", 0.78)), 0.0, 1.0)
	clean["settings"]["sfx_volume"] = clampf(float(s_in.get("sfx_volume", 0.85)), 0.0, 1.0)
	clean["settings"]["music_muted"] = bool(s_in.get("music_muted", false))
	clean["settings"]["sfx_muted"] = bool(s_in.get("sfx_muted", false))
	clean["settings"]["reduce_motion"] = bool(s_in.get("reduce_motion", false))
	clean["settings"]["screen_shake"] = bool(s_in.get("screen_shake", true))
	return clean


func _try_read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	if txt.strip_edges() == "":
		return {}
	var parser := JSON.new()
	if parser.parse(txt) != OK:
		return {}
	return _validate_and_normalize(parser.data)


func load_save() -> bool:
	last_load_recovered_from_corruption = false
	var primary_path := get_save_path()
	var loaded := _try_read_file(primary_path)
	if not loaded.is_empty():
		data = loaded
		return true

	var had_primary := FileAccess.file_exists(primary_path)
	var backup := _try_read_file(get_backup_path())
	if not backup.is_empty():
		data = backup
		last_load_recovered_from_corruption = had_primary
		save_to_disk()
		return true

	data = create_default_data()
	if had_primary:
		last_load_recovered_from_corruption = true
	save_to_disk()
	return false


func save_to_disk() -> bool:
	if data.is_empty():
		data = create_default_data()
	data["schema_version"] = SCHEMA_VERSION
	data["checksum"] = _compute_checksum(data)
	var serialized := JSON.stringify(data, "\t", true)

	var primary_path := get_save_path()
	var backup_path := get_backup_path()
	if FileAccess.file_exists(primary_path):
		var existing_valid := _try_read_file(primary_path)
		if not existing_valid.is_empty():
			var fb := FileAccess.open(backup_path, FileAccess.WRITE)
			if fb != null:
				fb.store_string(JSON.stringify(existing_valid, "\t", true))
				fb.close()

	var f := FileAccess.open(primary_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(serialized)
	f.close()

	# Once primary is safely written, sync backup mirror so external primary corruption
	# recovers the complete latest committed state without losing the most recent save.
	var fm := FileAccess.open(backup_path, FileAccess.WRITE)
	if fm != null:
		fm.store_string(serialized)
		fm.close()
	return true


func record_level_win(level_id: int, stars: int, score: int) -> void:
	var key := str(level_id)
	var prev_stars := int(data["level_stars"].get(key, 0))
	data["level_stars"][key] = maxi(prev_stars, clampi(stars, 1, 3))
	var prev_score := int(data["level_best_scores"].get(key, 0))
	data["level_best_scores"][key] = maxi(prev_score, maxi(0, score))
	if level_id >= int(data.get("unlocked_level", 1)) and level_id < MAX_LEVELS:
		data["unlocked_level"] = level_id + 1
	save_to_disk()
	progress_changed.emit()


func record_endless_run(wave: int, score: int) -> void:
	data["best_endless_wave"] = maxi(int(data.get("best_endless_wave", 0)), wave)
	data["best_endless_score"] = maxi(int(data.get("best_endless_score", 0)), score)
	save_to_disk()
	progress_changed.emit()


static func _is_consecutive_day(prev_date: String, cur_date: String) -> bool:
	var p := prev_date.split("-")
	var c := cur_date.split("-")
	if p.size() != 3 or c.size() != 3:
		return false
	var p_ts := Time.get_unix_time_from_datetime_dict({"year": int(p[0]), "month": int(p[1]), "day": int(p[2]), "hour": 12, "minute": 0, "second": 0})
	var c_ts := Time.get_unix_time_from_datetime_dict({"year": int(c[0]), "month": int(c[1]), "day": int(c[2]), "hour": 12, "minute": 0, "second": 0})
	return roundi(float(c_ts - p_ts) / 86400.0) == 1


func record_daily_win(date_str: String) -> void:
	var prev_date := str(data.get("last_daily_date", ""))
	if prev_date != date_str:
		data["daily_streak"] = (int(data.get("daily_streak", 0)) + 1) if _is_consecutive_day(prev_date, date_str) else 1
		data["last_daily_date"] = date_str
		save_to_disk()
		progress_changed.emit()


func increment_stat(key: String, delta: int = 1) -> void:
	if not data.has("stats") or typeof(data["stats"]) != TYPE_DICTIONARY:
		data["stats"] = create_default_data()["stats"]
	data["stats"][key] = int(data["stats"].get(key, 0)) + delta


func unlock_achievement(ach_id: String) -> bool:
	if not data.has("achievements") or typeof(data["achievements"]) != TYPE_DICTIONARY:
		data["achievements"] = {}
	if bool(data["achievements"].get(ach_id, false)):
		return false
	data["achievements"][ach_id] = true
	save_to_disk()
	progress_changed.emit()
	return true


func has_achievement(ach_id: String) -> bool:
	return bool(data.get("achievements", {}).get(ach_id, false))


func get_unlocked_achievement_count() -> int:
	var n := 0
	for v in data.get("achievements", {}).values():
		if bool(v):
			n += 1
	return n


func reset_progress_keep_settings() -> void:
	var saved_settings: Dictionary = data.get("settings", {}).duplicate(true)
	data = create_default_data()
	if not saved_settings.is_empty():
		data["settings"] = saved_settings
	save_to_disk()
	progress_changed.emit()


func get_unlocked_level() -> int:
	return clampi(int(data.get("unlocked_level", 1)), 1, MAX_LEVELS)


func get_level_stars(level_id: int) -> int:
	return clampi(int(data["level_stars"].get(str(level_id), 0)), 0, 3)


func get_total_stars() -> int:
	var total := 0
	for v in data.get("level_stars", {}).values():
		total += int(v)
	return total


func get_level_best_score(level_id: int) -> int:
	return int(data["level_best_scores"].get(str(level_id), 0))


func get_setting(key: String, default_val: Variant = null) -> Variant:
	var s: Dictionary = data.get("settings", {})
	return s.get(key, default_val)


func set_setting(key: String, val: Variant) -> void:
	if not data.has("settings") or typeof(data["settings"]) != TYPE_DICTIONARY:
		data["settings"] = create_default_data()["settings"]
	data["settings"][key] = val
	save_to_disk()
	settings_changed.emit()
