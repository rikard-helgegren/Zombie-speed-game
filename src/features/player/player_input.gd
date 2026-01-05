extends Node
class_name PlayerInput

signal move_input(direction : Vector2)
signal action_input(action_name : String)

func _process(_delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	emit_signal("move_input", input_vector.normalized())

	# Example actions
	if Input.is_action_just_pressed("attack"):
		emit_signal("action_input", "attack")
	if Input.is_action_just_pressed("shoot"):
		emit_signal("action_input", "shoot")
