extends Node2D
class_name World

signal level_cleared

@export var default_zombie_scene: PackedScene

@onready var zombies: Node2D = $Zombies

var max_zombies := 16
var alive_zombies := 0
var active_spawners := 0

func _ready():
	add_to_group("world")


func request_zombie_spawn(
	position: Vector2,
	zombie_scene: PackedScene = null
) -> void:
	if not _can_spawn():
		return

	var scene := zombie_scene if zombie_scene else default_zombie_scene
	if scene == null:
		push_error("World: No zombie scene provided")
		return

	_spawn_zombie(scene, position)

# -------- INTERNAL --------

func _can_spawn() -> bool:
	return zombies.get_child_count() < max_zombies
	
func _spawn_zombie(scene: PackedScene, position: Vector2) -> void:
	var zombie = scene.instantiate()
	zombies.add_child(zombie)
	zombie.global_position = position
	alive_zombies += 1


func register_spawner():
	active_spawners += 1

func spawner_finished():
	active_spawners -= 1
	_check_level_cleared()

func on_zombie_spawned():
	alive_zombies += 1

func on_zombie_died():
	alive_zombies -= 1
	_check_level_cleared()


func _check_level_cleared():
	if active_spawners > 0:
		return
	
	if alive_zombies > 0:
		return
		
	emit_signal("level_cleared")
