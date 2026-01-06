extends Node2D
class_name WeaponBase

@export var fire_rate: float = 0.3
@export var damage: int = 1

@onready var muzzle: MuzzleFlash = $Muzzle
@onready var default_muzzle_pos := muzzle.position

var can_fire := true
var aim_direction := Vector2.RIGHT
var facing_left := false


var sprite: Sprite2D = null

func _ready():
	sprite = get_node_or_null("Sprite2D")  # child can have it

func set_aim_direction(direction: Vector2):
	if direction.length() == 0:
		return

	aim_direction = direction.normalized()
	rotation = aim_direction.angle()

	# Flip sprite when aiming left
	if sprite:
		sprite.flip_v = abs(rad_to_deg(rotation)) > 90
	
		
func fire():
	# To be overridden by child weapons
	print("Base weapon fire")
	#pass


func hitscan_fire(damage: int, max_distance := 1000.0):
	print("hitscan")
	var space_state = get_world_2d().direct_space_state
	
	var muzzle = get_node_or_null("Muzzle")
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
			if not collider.get_parent().has_method("take_damage"):
				print("Error: hitbox parrent is missing take_damage function")
			collider.get_parent().take_damage(damage)
