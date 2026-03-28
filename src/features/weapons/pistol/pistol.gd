extends WeaponBase
class_name Pistol

# Fire rate and damage is set in inspector
func _init() -> void:
	fire_rate = 0.5 - minf(0.4, 0.1 * Global.player_fire_rate_modifier)
	damage = 2 + Global.player_damage_modifier
	max_ammo = 3 + Global.player_ammo_modifier
	
	ammo = max_ammo
	

@onready var muzzle_flash: MuzzleFlash = $Muzzle


func fire():
	if not can_fire:
		return
	if Global and not Global.can_use_weapon():
		return
	
	if reloading:
		return
		
	if ammo <= 0:
		$EmptyShot.play()
		return

	can_fire = false
	if Global:
		Global.start_weapon_cooldown(fire_rate)

	if muzzle_flash:
		muzzle_flash.flash()
		
	consume_ammo()
		
	$Shoot.play()
	MySoundEventSystem.sound_emitted.emit(
		global_position,
		sound_radius
	)

	apply_recoil()
	hitscan_fire(damage)

	await get_tree().create_timer(fire_rate).timeout
	can_fire = true
	
