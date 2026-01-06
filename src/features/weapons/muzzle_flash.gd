extends Node2D
class_name MuzzleFlash

@onready var sprite: Sprite2D = $Sprite2D

# This is the permanent “design” scale of the flash
@export var base_scale: Vector2 = Vector2.ONE *0.15

var tween: Tween

func flash():
	if not sprite:
		return

	if tween and tween.is_running():
		tween.kill()

	sprite.visible = true
	sprite.modulate.a = 1.0

	# Start at small fraction of base_scale
	sprite.scale = base_scale * 0.4

	tween = create_tween()
	tween.set_parallel(true)

	# Tween to full base_scale
	tween.tween_property(sprite, "scale", base_scale, 0.05)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(sprite, "modulate:a", 0.0, 0.08)\
		.set_delay(0.02)

	tween.finished.connect(func():
		sprite.visible = false
	)

	
