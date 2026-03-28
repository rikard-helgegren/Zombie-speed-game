extends Node

# Signals
signal level_started

# Export a NodePath to your PauseMenu
@export var pause_menu_path: NodePath
@export var levels: Array[PackedScene] = []

@onready var pause_menu: Control = get_node(pause_menu_path)

@export var level_container_path: NodePath
@onready var level_container := get_node("../World/Level")

@export var player_node_path: NodePath
@onready var player_node := get_node("../World/Player")

@export var world_node_path: NodePath
@onready var world_node := get_node("../World")

@export var zombies_node_path: NodePath
@onready var zombies_node := get_node("../World/Zombies")

@export var ui_layer_path: NodePath
@onready var ui_layer := get_node(ui_layer_path)
@onready var start_menu: Control = get_node_or_null("../UI/StartMenu")

@export var all_upgrades: Array[UpgradeDef] = []

var current_level_index := -1
var current_level_instance: Node = null


@export var upgrade_menu_scene: PackedScene
@export var completed_map_scene: PackedScene = preload("res://src/ui/menus/MapComplete.tscn")

var _current_world: World
var _upgrade_menu: Node
var _completed_map: Node
const COMPLETED_MAP_DISPLAY_SECONDS := 10.0




func _ready():
	add_to_group("game_manager")
	var world := get_tree().get_first_node_in_group("world")
	world.level_cleared.connect(_on_level_cleared)

func register_world(world: World) -> void:
	_current_world = world
	world.level_cleared.connect(_on_level_cleared)


func _on_level_cleared():
	AudioManager.play_sfx_clip("sfx_game_complete")
	_show_completed_map()
	await _wait_for_map_complete_continue()
	_hide_completed_map()
	load_upgrade_menu()
	
func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	var paused = not get_tree().paused
	get_tree().paused = paused
	
	if paused:
		pause_menu.show_menu()
	else:
		pause_menu.visible = false
	_update_mouse_mode()
		

func load_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		push_error("Invalid level index: %d" % index)
		return
		
	# Remove prev Zombies
	for child in zombies_node.get_children():
		child.queue_free()
	
	world_node.alive_zombies = 0
	world_node.active_spawners = 0
	world_node.kill_count = 0
	
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
	if start_menu:
		start_menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_update_mouse_mode()
	
	# Emit level started signal
	level_started.emit()

	AudioManager.play_music_clip("music_level")
	
func load_first_level():
	load_level(0)

func load_next_level():
	var next_level: int
	if current_level_index >= levels.size() - 1:
		next_level = 0 #loop levels
		Global.spawner_extra_zombies += 1
		Global.zombies_extra_speed += 1
		
	else:
		next_level = current_level_index + 1
	load_level(next_level)

func restart_level():
	load_level(current_level_index)	
	
func load_start_menue():
	pass
	
func load_upgrade_menu():
	if upgrade_menu_scene == null:
		push_error("GameManager: upgrade_menu_scene not set")
		return
		
	get_tree().paused = true

	var upgrades := get_random_upgrades(2)

	_upgrade_menu = upgrade_menu_scene.instantiate()
	ui_layer.add_child(_upgrade_menu)

	_upgrade_menu.show_menu(upgrades)	
	_update_mouse_mode()

func _show_completed_map() -> void:
	if completed_map_scene == null:
		return
	if _completed_map and is_instance_valid(_completed_map):
		_completed_map.queue_free()
	_completed_map = completed_map_scene.instantiate()
	ui_layer.add_child(_completed_map)
	_update_completed_map_count()

func _hide_completed_map() -> void:
	if _completed_map and is_instance_valid(_completed_map):
		_completed_map.queue_free()
		_completed_map = null

func _update_completed_map_count() -> void:
	if _completed_map == null:
		return
	var count_label := _completed_map.get_node_or_null("KillCount/Count")
	if count_label and count_label is Label:
		count_label.text = str(world_node.kill_count)

func _wait_for_map_complete_continue() -> void:
	var timer := get_tree().create_timer(COMPLETED_MAP_DISPLAY_SECONDS, true)
	while true:
		if Input.is_anything_pressed():
			return
		if timer.time_left <= 0.0:
			return
		await get_tree().process_frame

func _update_mouse_mode() -> void:
	var should_show := false
	if pause_menu and pause_menu.visible:
		should_show = true
	elif start_menu and start_menu.visible:
		should_show = true
	elif _upgrade_menu and _upgrade_menu.visible:
		should_show = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if should_show else Input.MOUSE_MODE_HIDDEN)
	

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
