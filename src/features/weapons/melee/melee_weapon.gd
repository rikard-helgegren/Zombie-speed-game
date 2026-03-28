extends WeaponBase
class_name MeleeWeapon

func fire():
	if not can_fire:
		return
	if Global and not Global.can_use_weapon():
		return

	can_fire = false
	if Global:
		Global.start_weapon_cooldown(fire_rate)
	print("Melee attack")
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true
