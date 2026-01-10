extends Node2D

@export var player_scene: PackedScene
@export var spawn_point: Node2D

var player_instance: Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_player()

func spawn_player():
	if not player_scene or not spawn_point:
		print("Player spawner not properly instansiated")
		return
		
	# Instance the zombie
	player_instance = player_scene.instantiate()
	player_instance.global_position = spawn_point.global_position
	get_parent().call_deferred("add_child", player_instance)
	
