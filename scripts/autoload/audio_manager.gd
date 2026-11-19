extends Node
## Audio manager for Master, Music, SFX, and UI buses with seamless music looping and pitch-scaled SFX.

const MUSIC_TRACKS := {
	"menu": "res://assets/audio/music/bgm_menu_tropika.wav",
	"gameplay": "res://assets/audio/music/bgm_gameplay_nadi.wav",
	"victory": "res://assets/audio/music/bgm_victory_cerah.wav",
	"boss": "res://assets/audio/music/bgm_boss_harmoni.wav"
}

const SFX_PATHS := {
	"menu_button": "res://assets/audio/sfx/sfx_menu_button.wav",
	"tile_select": "res://assets/audio/sfx/sfx_tile_select.wav",
	"chain_extend": "res://assets/audio/sfx/sfx_chain_extend.wav",
	"valid_release": "res://assets/audio/sfx/sfx_valid_release.wav",
	"invalid_path": "res://assets/audio/sfx/sfx_invalid_path.wav",
	"match_small": "res://assets/audio/sfx/sfx_match_small.wav",
	"match_large": "res://assets/audio/sfx/sfx_match_large.wav",
	"endpoint_pulse": "res://assets/audio/sfx/sfx_endpoint_pulse.wav",
	"shield_activate": "res://assets/audio/sfx/sfx_shield_activate.wav",
	"shield_block": "res://assets/audio/sfx/sfx_shield_block.wav",
	"hazard_warning": "res://assets/audio/sfx/sfx_hazard_warning.wav",
	"hazard_trigger": "res://assets/audio/sfx/sfx_hazard_trigger.wav",
	"tile_refill": "res://assets/audio/sfx/sfx_tile_refill.wav",
	"score_popup": "res://assets/audio/sfx/sfx_score_popup.wav",
	"victory": "res://assets/audio/sfx/sfx_victory.wav",
	"defeat": "res://assets/audio/sfx/sfx_defeat.wav",
	"level_transition": "res://assets/audio/sfx/sfx_level_transition.wav",
	"loop_form": "res://assets/audio/sfx/sfx_loop_form.wav",
	"ability_cast": "res://assets/audio/sfx/sfx_ability_cast.wav",
	"combo_banner": "res://assets/audio/sfx/sfx_combo_banner.wav",
	"star_pop": "res://assets/audio/sfx/sfx_star_pop.wav"
}

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _ui_player: AudioStreamPlayer
var _music_streams: Dictionary = {}
var _sfx_streams: Dictionary = {}
var _current_track: String = ""
var _sfx_cursor: int = 0
var _paused_by_focus: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_players()
	_preload_streams()
	apply_saved_volumes()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_paused_by_focus = true
		if is_instance_valid(_music_player) and _music_player.playing:
			_music_player.stream_paused = true
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if _paused_by_focus:
			_paused_by_focus = false
			if is_instance_valid(_music_player):
				_music_player.stream_paused = false


func _setup_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)

	_ui_player = AudioStreamPlayer.new()
	_ui_player.bus = "UI" if AudioServer.get_bus_index("UI") >= 0 else "Master"
	add_child(_ui_player)

	for i in range(10):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		add_child(p)
		_sfx_pool.append(p)


func _preload_streams() -> void:
	for k in MUSIC_TRACKS.keys():
		var path: String = MUSIC_TRACKS[k]
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			if stream is AudioStreamWAV and k != "victory":
				stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
				stream.loop_begin = 0
				# Calculate total PCM frames for clean WAV looping
				if stream.data.size() > 0:
					var frame_bytes := 4 if stream.stereo else 2
					stream.loop_end = stream.data.size() / frame_bytes
			_music_streams[k] = stream
	for k in SFX_PATHS.keys():
		var spath: String = SFX_PATHS[k]
		if ResourceLoader.exists(spath):
			_sfx_streams[k] = load(spath)


