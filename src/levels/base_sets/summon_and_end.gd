extends Node2D

@export var spawn_radious: float = 260.0
@export var detect_radius: float = 60.0

@onready var area: Area2D = $Area2D

func _ready() -> void:
	area.body_entered.connect(_on_area_body_entered)


func _on_area_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_teleport_zombies_to_circle()


func _teleport_zombies_to_circle() -> void:
	var zombies_node := _find_zombies_node()
	if zombies_node == null:
		push_error("SummonAndEnd: Zombies node not found")
		return

	var zombies := zombies_node.get_children()
	var count := zombies.size()
	if count == 0:
		return

	var center := area.global_position
	for i in range(count):
		var zombie := zombies[i]
		if not zombie or not is_instance_valid(zombie):
			continue
		if zombie is Node2D:
			var angle := TAU * float(i) / float(count)
			var offset := Vector2(cos(angle), sin(angle)) * spawn_radious
			zombie.global_position = center + offset


func _find_zombies_node() -> Node2D:
	if Global.zombies_node and is_instance_valid(Global.zombies_node):
		return Global.zombies_node

	var world := get_tree().get_first_node_in_group("world")
	if world:
		var world_zombies := world.get_node_or_null("Zombies")
		if world_zombies and world_zombies is Node2D:
			return world_zombies

	var scene := get_tree().current_scene
	if scene:
		var scene_zombies := scene.get_node_or_null("Zombies")
		if scene_zombies and scene_zombies is Node2D:
			return scene_zombies
		var found := scene.find_child("Zombies", true, false)
		if found and found is Node2D:
			return found

	return null
