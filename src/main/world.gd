extends Node2D
class_name World

signal level_cleared

@export var default_zombie_scene: PackedScene

@onready var zombies: Node2D = $Zombies

var max_zombies := 400
var alive_zombies := 0
var active_spawners := 0

func _ready():
	add_to_group("world")
	Global.zombies_node = zombies
	print("World: zombies node set -> ", zombies, " path=", zombies.get_path())


func request_zombie_spawn(position: Vector2,
						  zombie_scene: PackedScene = null) -> void:
	if not _can_spawn():
		return

	var zombie := zombie_scene if zombie_scene else default_zombie_scene
	if zombie == null:
		push_error("World: No zombie scene provided")
		return

	_spawn_zombie(zombie, position)

# -------- INTERNAL --------

func _can_spawn() -> bool:
	if zombies.get_child_count() < max_zombies:
		return true
	else:
		push_error("World: Max amount of zombies, stoped spawning")
		return false
	
func _spawn_zombie(zombie_scene: PackedScene, position: Vector2) -> void:
	var zombie = zombie_scene.instantiate()
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
