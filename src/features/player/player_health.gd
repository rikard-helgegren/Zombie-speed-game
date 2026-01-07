extends Node
class_name PlayerHealth

@export var max_health: int = 1
@export var damage_sound: AudioStream
var current_health: int

signal health_changed(current_health)
signal player_died()

func _ready():
	current_health = max_health
	emit_signal("health_changed", current_health)

func take_damage(amount: int):
	current_health -= amount
	current_health = max(current_health, 0)
	emit_signal("health_changed", current_health)
	$damage.play()
	if current_health <= 0:
		emit_signal("player_died")

func heal(amount: int):
	current_health += amount
	current_health = min(current_health, max_health)
	emit_signal("health_changed", current_health)
