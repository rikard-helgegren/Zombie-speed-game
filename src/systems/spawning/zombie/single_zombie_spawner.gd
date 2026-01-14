extends Node2D
class_name SingleZombieSpawner

@export var zombie_scene: PackedScene
@export var auto_spawn := true
@export var spawn_delay := 0.5

var _world: World

func _ready():
	_world = get_tree().get_first_node_in_group("world")
	if _world == null:
		push_error("ZombieSpawner: World not found")
		return

	if auto_spawn:
		await get_tree().create_timer(spawn_delay).timeout
		spawn()

func spawn():
	if _world == null:
		return

	_world.request_zombie_spawn(
		global_position,
		zombie_scene
	)
