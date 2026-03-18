extends Node2D
class_name GrapplingHook

@export var max_distance: float = 900.0
@export var pull_speed: float = 700.0
@export var stop_distance: float = 24.0
@export var cooldown_time: float = 1.2

@onready var rope: Line2D = $Rope
@onready var hook_sprite: Sprite2D = $Hook
@onready var gun_sprite: Sprite2D = $Gun
@onready var gun_and_hook_sprite: Sprite2D = $GunAndHook
@onready var hook_connection: Node2D = $Hook/ConectionPointHook
@onready var gun_connection: Node2D = $Gun/ConnectionpiontGun

var active := false
var selected := false
var target_point := Vector2.ZERO
var target_body: Node2D
var target_local_point := Vector2.ZERO
var _equipped_offset := Vector2.ZERO
var _equipped_offset_base := Vector2.ZERO
var _active_origin_offset := Vector2.ZERO
var _gun_connection_base := Vector2.ZERO
var _cooldown_remaining := 0.0


func _ready() -> void:
	rope.visible = false
	hook_sprite.visible = false
	gun_sprite.visible = false
	gun_and_hook_sprite.visible = false
	_equipped_offset = gun_and_hook_sprite.position
	_equipped_offset_base = gun_and_hook_sprite.position
	if gun_connection:
		_gun_connection_base = gun_connection.position
	rope.top_level = true
	hook_sprite.top_level = false
	gun_sprite.top_level = false
	gun_and_hook_sprite.top_level = false


func _process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


func set_selected(value: bool) -> void:
	if selected == value:
		return

	selected = value
	_refresh_in_hand_visuals()

	if not selected:
		cancel()


func set_aim_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	if active:
		return

	var rotation := direction.angle()
	gun_sprite.rotation = rotation
	gun_and_hook_sprite.rotation = rotation
	var facing_left := direction.x < 0
	gun_sprite.flip_v = facing_left
	gun_and_hook_sprite.flip_v = facing_left
	if gun_connection:
		gun_connection.position.y = -_gun_connection_base.y if facing_left else _gun_connection_base.y
	var rotated_offset := _equipped_offset_base.rotated(rotation)
	_equipped_offset = rotated_offset
	gun_sprite.position = _equipped_offset
	gun_and_hook_sprite.position = _equipped_offset


func get_origin() -> Vector2:
	return gun_connection.global_position if gun_connection else to_global(_equipped_offset)


func fire(direction: Vector2, exclude: Array) -> bool:
	if direction == Vector2.ZERO:
		return false
	if _cooldown_remaining > 0.0:
		return false

	_cooldown_remaining = maxf(cooldown_time, 0.0)

	var origin := get_origin()
	var query := PhysicsRayQueryParameters2D.create(
		origin,
		origin + direction.normalized() * max_distance
	)
	query.exclude = exclude
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result := get_world_2d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		cancel()
		return false

	var collider = result.collider
	var grapple_target: Node2D = collider
	if collider is Hitbox:
		grapple_target = collider.get_parent() as Node2D
		if grapple_target and grapple_target.has_method("take_damage"):
			var hit_dir := (grapple_target.global_position - origin).normalized()
			grapple_target.take_damage(1, hit_dir)

	if not _can_grapple_to_collider(grapple_target):
		cancel()
		return false

	active = true
	_active_origin_offset = _equipped_offset
	target_point = result.position
	gun_and_hook_sprite.visible = false
	gun_sprite.visible = true
	hook_sprite.top_level = true

	if grapple_target is Node2D:
		target_body = grapple_target
		target_local_point = target_body.to_local(target_point)
	else:
		target_body = null

	update_visuals(origin)
	return true


func update_visuals(origin: Vector2) -> void:
	if not active:
		rope.visible = false
		_refresh_in_hand_visuals()
		return

	var target_position := get_target_position()
	hook_sprite.global_position = target_position
	var rope_start := gun_connection.global_position if gun_connection else origin
	var rope_end := hook_connection.global_position if hook_connection else hook_sprite.global_position
	rope.points = PackedVector2Array([rope_start, rope_end])
	rope.visible = true

	hook_sprite.rotation = (target_position - origin).angle()
	hook_sprite.visible = true


func get_target_position() -> Vector2:
	if is_instance_valid(target_body):
		target_point = target_body.to_global(target_local_point)
	return target_point


func cancel() -> void:
	active = false
	_clear_target_pull()
	target_body = null
	rope.visible = false
	rope.points = PackedVector2Array()
	_refresh_in_hand_visuals()


func _can_grapple_to_collider(collider: Variant) -> bool:
	if collider == null:
		return false
	return collider is PhysicsBody2D or collider is TileMapLayer


func apply_target_pull(player_position: Vector2) -> void:
	if not active or target_body == null:
		return
	if target_body.has_method("apply_grapple_pull"):
		var target_position := get_target_position()
		var pull_dir := (player_position - target_position)
		target_body.apply_grapple_pull(pull_dir, pull_speed)


func _clear_target_pull() -> void:
	if target_body and target_body.has_method("clear_grapple_pull"):
		target_body.clear_grapple_pull()


func _refresh_in_hand_visuals() -> void:
	hook_sprite.top_level = false
	hook_sprite.visible = active

	gun_sprite.top_level = false
	gun_and_hook_sprite.top_level = false

	gun_sprite.position = _equipped_offset
	gun_and_hook_sprite.position = _equipped_offset

	if not selected:
		gun_sprite.visible = false
		gun_and_hook_sprite.visible = false
		return

	if active:
		gun_sprite.visible = true
		gun_and_hook_sprite.visible = false
	else:
		gun_sprite.visible = false
		gun_and_hook_sprite.visible = true


func is_on_cooldown() -> bool:
	return _cooldown_remaining > 0.0


func get_cooldown_progress() -> float:
	if cooldown_time <= 0.0:
		return 1.0
	return clampf(1.0 - (_cooldown_remaining / cooldown_time), 0.0, 1.0)


func is_selected() -> bool:
	return selected
