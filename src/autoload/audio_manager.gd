extends Node
# Centralized audio control

const DEFAULT_MUSIC_PATH := "res://src/assets/audio/music/psychronic-echoes-of-the-precursors/main.mp3"
const AUDIO_CONFIG_PATH := "res://src/config/audio_config.cfg"
const CLIP_SECTION_PREFIX := "clip:"
const MIN_LINEAR := 0.001
const SFX_BASE_DB := 16.0
signal sfx_volume_changed(value: float)

var _music_player: AudioStreamPlayer
var _music_fade_tween: Tween
var _music_track_db: float = 0.0
var _music_track_pitch: float = 1.0
var _clip_by_path: Dictionary = {}
var _clip_by_name: Dictionary = {}
var _audio_cfg: ConfigFile
var music_volume_linear: float = 0.5
var sfx_volume_linear: float = 0.5

func _ready():
	EventBus.pause_changed.connect(_on_pause_changed)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_audio_config()
	_init_music_player()
	set_music_volume_linear(music_volume_linear)
	play_music_path(_get_default_music_path())

func _init_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.autoplay = false
	add_child(_music_player)
	set_music_volume_linear(music_volume_linear)

func play_music_clip(clip_name: String, loop: bool = true) -> void:
	var path := get_clip_path(clip_name)
	if path == "":
		push_warning("AudioManager: missing music clip '%s' in config" % clip_name)
		path = DEFAULT_MUSIC_PATH
	play_music_path(path, loop)

func play_music_path(path: String, loop: bool = true) -> void:
	var stream: AudioStream = load(path)
	if stream == null:
		push_error("AudioManager: failed to load music at %s" % path)
		return
	var effective_loop := _apply_music_clip_settings(path, loop)
	play_music_stream(stream, effective_loop)

func play_music_stream(stream: AudioStream, loop: bool = true) -> void:
	if stream == null:
		return
	if "loop" in stream:
		stream.loop = loop
	_music_player.stream = stream
	_music_player.pitch_scale = _music_track_pitch
	_music_player.play()
	_fade_in_music()

func stop_music() -> void:
	_music_player.stop()

func _on_pause_changed(paused: bool) -> void:
	# Keep music playing during pause.
	pass

func set_music_volume_linear(value: float) -> void:
	music_volume_linear = clamp(value, 0.0, 1.0)
	if _music_player:
		_apply_music_volume()

func _fade_in_music() -> void:
	if not _music_player:
		return
	if _music_fade_tween:
		_music_fade_tween.kill()
	var target_db = _get_music_volume_db()
	_music_player.volume_db = -80.0
	_music_fade_tween = create_tween()
	_music_fade_tween.tween_property(_music_player, "volume_db", target_db, 0.5)

func set_sfx_volume_linear(value: float) -> void:
	sfx_volume_linear = clamp(value, 0.0, 1.0)
	sfx_volume_changed.emit(sfx_volume_linear)

func get_music_volume_linear() -> float:
	return music_volume_linear

func get_sfx_volume_linear() -> float:
	return sfx_volume_linear

func get_sfx_volume_db_offset() -> float:
	return linear_to_db(max(sfx_volume_linear, MIN_LINEAR)) + SFX_BASE_DB

func get_sfx_volume_db() -> float:
	return get_sfx_volume_db_offset()

func get_clip_path(clip_name: String) -> String:
	if not _clip_by_name.has(clip_name):
		return ""
	return str(_clip_by_name[clip_name].get("path", ""))

func get_clip_names() -> Array[String]:
	var names: Array[String] = []
	for name in _clip_by_name.keys():
		names.append(str(name))
	return names

func get_clip_volume_db_by_name(clip_name: String) -> float:
	if not _clip_by_name.has(clip_name):
		return 0.0
	return float(_clip_by_name[clip_name].get("volume_db", 0.0))

func set_clip_volume_db(clip_name: String, value: float) -> void:
	if not _clip_by_name.has(clip_name):
		return
	var clip: Dictionary = _clip_by_name[clip_name] as Dictionary
	clip["volume_db"] = float(value)
	_clip_by_name[clip_name] = clip
	_clip_by_path[str(clip.get("path", ""))] = clip
	_save_clip_value(clip_name, "volume_db", float(value))

	var clip_type := str(clip.get("type", "sfx"))
	if clip_type == "music":
		if _music_player and _music_player.stream and _music_player.stream.resource_path == str(clip.get("path", "")):
			_music_track_db = float(value)
			_apply_music_volume()
	else:
		sfx_volume_changed.emit(sfx_volume_linear)

func get_sfx_clip_db(stream: AudioStream) -> float:
	var clip := _get_clip_config_for_stream(stream)
	if clip.is_empty():
		return 0.0
	return float(clip.get("volume_db", 0.0))

