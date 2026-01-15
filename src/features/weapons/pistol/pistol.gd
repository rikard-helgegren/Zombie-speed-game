extends WeaponBase
class_name Pistol

# Fire rate and damage is set in inspector
func _init() -> void:
	fire_rate = 0.5 - maxf(0.4, 0.1 * Global.player_fire_rate_modifier)
	damage = 20 #2
	max_ammo = 5 + Global.player_ammo_modifier
	
	ammo = max_ammo
	

@onready var muzzle_flash: MuzzleFlash = $Muzzle


func fire():
	if not can_fire:
		#$EmptyShot.play()
		return
	
	if reloading:
		return
		
	if ammo <= 0:
		$EmptyShot.play()
		return

	can_fire = false

	if muzzle_flash:
		muzzle_flash.flash()
		
	consume_ammo()
		
	$Shoot.play()
	MySoundEventSystem.sound_emitted.emit(
		global_position,
		sound_radius
	)

	hitscan_fire(damage)

	await get_tree().create_timer(fire_rate).timeout
	can_fire = true
