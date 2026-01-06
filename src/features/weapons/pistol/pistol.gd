extends WeaponBase
class_name Pistol


@onready var muzzle_flash: MuzzleFlash = $Muzzle

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
	
	print("muzzle_flash: " + str(muzzle_flash))
	if muzzle_flash:
		muzzle_flash.flash()
	hitscan_fire(damage)

	
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true
	
	
func update_muzzle_position():
	if not muzzle_flash:
		return

	var local_pos = muzzle_flash.position

	# Flip horizontally
	if $Sprite2D.scale.x < 0:
		# Weapon is flipped, mirror Y
		local_pos.y = -abs(local_pos.y)
	else:
		local_pos.y = abs(local_pos.y)

	muzzle_flash.position = local_pos
