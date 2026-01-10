extends Node

# Export a NodePath to your PauseMenu
@export var pause_menu_path: NodePath
@onready var pause_menu: Control = get_node(pause_menu_path)


func _ready():
	# Ensure menu starts hidden
	pause_menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	var paused = not get_tree().paused
	get_tree().paused = paused
	pause_menu.visible = paused
	
	if paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		pause_menu.show_menu()
		
