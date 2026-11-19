extends SceneTree
## Multi-resolution visual verification & screenshot capture runner for NADILOOPA v2.0.

var _sv: SubViewport
var _main: Control
var _step: int = 0
var _wait: int = 0
var _loc_mgr: Node
var _save_mgr: Node
var _shots_dir: String = "res://screenshots/"


func _configure_viewport(phys_w: int, phys_h: int, logical_w: int, logical_h: int) -> void:
	_sv.size = Vector2i(phys_w, phys_h)
	_sv.size_2d_override = Vector2i(logical_w, logical_h)
	_sv.size_2d_override_stretch = true


func _save_shot(filename: String) -> void:
	var img := _sv.get_texture().get_image()
	var abs_path := ProjectSettings.globalize_path(_shots_dir + filename)
	var err := img.save_png(abs_path)
	var metrics: Dictionary = _main.call("get_layout_metrics")
	print("SHOT %s -> %dx%d (err=%d) metrics=%s" % [filename, img.get_width(), img.get_height(), err, str(metrics)])


func _process(_delta: float) -> bool:
	if _step == 0:
		_loc_mgr = root.get_node("LocalizationManager")
		_save_mgr = root.get_node("SaveManager")

		_sv = SubViewport.new()
		_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_sv.transparent_bg = false
		_configure_viewport(1080, 2400, 1080, 2400)
		root.add_child(_sv)

		var packed: PackedScene = load("res://scenes/main.tscn")
		_main = packed.instantiate()
		_main.set("_skip_splash", true)
		_sv.add_child(_main)

		_save_mgr.set_test_save_path("user://shot_tmp_v2.json")
		_save_mgr.load_save()
		for lid in range(1, 46):
			_save_mgr.record_level_win(lid, 3 if lid % 2 == 1 else 2, 1800 + lid * 50)
		_save_mgr.record_daily_win("2026-11-18")
		_save_mgr.unlock_achievement("ACH_FIRST_WIN")
		_save_mgr.unlock_achievement("ACH_CH1")
		_save_mgr.unlock_achievement("ACH_LOOP_1")
		_save_mgr.increment_stat("total_chains", 84)
		_save_mgr.increment_stat("total_loops", 12)
		_save_mgr.increment_stat("total_abilities_used", 9)
		_save_mgr.increment_stat("total_overloads_cleared", 27)
		_loc_mgr.set_language("en", false)
		_main.call("show_screen", "menu")
		_step = 1
		_wait = 6
		return false

	if _wait > 0:
		_wait -= 1
		return false

	match _step:
		1:
			_save_shot("01_main_menu_en_1080x2400.png")
			_main.set("_selected_chapter", 5)
			_main.call("show_screen", "levels")
			_step = 2
			_wait = 5
		2:
			_save_shot("02_level_select_1080x2400.png")
			_main.call("start_level", 46)
			_step = 3
			_wait = 6
		3:
			_save_shot("03_gameplay_board_7x12_1080x2400.png")
			# Showcase 2x2 Nadi Loop + Happy smiling organs + Bloom + Armored Overload + Tactical Dock ready!
			_main.call("start_level", 46)
			var prog: Dictionary = _main.get("progress")
			prog["care_energy"] = 85
			prog["combo_streak"] = 3
			var b: BoardState = _main.get("board_state")
			b.set_organ(Vector2i(2, 5), "heart")
			b.set_organ(Vector2i(3, 5), "heart")
			b.set_organ(Vector2i(3, 6), "heart")
			b.set_organ(Vector2i(2, 6), "heart")
			b.set_special(Vector2i(1, 4), "overload", 2)
			b.set_special(Vector2i(3, 4), "bloom", 1)
			b.set_special(Vector2i(1, 5), "care", 1)
			_main.get("_board_renderer").call("set_board_state", b, false)
			_main.get("_touch_ctrl").call("set_board_state", b)
			_main.call("_refresh_hud")
			var loop_chain: Array[Vector2i] = [Vector2i(2, 5), Vector2i(3, 5), Vector2i(3, 6), Vector2i(2, 6), Vector2i(2, 5)]
			_main.call("_on_chain_updated", loop_chain)
			_step = 4
			_wait = 6
		4:
			_save_shot("04_chain_selection_endpoint_preview_1080x2400.png")
			# Showcase Shield active + restricted organs + Overload variants
			var prog2: Dictionary = _main.get("progress")
			prog2["shield_charges"] = 1
			prog2["pulse_meter"] = 82
			prog2["care_energy"] = 60
			var b2: BoardState = _main.get("board_state")
			b2.set_organ(Vector2i(1, 7), "stomach", 1)
			b2.set_organ(Vector2i(2, 7), "liver", 1)
			b2.set_organ(Vector2i(2, 6), "kidneys")
			b2.set_organ(Vector2i(3, 6), "kidneys")
			b2.set_organ(Vector2i(4, 6), "kidneys")
			b2.set_special(Vector2i(5, 6), "overload", 1)
			_main.get("_board_renderer").call("set_board_state", b2, false)
			_main.call("_refresh_hud")
			var ch2: Array[Vector2i] = [Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6)]
			_main.call("_on_chain_updated", ch2)
			_step = 5
			_wait = 6
		5:
			_save_shot("05_hazard_and_care_shield_1080x2400.png")
			var prog3: Dictionary = _main.get("progress")
			prog3["score"] = 4860
			_main.call("_show_win_modal", 3, 720)
			_step = 6
			_wait = 16
		6:
			_save_shot("06_victory_screen_1080x2400.png")
			_main.call("_close_modals")
			_main.call("show_screen", "menu")
			_loc_mgr.set_language("id", false)
			_main.call("_sync_settings_ui")
			_main.call("_open_modal", _main.get("_modal_settings"))
			_step = 7
			_wait = 6
		7:
			_save_shot("07_settings_indonesian_1080x2400.png")
			_main.set("_almanac_tab", "cards")
			_main.call("_refresh_almanac_ui")
			_main.call("_open_modal", _main.get("_modal_almanac"))
			_step = 8
			_wait = 6
		8:
			_save_shot("08_almanac_indonesian_1080x2400.png")
			_main.set("_almanac_tab", "badges")
			_main.call("_refresh_almanac_ui")
			_step = 9
			_wait = 5
		9:
			_save_shot("09_almanac_badges_stats_1080x2400.png")
			_loc_mgr.set_language("en", false)
			_main.call("_close_modals")
			_main.call("start_level", 46)
			_configure_viewport(720, 1600, 1080, 2400)
			_step = 10
			_wait = 8
		10:
			_save_shot("res_720x1600.png")
			_configure_viewport(1080, 1920, 1080, 1920)
			_step = 11
			_wait = 8
		11:
			_save_shot("res_1080x1920.png")
			_configure_viewport(1080, 2400, 1080, 2400)
			_step = 12
			_wait = 8
		12:
			_save_shot("res_1080x2400.png")
			_configure_viewport(1440, 3200, 1080, 2400)
			_step = 13
			_wait = 8
		13:
			_save_shot("res_1440x3200.png")
			_save_mgr.clear_test_save_path()
			var tmp := "user://shot_tmp_v2.json"
			if FileAccess.file_exists(tmp):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
			if FileAccess.file_exists(tmp + ".bak"):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp + ".bak"))
			_save_mgr.load_save()
			_sv.queue_free()
			print("ALL SCREENSHOTS CAPTURED SUCCESSFULLY")
			quit(0)
			return true

	return false
