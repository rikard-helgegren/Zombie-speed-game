extends Node

# Export a NodePath to your PauseMenu
@export var pause_menu_path: NodePath
@export var levels: Array[PackedScene] = []

@onready var pause_menu: Control = get_node(pause_menu_path)
@onready var level_container := get_node("../World/Level")


@onready var player_node := get_node("../World/Player")
@onready var zombies_node := get_node("../World/Zombies")

var current_level_index := -1
var current_level_instance: Node = null




func _ready():
	# Ensure menu starts hidden
	pause_menu.visible = false
	

	#if levels.size() > 0:
#		load_first_level()
	
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
		

func load_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		push_error("Invalid level index: %d" % index)
		return

	# Remove current level
	if current_level_instance:
		current_level_instance.queue_free()
		current_level_instance = null

	# Instance new level
	var level_scene := levels[index]
	current_level_instance = level_scene.instantiate()
	level_container.add_child(current_level_instance)

	current_level_index = index

	# Ensure game is unpaused
	get_tree().paused = false
	pause_menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
func load_first_level():
	load_level(0)

func load_next_level():
	load_level(current_level_index + 1)

func restart_level():
	load_level(current_level_index)	
	
func load_start_menue():
	pass
	
func load_upgarde_menue():
	pass
	
# Called by UpgradeMenu
func apply_upgrade(option_index: int):
	match option_index:
		1:
			print("Upgrade 1 applied")
			# Example: increase player speed
			if player_node.has_method("upgrade_speed"):
				player_node.upgrade_speed()
		2:
			print("Upgrade 2 applied")
			# Example: increase player damage
			if player_node.has_method("upgrade_damage"):
				player_node.upgrade_damage()


		
