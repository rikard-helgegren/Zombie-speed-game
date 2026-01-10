extends Node2D

@export var zombie_scene: PackedScene

var zombie_instance: Node = null

func _ready():
	spawn_zombie()

func spawn_zombie():
	if not zombie_scene: 
		print("Zombie spawner not properly instansiated")
		return

	# Instance the zombie
	zombie_instance = zombie_scene.instantiate()
	zombie_instance.global_position = global_position
	get_parent().call_deferred("add_child", zombie_instance)
