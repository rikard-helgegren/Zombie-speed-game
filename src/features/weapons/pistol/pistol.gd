extends WeaponBase
class_name Pistol

# Fire rate and damage is set in inspector
func _init() -> void:
	fire_rate = 0.5
	damage = 2

@onready var muzzle_flash: MuzzleFlash = $Muzzle


func fire():
	if not can_fire:
		#$EmptyShot.play()
		return

	can_fire = false

	if muzzle_flash:
		muzzle_flash.flash()
		
	$Shoot.play()

	hitscan_fire(damage)

	await get_tree().create_timer(fire_rate).timeout
	can_fire = true


	
