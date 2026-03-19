extends Node
class_name PlayerHealth

@export var max_health: int = 3
@export var damage_sound: AudioStream
@export_group("Screen Shake")
@export var shake_duration: float = 0.5
@export var shake_intensity: float = 5.0
var current_health: int
var is_alive := true
@onready var _damage_player: AudioStreamPlayer2D = $damage
var _damage_base_db: float = 0.0
var _damage_base_pitch: float = 1.0

signal health_changed(current_health)
signal player_died()

func _ready():
	current_health = max_health + Global.player_hp_modifier
	emit_signal("health_changed", current_health)
	if _damage_player:
		_damage_base_db = _damage_player.volume_db
		_damage_base_pitch = _damage_player.pitch_scale
		_apply_sfx_volume()
	if AudioManager and not AudioManager.sfx_volume_changed.is_connected(_on_sfx_volume_changed):
		AudioManager.sfx_volume_changed.connect(_on_sfx_volume_changed)

func _exit_tree() -> void:
	if AudioManager and AudioManager.sfx_volume_changed.is_connected(_on_sfx_volume_changed):
		AudioManager.sfx_volume_changed.disconnect(_on_sfx_volume_changed)

func _on_sfx_volume_changed(_value: float) -> void:
	_apply_sfx_volume()

func _apply_sfx_volume() -> void:
	if not _damage_player:
		return
	_damage_player.volume_db = _damage_base_db + AudioManager.get_sfx_volume_db_offset() + AudioManager.get_sfx_clip_db(_damage_player.stream)
	_damage_player.pitch_scale = _damage_base_pitch * AudioManager.get_sfx_clip_pitch(_damage_player.stream)

func take_damage(amount: int):
	current_health -= amount
	EventBus.player_health_changed.emit(current_health)
	current_health = max(current_health, 0)
	emit_signal("health_changed", current_health)
	if is_alive:
		$damage.play()
		_trigger_screen_shake()
	if current_health <= 0: 
		emit_signal("player_died")
		is_alive = false

func heal(amount: int):
	current_health += amount
	current_health = min(current_health, max_health)
	emit_signal("health_changed", current_health)

func _trigger_screen_shake() -> void:
	var camera := get_viewport().get_camera_2d()
	if not camera:
		push_warning("PlayerHealth: No active Camera2D found for screen shake.")
		return

	if camera.has_method("shake"):
		camera.shake(shake_duration, shake_intensity)
	else:
		push_warning("PlayerHealth: Active Camera2D '%s' is missing a 'shake(duration, intensity)' function." % camera.name)
