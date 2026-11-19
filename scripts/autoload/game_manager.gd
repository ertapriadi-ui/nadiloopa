extends Node
## Global configuration and game state coordinator.

const CONFIG_PATH: String = "res://data/game_config.json"

enum PlayState {
	MENU,
	READY,
	SELECTING,
	RESOLVING,
	REFILLING,
	WIN,
	LOSE,
	PAUSED
}

var config: Dictionary = {}
var play_state: PlayState = PlayState.MENU
var current_level_id: int = 1


func _ready() -> void:
	load_config()


func load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		config = _fallback_config()
		return
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		config = parsed
	else:
		config = _fallback_config()


func _fallback_config() -> Dictionary:
	return {
		"codename": "NADILOOPA",
		"version": "1.0.0",
		"grid": {"cols": 7, "rows": 12, "min_chain_length": 3},
		"balance": {
			"initial_pulse": 100,
			"max_pulse": 100,
			"overload_pulse_penalty": 10,
			"overload_restrict_max_cells": 2,
			"overload_restrict_turns": 1,
			"care_pulse_restore": 8,
			"care_shield_max": 2,
			"care_score_bonus": 150,
			"overload_neutralize_bonus": 120,
			"base_tile_score": 25,
			"long_chain_threshold": 5,
			"remaining_move_bonus": 120
		}
	}


func get_balance(key: String, default_val: int) -> int:
	var b: Dictionary = config.get("balance", {})
	return int(b.get(key, default_val))


func is_reduce_motion() -> bool:
	return bool(SaveManager.get_setting("reduce_motion", false))


func is_screen_shake_enabled() -> bool:
	if is_reduce_motion():
		return false
	return bool(SaveManager.get_setting("screen_shake", true))


func is_haptics_enabled() -> bool:
	return bool(SaveManager.get_setting("haptics", true))


func trigger_haptic(duration_ms: int = 12) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not is_haptics_enabled():
		return
	Input.vibrate_handheld(clampi(duration_ms, 5, 120))

