extends Node2D

@export var zombie_scene: PackedScene
@export var spawn_point: Node2D
@export var respawn_delay: float = 3.0

var zombie_instance: Node = null

func _ready():
	print("ZombieSpawner _ready() called")
	print("Zombie scene:", zombie_scene)
	print("Spawn point:", spawn_point)
	spawn_zombie()

func spawn_zombie():
	print("in spawn")
	if not zombie_scene or not spawn_point:
		print("Zombie spawner not properly instansiated")
		return

	# Instance the zombie
	zombie_instance = zombie_scene.instantiate()
	zombie_instance.global_position = spawn_point.global_position
	get_parent().call_deferred("add_child", zombie_instance)
	
	print("should add zombie")
	print("Spawned zombie at", zombie_instance.global_position)

	# Connect death signal
	if zombie_instance.has_method("connect"):
		zombie_instance.connect("zombie_died", Callable(self, "_on_zombie_dead"))

func _on_zombie_dead():
	zombie_instance = null
	await get_tree().create_timer(respawn_delay).timeout
	spawn_zombie()
