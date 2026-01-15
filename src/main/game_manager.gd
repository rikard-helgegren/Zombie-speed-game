extends Node

# Export a NodePath to your PauseMenu
@export var pause_menu_path: NodePath
@export var levels: Array[PackedScene] = []

@onready var pause_menu: Control = get_node(pause_menu_path)

@export var level_container_path: NodePath
@onready var level_container := get_node("../World/Level")

@export var player_node_path: NodePath
@onready var player_node := get_node("../World/Player")

@export var zombies_node_path: NodePath
@onready var zombies_node := get_node("../World/Zombies")

@export var ui_layer_path: NodePath
@onready var ui_layer := get_node(ui_layer_path)

@export var all_upgrades: Array[UpgradeDef] = []

var current_level_index := -1
var current_level_instance: Node = null


@export var upgrade_menu_scene: PackedScene

var _current_world: World
var _upgrade_menu: Node


func _ready():
	var world := get_tree().get_first_node_in_group("world")
	world.level_cleared.connect(_on_level_cleared)

func register_world(world: World) -> void:
	_current_world = world
	world.level_cleared.connect(_on_level_cleared)


func _on_level_cleared():
	print("_on_level_cleared")
	load_upgrade_menu()
	#load_next_level()
	
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
	var next_level: int
	if current_level_index >= levels.size() - 1:
		next_level = 0 #loop levels
	else:
		next_level = current_level_index + 1
	load_level(next_level)

func restart_level():
	load_level(current_level_index)	
	
func load_start_menue():
	pass
	
func load_upgrade_menu():
	print("load upgarde menu")
	if upgrade_menu_scene == null:
		push_error("GameManager: upgrade_menu_scene not set")
		return
		
	get_tree().paused = true

	var upgrades := get_random_upgrades(2)

	_upgrade_menu = upgrade_menu_scene.instantiate()
	#_upgrade_menu.pause_mode = Node.PAUSE_MODE_PROCESS
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	ui_layer.add_child(_upgrade_menu)

	_upgrade_menu.show_menu(upgrades)	
	


# Called by UpgradeMenu
func apply_upgrade(upgrade: UpgradeDef):
	match upgrade.id:
		"move_speed":
			Global.player_move_speed_modifier += 1
		"reload_speed":
			Global.player_reload_speed_modifier += 1
		"damage":
			Global.player_damage_modifier += 1
		"ammo":
			Global.player_ammo_modifier += 1
		"fire_rate":
			Global.player_fire_rate_modifier += 1
		"HP":
			Global.player_hp_modifier += 1
		_:
			push_warning("Unknown upgrade: " + upgrade.id)

func get_random_upgrades(count: int = 2) -> Array[UpgradeDef]:
	var pool := all_upgrades.duplicate()
	pool.shuffle()
	return pool.slice(0, count)
