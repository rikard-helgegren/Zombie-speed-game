extends Node2D
class_name GrapplingHook

@export var max_distance: float = 900.0
@export var pull_speed: float = 700.0
@export var stop_distance: float = 24.0
@export var cooldown_time: float = 5.0
@export var pull_delay_time: float = 0.1
@export var hook_travel_speed: float = 1800.0

@onready var rope_root: Node2D = $RopeRoot
@onready var rope: Line2D = $RopeRoot/Rope
@onready var hook_sprite: Sprite2D = $Hook
@onready var gun_sprite: Sprite2D = $Gun
@onready var gun_and_hook_sprite: Sprite2D = $GunAndHook
@onready var hook_connection: Node2D = $Hook/ConectionPointHook
@onready var gun_connection: Node2D = $Gun/ConnectionpiontGun
@onready var fire_whoosh_sfx: AudioStreamPlayer2D = $FireWhoosh
@onready var hit_object_sfx: AudioStreamPlayer2D = $HitObject
@onready var reel_tighten_sfx: AudioStreamPlayer2D = $ReelTighten

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
var _pull_delay_remaining := 0.0
var _sfx_players: Array[AudioStreamPlayer2D] = []
var _sfx_base_db: Dictionary = {}
var _sfx_base_pitch: Dictionary = {}
var _last_delta := 0.0
var _hook_traveling := false
var _hook_retracting := false
var _hook_position := Vector2.ZERO
var _retract_wait_remaining := 0.0
var _retract_time_remaining := 0.0
var _missed_shot := false
var _missed_shot_origin := Vector2.ZERO
var _pending_target_body: Node2D
var _pending_target_local_point := Vector2.ZERO
var _pending_damage_target: Node2D
var _pending_hit_is_zombie := false

const MISSED_SHOT_DISTANCE_FACTOR := 0.7
const MISSED_SHOT_HOLD_TIME := 0.1
const MISSED_SHOT_RETRACT_TIME := 0.3


func _ready() -> void:
	rope.visible = false
	rope_root.visible = false
	rope_root.y_sort_enabled = true
	rope.z_index = 0
	hook_sprite.visible = false
	gun_sprite.visible = false
	gun_and_hook_sprite.visible = false
	_equipped_offset = gun_and_hook_sprite.position
	_equipped_offset_base = gun_and_hook_sprite.position
	if gun_connection:
		_gun_connection_base = gun_connection.position
	rope_root.top_level = false
	hook_sprite.top_level = false
	gun_sprite.top_level = false
	gun_and_hook_sprite.top_level = false
	
	var scene := get_tree().current_scene
	var rope_parent: Node = null
	if scene:
		rope_parent = scene.get_node_or_null("World/Current_level")
		if rope_parent == null:
			rope_parent = scene.get_node_or_null("World/Level")
		if rope_parent == null:
			rope_parent = scene.get_node_or_null("World")
	if rope_parent and rope_root.get_parent() != rope_parent:
		rope_root.get_parent().remove_child(rope_root)
		rope_parent.add_child(rope_root)
	_init_sfx_players()
	if reel_tighten_sfx and reel_tighten_sfx.stream and "loop" in reel_tighten_sfx.stream:
		reel_tighten_sfx.stream.loop = true


func _exit_tree() -> void:
	if AudioManager and AudioManager.sfx_volume_changed.is_connected(_on_sfx_volume_changed):
		AudioManager.sfx_volume_changed.disconnect(_on_sfx_volume_changed)
	if is_instance_valid(rope_root):
		rope_root.queue_free()


func _process(delta: float) -> void:
	_last_delta = delta
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if _pull_delay_remaining > 0.0:
		_pull_delay_remaining = maxf(_pull_delay_remaining - delta, 0.0)
	if _retract_wait_remaining > 0.0:
		_retract_wait_remaining = maxf(_retract_wait_remaining - delta, 0.0)
	if _retract_time_remaining > 0.0:
		_retract_time_remaining = maxf(_retract_time_remaining - delta, 0.0)


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
	_play_sfx(fire_whoosh_sfx)

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
		_start_missed_shot(origin, direction)
		return true

	var collider = result.collider
	var grapple_target: Node2D = collider
	var hit_is_zombie := false
	if collider is Hitbox:
		grapple_target = collider.get_parent() as Node2D
		if grapple_target and grapple_target.has_method("take_damage"):
			hit_is_zombie = true

	if not _can_grapple_to_collider(grapple_target):
		_start_missed_shot(origin, direction)
		return true

	active = true
	_active_origin_offset = _equipped_offset
	target_point = result.position
	_pull_delay_remaining = 0.0
	_hook_traveling = true
	_hook_retracting = false
	_hook_position = origin
	_retract_wait_remaining = 0.0
	_missed_shot = false
	_pending_damage_target = grapple_target
	_pending_hit_is_zombie = hit_is_zombie
	gun_and_hook_sprite.visible = false
	gun_sprite.visible = true
	hook_sprite.top_level = true

	if grapple_target is Node2D:
		_pending_target_body = grapple_target
		_pending_target_local_point = grapple_target.to_local(target_point)
	else:
		_pending_target_body = null

	update_visuals(origin)
	return true


