extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
