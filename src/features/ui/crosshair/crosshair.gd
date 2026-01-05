extends Node2D
class_name Crosshair

func _process(_delta):
	global_position = get_global_mouse_position()
