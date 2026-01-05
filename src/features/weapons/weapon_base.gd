extends Node2D
class_name WeaponBase

@export var fire_rate: float = 0.3
@export var damage: int = 1

var can_fire := true
var aim_direction := Vector2.RIGHT

@onready var sprite: Sprite2D = $Sprite2D

func set_aim_direction(direction: Vector2):
	if direction.length() == 0:
		return

	aim_direction = direction.normalized()
	rotation = aim_direction.angle()

	# Flip sprite when aiming left
	if sprite:
		sprite.flip_v = abs(rad_to_deg(rotation)) > 90

func fire():
	# To be overridden by child weapons
	pass
