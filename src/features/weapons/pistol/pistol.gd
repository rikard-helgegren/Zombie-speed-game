extends WeaponBase
class_name Pistol

# Fire rate and damage is set in inspector
func _init() -> void:
	fire_rate = 0.5
	damage = 2

func fire():
	print("pistol trigger")
	if not can_fire:
		print("not ready")
		return

	can_fire = false
	
	hitscan_fire(damage)
	
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true
