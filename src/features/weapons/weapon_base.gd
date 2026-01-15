extends Node2D
class_name WeaponBase

@export var fire_rate: float = 0.3
@export var damage: int = 1
@export var max_ammo: int = 3
@export var sound_radius: float = 1000.0 

var sprite: Sprite2D
var muzzle: Node2D
var default_muzzle_pos: Vector2

var aim_direction := Vector2.RIGHT
var can_fire := true
var ammo : int
var facing_left := false
var reloading := false


func _ready():
	sprite = get_node_or_null("Sprite2D")
	muzzle = get_node_or_null("Muzzle")

	if muzzle:
		default_muzzle_pos = muzzle.position
		
	ammo = max_ammo
		
		
func set_aim_direction(direction: Vector2):
	if direction == Vector2.ZERO:
		return

	aim_direction = direction.normalized()
	rotation = aim_direction.angle()

	facing_left = aim_direction.x < 0
	apply_flip()
	
func apply_flip():
	if not sprite:
		return

	# Keep sprite upright
	sprite.flip_v = facing_left

	# Fix muzzle position
	if muzzle:
		muzzle.position = Vector2(
			default_muzzle_pos.x,
			-default_muzzle_pos.y if facing_left else default_muzzle_pos.y
		)
	
		
func fire():
	# To be overridden by child weapons
	pass


func hitscan_fire(damage: int, max_distance := 1000.0):
	var space_state = get_world_2d().direct_space_state
	
	var from = muzzle.global_position if muzzle else global_position
	var to = from + aim_direction * max_distance
	
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [self]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.hit_from_inside = true
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider

		if collider is Hitbox:
			#TODO: unsafe code
			if not collider.get_parent().has_method("take_damage"):
				print("Error: hitbox parrent is missing take_damage function")
				return
				
			var hit_dir = (collider.get_parent().global_position - global_position).normalized()
			collider.get_parent().take_damage(damage, hit_dir)
			collider.get_parent().show_hit_splatter(result.position, hit_dir)
			


func consume_ammo():
	ammo -= 1
	EventBus.player_ammo_changed.emit(ammo)

func reload():
	reloading = true
	ammo = max_ammo
	
	var delay = maxf(0.7 - 0.1 * Global.player_reload_speed_modifier, 0.1)
	$HolsterOff.play()
	await  get_tree().create_timer(delay).timeout
	$HolsterOn.play()
	await  get_tree().create_timer(delay).timeout
	$SafetyOff.play()
	await  get_tree().create_timer(delay).timeout
	reloading = false
	EventBus.player_ammo_changed.emit(ammo)
	
