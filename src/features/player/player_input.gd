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
	if Input.is_action_just_pressed("melee"): # right click
		emit_signal("action_input", "melee")
	if Input.is_action_just_pressed("reload"): # 'R'
		emit_signal("action_input", "reload")
	if Input.is_action_just_pressed("grappleHook"): # E
		emit_signal("action_input", "grapple_hold_start")
	if Input.is_action_just_released("grappleHook"):
		emit_signal("action_input", "grapple_hold_end")
