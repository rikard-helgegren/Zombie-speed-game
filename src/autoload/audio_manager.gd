extends Node
# Centralized audio control

const DEFAULT_MUSIC_PATH := "res://src/assets/audio/music/psychronic-echoes-of-the-precursors/main.mp3"
const MIN_LINEAR := 0.001
const SFX_BASE_DB := 12.0
signal sfx_volume_changed(value: float)

var _music_player: AudioStreamPlayer
var _music_fade_tween: Tween
var music_volume_linear: float = 0.5
var sfx_volume_linear: float = 0.5

func _ready():
	EventBus.pause_changed.connect(_on_pause_changed)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_music_player()
	set_music_volume_linear(music_volume_linear)
	play_music_path(DEFAULT_MUSIC_PATH)

func _init_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.autoplay = false
	add_child(_music_player)
	set_music_volume_linear(music_volume_linear)

func play_music_path(path: String, loop: bool = true) -> void:
	var stream: AudioStream = load(path)
	if stream == null:
		push_error("AudioManager: failed to load music at %s" % path)
		return
	play_music_stream(stream, loop)

func play_music_stream(stream: AudioStream, loop: bool = true) -> void:
	if stream == null:
		return
	if "loop" in stream:
		stream.loop = loop
	_music_player.stream = stream
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
		_music_player.volume_db = linear_to_db(max(music_volume_linear, MIN_LINEAR))

func _fade_in_music() -> void:
	if not _music_player:
		return
	if _music_fade_tween:
		_music_fade_tween.kill()
	var target_db = linear_to_db(max(music_volume_linear, MIN_LINEAR))
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