func update_visuals(origin: Vector2) -> void:
	if not active:
		rope.visible = false
		rope_root.visible = false
		_refresh_in_hand_visuals()
		_stop_reel_sfx()
		return

	if _missed_shot and _retract_wait_remaining <= 0.0 and not _hook_traveling and not _hook_retracting:
		_hook_retracting = true
		_retract_time_remaining = MISSED_SHOT_RETRACT_TIME
	if _missed_shot and _hook_retracting and _retract_time_remaining <= 0.0:
		_missed_shot = false
		cancel()
		return

	var target_position := get_target_position()
	if _hook_retracting:
		target_position = _missed_shot_origin
	if _hook_traveling or _hook_retracting:
		_update_hook_travel(origin, target_position)
		target_position = _hook_position
	hook_sprite.global_position = target_position
	var rope_start := gun_connection.global_position if gun_connection else origin
	var rope_end := hook_connection.global_position if hook_connection else hook_sprite.global_position
	rope_root.global_position = rope_start
	rope.points = PackedVector2Array([Vector2.ZERO, rope_end - rope_start])
	rope.visible = true
	rope_root.visible = true

	hook_sprite.rotation = (target_position - origin).angle()
	hook_sprite.visible = true
	_update_reel_sfx(origin)


func get_target_position() -> Vector2:
	if _hook_traveling and is_instance_valid(_pending_target_body):
		target_point = _pending_target_body.to_global(_pending_target_local_point)
	if is_instance_valid(target_body):
		target_point = target_body.to_global(target_local_point)
	return target_point


func cancel() -> void:
	active = false
	_pull_delay_remaining = 0.0
	_hook_traveling = false
	_hook_retracting = false
	_retract_wait_remaining = 0.0
	_retract_time_remaining = 0.0
	_missed_shot = false
	_missed_shot_origin = Vector2.ZERO
	_clear_target_pull()
	target_body = null
	_pending_target_body = null
	_pending_damage_target = null
	_pending_hit_is_zombie = false
	rope.visible = false
	rope_root.visible = false
	rope.points = PackedVector2Array()
	_refresh_in_hand_visuals()
	_stop_reel_sfx()


func _can_grapple_to_collider(collider: Variant) -> bool:
	if collider == null:
		return false
	return collider is PhysicsBody2D or collider is TileMapLayer


func apply_target_pull(player_position: Vector2) -> void:
	if not active or target_body == null:
		return
	if _hook_traveling:
		return
	if _pull_delay_remaining > 0.0:
		return
	if target_body.has_method("apply_grapple_pull"):
		var target_position := get_target_position()
		var pull_dir := (player_position - target_position)
		target_body.apply_grapple_pull(pull_dir, pull_speed)


func is_pull_ready() -> bool:
	return _pull_delay_remaining <= 0.0 and not _hook_traveling and not _hook_retracting


func should_pull_player() -> bool:
	return active and not _missed_shot


func _update_hook_travel(origin: Vector2, target_position: Vector2) -> void:
	var to_target := target_position - _hook_position
	var distance := to_target.length()
	if distance <= 0.001:
		if _hook_retracting:
			return
		_finish_hook_travel(origin, target_position)
		return
	var step := hook_travel_speed * maxf(_last_delta, 0.0)
	if step >= distance:
		if _hook_retracting:
			_hook_position = target_position
			return
		_finish_hook_travel(origin, target_position)
		return
	_hook_position += to_target * (step / distance)


