extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
