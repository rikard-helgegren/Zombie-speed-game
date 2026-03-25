extends Node2D

@export var thickness: float = 2.5
@export var color: Color = Color(1.0, 0.85, 0.4, 0.4)
@export var fade_time: float = 0.12

@onready var rect: Polygon2D = $Rect

func setup(from: Vector2, to: Vector2) -> void:
	var dir := from - to
	var length := dir.length()
	if length <= 0.001:
		queue_free()
		return
	
	# Anchor at hit position so y-sort uses the impact depth.
	global_position = to
	rotation = dir.angle()
	
	var half := thickness * 0.5
	rect.polygon = PackedVector2Array([
		Vector2(0.0, -half),
		Vector2(length, -half),
		Vector2(length, half),
		Vector2(0.0, half),
	])
	rect.color = color
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.finished.connect(queue_free)
