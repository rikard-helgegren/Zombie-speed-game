extends Node2D

@export var zombie_scene: PackedScene
@export var respawn_delay: float = 3.0
@export var spawn_count_on_death: int = 2
@export var spawn_radius: float = 100.0

func _ready():
	spawn_zombie()

func spawn_zombie():
	if not zombie_scene:
		push_error("Zombie scene not assigned")
		return

	var zombie = zombie_scene.instantiate()
	zombie.global_position = global_position + _random_offset()
	get_parent().call_deferred("add_child", zombie)

	# Connect death signal
	zombie.zombie_died.connect(_on_zombie_dead)

func _on_zombie_dead():
	await get_tree().create_timer(respawn_delay).timeout

	for i in spawn_count_on_death:
		spawn_zombie()

func _random_offset() -> Vector2:
	return Vector2(
		randf_range(-spawn_radius, spawn_radius),
		randf_range(-spawn_radius, spawn_radius)
	)
