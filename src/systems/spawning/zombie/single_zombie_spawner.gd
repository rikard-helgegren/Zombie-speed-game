extends Node2D

@export var zombie_scene: PackedScene
@export var zombies_parent_path: NodePath

var zombie_instance: Node = null

func _ready():
	spawn_zombie()

func spawn_zombie():
	if not zombie_scene: 
		print("ERROR: Zombie spawner not properly instansiated")
		return
	
	var zombie_instance = zombie_scene.instantiate()

	var zombies_parent = get_node(zombies_parent_path)
	zombies_parent.add_child(zombie_instance)

	zombie_instance.global_position = global_position
	