func get_sfx_clip_pitch(stream: AudioStream) -> float:
	var clip := _get_clip_config_for_stream(stream)
	if clip.is_empty():
		return 1.0
	return float(clip.get("pitch_scale", 1.0))

func _apply_music_clip_settings(path: String, loop: bool) -> bool:
	var clip := _get_clip_config_for_path(path)
	_music_track_db = float(clip.get("volume_db", 0.0))
	_music_track_pitch = float(clip.get("pitch_scale", 1.0))
	if clip.has("loop"):
		loop = bool(clip.get("loop", loop))
	return loop

func _get_default_music_path() -> String:
	var path := get_clip_path("music_default")
	if path != "":
		return path
	return DEFAULT_MUSIC_PATH

func _apply_music_volume() -> void:
	if not _music_player:
		return
	_music_player.volume_db = _get_music_volume_db()

func _get_music_volume_db() -> float:
	return linear_to_db(max(music_volume_linear, MIN_LINEAR)) + _music_track_db

func _get_clip_config_for_stream(stream: AudioStream) -> Dictionary:
	if stream == null:
		return {}
	return _get_clip_config_for_path(stream.resource_path)

func _get_clip_config_for_path(path: String) -> Dictionary:
	if path == "":
		return {}
	return _clip_by_path.get(path, {})

func _load_audio_config() -> void:
	_clip_by_path.clear()
	_clip_by_name.clear()
	var cfg := ConfigFile.new()
	var err := cfg.load(AUDIO_CONFIG_PATH)
	if err != OK:
		push_warning("AudioManager: failed to load audio config at %s" % AUDIO_CONFIG_PATH)
		_audio_cfg = null
		return
	_audio_cfg = cfg
	if cfg.has_section_key("global", "music_volume_linear"):
		music_volume_linear = float(cfg.get_value("global", "music_volume_linear", music_volume_linear))
	if cfg.has_section_key("global", "sfx_volume_linear"):
		sfx_volume_linear = float(cfg.get_value("global", "sfx_volume_linear", sfx_volume_linear))
	for section in cfg.get_sections():
		if not section.begins_with(CLIP_SECTION_PREFIX):
			continue
		var clip_name := section.trim_prefix(CLIP_SECTION_PREFIX)
		var path := str(cfg.get_value(section, "path", ""))
		if path == "":
			continue
		var clip := {
			"name": clip_name,
			"path": path,
			"type": str(cfg.get_value(section, "type", "sfx")),
			"volume_db": float(cfg.get_value(section, "volume_db", 0.0)),
			"pitch_scale": float(cfg.get_value(section, "pitch_scale", 1.0)),
			"loop": bool(cfg.get_value(section, "loop", false)),
		}
		_clip_by_path[path] = clip
		_clip_by_name[clip_name] = clip

func _save_clip_value(clip_name: String, key: String, value: Variant) -> void:
	var section := "%s%s" % [CLIP_SECTION_PREFIX, clip_name]
	if _audio_cfg == null:
		_audio_cfg = ConfigFile.new()
		var err := _audio_cfg.load(AUDIO_CONFIG_PATH)
		if err != OK:
			push_warning("AudioManager: failed to reload audio config for save at %s" % AUDIO_CONFIG_PATH)
			return
	_audio_cfg.set_value(section, key, value)
	var save_err := _audio_cfg.save(AUDIO_CONFIG_PATH)
	if save_err != OK:
		push_warning("AudioManager: failed to save audio config at %s" % AUDIO_CONFIG_PATH)

func play_sfx_clip_at_position(clip_name: String, position: Vector2) -> void:
	var path := get_clip_path(clip_name)
	if path == "":
		return
	var stream: AudioStream = load(path)
	if not stream:
		return

	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.position = position
	player.volume_db = get_sfx_clip_db(stream) + get_sfx_volume_db_offset()
	player.pitch_scale = get_sfx_clip_pitch(stream)
	get_tree().current_scene.add_child(player)
	player.play()

	# Queue free after the audio finishes
	var duration := 2.0 # fallback duration
	if stream.has_method("get_length"):
		duration = stream.get_length() / player.pitch_scale

	var t := Timer.new()
	t.one_shot = true
	t.wait_time = duration
	t.timeout.connect(Callable(player, "queue_free"))
	player.add_child(t)
	t.start()

func play_sfx_clip(clip_name: String) -> void:
	var path := get_clip_path(clip_name)
	if path == "":
		return
	var stream: AudioStream = load(path)
	if not stream:
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = get_sfx_clip_db(stream) + get_sfx_volume_db_offset()
	player.pitch_scale = get_sfx_clip_pitch(stream)
	add_child(player)
	player.play()

	var duration := 2.0 # fallback duration
	if stream.has_method("get_length"):
		duration = stream.get_length() / player.pitch_scale

	var t := Timer.new()
	t.one_shot = true
	t.wait_time = duration
	t.timeout.connect(Callable(player, "queue_free"))
	player.add_child(t)
	t.start()
