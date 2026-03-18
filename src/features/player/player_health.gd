extends Node
class_name PlayerHealth

@export var max_health: int = 3
@export var damage_sound: AudioStream
var current_health: int
var is_alive := true
@onready var _damage_player: AudioStreamPlayer2D = $damage
var _damage_base_db: float = 0.0

signal health_changed(current_health)
signal player_died()

func _ready():
	current_health = max_health + Global.player_hp_modifier
	emit_signal("health_changed", current_health)
	if _damage_player:
		_damage_base_db = _damage_player.volume_db
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
	_damage_player.volume_db = _damage_base_db + AudioManager.get_sfx_volume_db_offset()

func take_damage(amount: int):
	current_health -= amount
	EventBus.player_health_changed.emit(current_health)
	current_health = max(current_health, 0)
	emit_signal("health_changed", current_health)
	if is_alive:
		$damage.play()
	if current_health <= 0: 
		emit_signal("player_died")
		is_alive = false

func heal(amount: int):
	current_health += amount
	current_health = min(current_health, max_health)
	emit_signal("health_changed", current_health)
