extends WeaponBase
class_name Pistol

func fire():
	if not can_fire:
		return

	can_fire = false
	print("Pistol fired")

	await get_tree().create_timer(fire_rate).timeout
	can_fire = true
