extends Area2D
class_name Hitbox

@export var expand_scale: float = 1.2
@export var expand_time: float = 0.06

@onready var collision_shape := $CollisionShape2D

var original_scale: Vector2

func _ready():
	original_scale = collision_shape.scale

func feedback_expand():
	collision_shape.scale = original_scale * expand_scale

	await get_tree().create_timer(expand_time).timeout

	collision_shape.scale = original_scale
