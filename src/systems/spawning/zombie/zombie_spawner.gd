extends Node2D
class_name ZombieSpawner

@export var zombie_scene: PackedScene
@export var spawn_count := 1
@export var spawn_delay := 0.5

var _world: World

func _ready():
	_world = get_tree().get_first_node_in_group("world")
	if _world == null:
		return

	_world.register_spawner()

	await get_tree().create_timer(spawn_delay).timeout
	_spawn_all()

func _spawn_all():
	for i in spawn_count:
		_world.request_zombie_spawn(global_position, zombie_scene)

	_world.spawner_finished()
