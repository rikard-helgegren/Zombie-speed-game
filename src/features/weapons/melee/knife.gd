extends WeaponBase
class_name Knife

signal swing_started
signal swing_finished

@export var swing_arc_degrees: float = 110.0
@export var swing_duration: float = 0.12
@export var swing_cooldown: float = 0.25
@export var swing_range: float = 52.0
@export var swing_radius: float = 34.0
@export var damage_amount: int = 3
@export var wait_in_extreme_position: float = 0.1

var _swinging := false
var _damaged_this_swing: Dictionary = {}
var _hit_any := false
var _flesh_played := false

@onready var air_sfx: AudioStreamPlayer2D = $KnifeAir
@onready var flesh_sfx: AudioStreamPlayer2D = $KnifeFlesh


func _ready() -> void:
	super._ready()
	hide()

func _process(delta: float) -> void:
	if _swinging:
		return
	super._process(delta)

# aka swing
func fire() -> void:
	if _swinging or not can_fire:
		return

	can_fire = false
	_swinging = true
	_damaged_this_swing.clear()
	_hit_any = false
	_flesh_played = false
	show()
	swing_started.emit()

	var arc := deg_to_rad(swing_arc_degrees)
	var start_rot := aim_direction.angle() - arc * 0.5
	var end_rot := aim_direction.angle() + arc * 0.5
	_set_swing_angle(start_rot)

	_apply_swing_damage()
	await get_tree().create_timer(wait_in_extreme_position).timeout

	var tween := create_tween()
	tween.tween_method(_set_swing_angle, start_rot, end_rot, swing_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(swing_duration).timeout
	await get_tree().create_timer(wait_in_extreme_position).timeout
	if not _hit_any:
		_play_air_sfx()
	hide()
	position = Vector2.ZERO
	rotation = 0.0
	_swinging = false
	swing_finished.emit()

	await get_tree().create_timer(swing_cooldown).timeout
	can_fire = true

func _set_swing_angle(angle: float) -> void:
	position = Vector2(cos(angle), sin(angle)) * swing_range
	rotation = angle
	_apply_swing_damage()

func _apply_swing_damage() -> void:
	var space_state = get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = swing_radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position + aim_direction * swing_range)
	query.exclude = [self, get_parent(), get_owner()]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 0x7FFFFFFF

	var results := space_state.intersect_shape(query, 32)

	for result in results:
		var collider = result.collider
		if collider is Hitbox:
			if _damaged_this_swing.has(collider):
				continue
			_damaged_this_swing[collider] = true

			var target = collider.get_parent()
			if not target or not target.has_method("take_damage"):
				push_error("Error: hitbox parrent is missing take_damage function")
				continue

			var hit_dir = (target.global_position - global_position).normalized()
			target.take_damage(damage_amount, hit_dir)
			target.show_hit_splatter(target.global_position, hit_dir)
			_hit_any = true
			if not _flesh_played:
				_flesh_played = true
				_play_flesh_sfx()

func _play_air_sfx() -> void:
	if air_sfx:
		air_sfx.play()

func _play_flesh_sfx() -> void:
	if flesh_sfx:
		flesh_sfx.play()
