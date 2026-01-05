extends Node
class_name PlayerInput

signal move_input(direction : Vector2)
signal action_input(action_name : String)

func _process(_delta):
	var input_vector = Vector2.ZERO
	input_vector = Input.get_vector("left", "right", "up", "down")
	
	emit_signal("move_input", input_vector.normalized())

	if Input.is_action_just_pressed("shoot"): #space/left click/ RB
		emit_signal("action_input", "shoot")
