extends WeaponBase
class_name Shotgun

@export var pellet_count := 6
@export var spread := 15.0

func fire():
	if not can_fire:
		return

	can_fire = false

	for i in pellet_count:
		var angle_offset = deg_to_rad(randf_range(-spread, spread))
		var pellet_dir = aim_direction.rotated(angle_offset)
		print("Shotgun pellet:", pellet_dir)

	await get_tree().create_timer(fire_rate).timeout
	can_fire = true