func apply_saved_volumes() -> void:
	var m_vol := float(SaveManager.get_setting("music_volume", 0.78))
	var s_vol := float(SaveManager.get_setting("sfx_volume", 0.85))
	var m_mute := bool(SaveManager.get_setting("music_muted", false))
	var s_mute := bool(SaveManager.get_setting("sfx_muted", false))
	set_music_volume(m_vol, false)
	set_sfx_volume(s_vol, false)
	set_music_muted(m_mute, false)
	set_sfx_muted(s_mute, false)


func _linear_to_bus_db(linear_val: float) -> float:
	if linear_val <= 0.001:
		return -80.0
	return linear_to_db(clampf(linear_val, 0.001, 1.0))


func set_music_volume(linear_val: float, persist: bool = true) -> void:
	var v := clampf(linear_val, 0.0, 1.0)
	var bus_idx := AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, _linear_to_bus_db(v))
	if persist:
		SaveManager.set_setting("music_volume", v)


func set_sfx_volume(linear_val: float, persist: bool = true) -> void:
	var v := clampf(linear_val, 0.0, 1.0)
	for bus_name in ["SFX", "UI"]:
		var bus_idx := AudioServer.get_bus_index(bus_name)
		if bus_idx >= 0:
			AudioServer.set_bus_volume_db(bus_idx, _linear_to_bus_db(v))
	if persist:
		SaveManager.set_setting("sfx_volume", v)


func set_music_muted(muted: bool, persist: bool = true) -> void:
	var bus_idx := AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_mute(bus_idx, muted)
	if persist:
		SaveManager.set_setting("music_muted", muted)


func set_sfx_muted(muted: bool, persist: bool = true) -> void:
	for bus_name in ["SFX", "UI"]:
		var bus_idx := AudioServer.get_bus_index(bus_name)
		if bus_idx >= 0:
			AudioServer.set_bus_mute(bus_idx, muted)
	if persist:
		SaveManager.set_setting("sfx_muted", muted)


func play_music(track_key: String) -> void:
	if DisplayServer.get_name() == "headless":
		_current_track = track_key
		return
	if _current_track == track_key and _music_player.playing:
		return
	if not _music_streams.has(track_key):
		return
	_current_track = track_key
	_music_player.stream = _music_streams[track_key]
	_music_player.stream_paused = false
	_music_player.play()


func stop_music() -> void:
	_current_track = ""
	if is_instance_valid(_music_player):
		_music_player.stop()


func _on_music_finished() -> void:
	if _current_track == "menu" or _current_track == "gameplay" or _current_track == "boss":
		if is_instance_valid(_music_player) and _music_player.stream != null:
			_music_player.play()


func play_sfx(event_name: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not _sfx_streams.has(event_name):
		return
	if DisplayServer.get_name() == "headless":
		return
	var stream: AudioStream = _sfx_streams[event_name]
	if event_name == "menu_button" or event_name == "level_transition":
		_ui_player.stream = stream
		_ui_player.pitch_scale = clampf(pitch_scale, 0.75, 1.55)
		_ui_player.volume_db = volume_db
		_ui_player.play()
		return
	var player := _sfx_pool[_sfx_cursor]
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_pool.size()
	player.stream = stream
	player.pitch_scale = clampf(pitch_scale, 0.72, 1.75)
	player.volume_db = volume_db
	player.play()


func play_chain_step_sfx(chain_length: int) -> void:
	# Pentatonic musical scale steps as chain grows
	var semitones := [0, 2, 4, 7, 9, 12, 14, 16, 19]
	var idx := clampi(chain_length - 1, 0, semitones.size() - 1)
	var pitch := pow(2.0, float(semitones[idx]) / 12.0)
	play_sfx("chain_extend" if chain_length > 1 else "tile_select", pitch, -1.5)


func get_registered_sfx_names() -> Array:
	return SFX_PATHS.keys()


func get_registered_music_names() -> Array:
	return MUSIC_TRACKS.keys()