func _finish_hook_travel(origin: Vector2, target_position: Vector2) -> void:
	_hook_traveling = false
	_hook_retracting = false
	_hook_position = target_position
	if _missed_shot:
		if target_position.distance_to(_missed_shot_origin) <= 0.001:
			_missed_shot = false
			cancel()
			return
		_retract_wait_remaining = MISSED_SHOT_HOLD_TIME
		return
	if _pending_hit_is_zombie:
		if is_instance_valid(_pending_damage_target) and _pending_damage_target.has_method("take_damage"):
			var hit_dir := (target_position - origin).normalized()
			_pending_damage_target.take_damage(1, hit_dir)
	else:
		_play_sfx(hit_object_sfx)
	if is_instance_valid(_pending_target_body):
		target_body = _pending_target_body
		target_local_point = _pending_target_body.to_local(target_position)
	else:
		target_body = null
	_pending_target_body = null
	_pending_damage_target = null
	_pending_hit_is_zombie = false
	_pull_delay_remaining = maxf(pull_delay_time, 0.0)


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


func _init_sfx_players() -> void:
	_sfx_players.clear()
	_sfx_base_db.clear()
	_sfx_base_pitch.clear()
	var players: Array[AudioStreamPlayer2D] = [fire_whoosh_sfx, hit_object_sfx, reel_tighten_sfx]
	for player in players:
		if player == null:
			continue
		_sfx_players.append(player)
		_sfx_base_db[player.get_instance_id()] = player.volume_db
		_sfx_base_pitch[player.get_instance_id()] = player.pitch_scale
	_apply_sfx_volume()
	if AudioManager and not AudioManager.sfx_volume_changed.is_connected(_on_sfx_volume_changed):
		AudioManager.sfx_volume_changed.connect(_on_sfx_volume_changed)


func _on_sfx_volume_changed(_value: float) -> void:
	_apply_sfx_volume()


func _apply_sfx_volume() -> void:
	var offset_db := AudioManager.get_sfx_volume_db_offset() if AudioManager else 0.0
	for player in _sfx_players:
		if not is_instance_valid(player):
			continue
		var base_db = _sfx_base_db.get(player.get_instance_id(), player.volume_db)
		var base_pitch = _sfx_base_pitch.get(player.get_instance_id(), player.pitch_scale)
		player.volume_db = base_db + offset_db + (AudioManager.get_sfx_clip_db(player.stream) if AudioManager else 0.0)
		player.pitch_scale = base_pitch * (AudioManager.get_sfx_clip_pitch(player.stream) if AudioManager else 1.0)


func _play_sfx(player: AudioStreamPlayer2D) -> void:
	if not is_instance_valid(player):
		return
	var offset_db := AudioManager.get_sfx_volume_db_offset() if AudioManager else 0.0
	var base_db = _sfx_base_db.get(player.get_instance_id(), player.volume_db)
	var base_pitch = _sfx_base_pitch.get(player.get_instance_id(), player.pitch_scale)
	player.volume_db = base_db + offset_db + (AudioManager.get_sfx_clip_db(player.stream) if AudioManager else 0.0)
	player.pitch_scale = base_pitch * (AudioManager.get_sfx_clip_pitch(player.stream) if AudioManager else 1.0)
	player.play()


func _update_reel_sfx(origin: Vector2) -> void:
	if not is_instance_valid(reel_tighten_sfx):
		return
	if _hook_traveling or _hook_retracting:
		if reel_tighten_sfx.playing:
			reel_tighten_sfx.stop()
		return
	var target_position := get_target_position()
	var should_reel := target_position.distance_to(origin) > stop_distance
	if should_reel:
		if not reel_tighten_sfx.playing:
			_play_sfx(reel_tighten_sfx)
	else:
		if reel_tighten_sfx.playing:
			reel_tighten_sfx.stop()


func _stop_reel_sfx() -> void:
	if is_instance_valid(reel_tighten_sfx) and reel_tighten_sfx.playing:
		reel_tighten_sfx.stop()


func _start_missed_shot(origin: Vector2, direction: Vector2) -> void:
	active = true
	_active_origin_offset = _equipped_offset
	target_point = origin + direction.normalized() * max_distance * MISSED_SHOT_DISTANCE_FACTOR
	_pull_delay_remaining = 0.0
	_hook_traveling = true
	_hook_retracting = false
	_hook_position = origin
	_retract_wait_remaining = 0.0
	_retract_time_remaining = 0.0
	_missed_shot = true
	_missed_shot_origin = origin
	_pending_target_body = null
	_pending_damage_target = null
	_pending_hit_is_zombie = false
	target_body = null
	gun_and_hook_sprite.visible = false
	gun_sprite.visible = true
	hook_sprite.top_level = true
	update_visuals(origin)
