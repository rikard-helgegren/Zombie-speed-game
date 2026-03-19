extends Node2D
class_name WeaponBase

@export var fire_rate: float = 0.3
@export var damage: int = 1
@export var max_ammo: int = 3
@export var sound_radius: float = 1000.0 
@export_group("Visuals")
@export var recoil_amount: float = 10.0
@export var recoil_return_speed: float = 10.0

var sprite: Sprite2D
var muzzle: Node2D
var default_muzzle_pos: Vector2

var aim_direction := Vector2.RIGHT
var can_fire := true
var ammo : int
var facing_left := false
var reloading := false
var _sfx_players: Array[AudioStreamPlayer2D] = []
var _sfx_base_db: Dictionary = {}
var _sfx_base_pitch: Dictionary = {}
var _current_recoil_offset: float = 0.0


func _ready():
	sprite = get_node_or_null("Sprite2D")
	muzzle = get_node_or_null("Muzzle")

	if muzzle:
		default_muzzle_pos = muzzle.position
		
	ammo = max_ammo
	_init_sfx_players()

func _process(delta: float) -> void:
	if _current_recoil_offset > 0.01:
		_current_recoil_offset = lerp(_current_recoil_offset, 0.0, recoil_return_speed * delta)
		position = -aim_direction * _current_recoil_offset
	elif position != Vector2.ZERO:
		_current_recoil_offset = 0.0
		position = Vector2.ZERO

func _exit_tree() -> void:
	if AudioManager and AudioManager.sfx_volume_changed.is_connected(_on_sfx_volume_changed):
		AudioManager.sfx_volume_changed.disconnect(_on_sfx_volume_changed)

func _init_sfx_players() -> void:
	_sfx_players.clear()
	_sfx_base_db.clear()
	_sfx_base_pitch.clear()
	var players = find_children("*", "AudioStreamPlayer2D", true, false)
	for player in players:
		_sfx_players.append(player)
		_sfx_base_db[player.get_instance_id()] = player.volume_db
		_sfx_base_pitch[player.get_instance_id()] = player.pitch_scale
	_apply_sfx_volume()
	if AudioManager and not AudioManager.sfx_volume_changed.is_connected(_on_sfx_volume_changed):
		AudioManager.sfx_volume_changed.connect(_on_sfx_volume_changed)

func _on_sfx_volume_changed(_value: float) -> void:
	_apply_sfx_volume()

func _apply_sfx_volume() -> void:
	var offset_db = AudioManager.get_sfx_volume_db_offset()
	for player in _sfx_players:
		if not is_instance_valid(player):
			continue
		var base_db = _sfx_base_db.get(player.get_instance_id(), player.volume_db)
		var base_pitch = _sfx_base_pitch.get(player.get_instance_id(), player.pitch_scale)
		player.volume_db = base_db + offset_db + AudioManager.get_sfx_clip_db(player.stream)
		player.pitch_scale = base_pitch * AudioManager.get_sfx_clip_pitch(player.stream)
		
		
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
	
func apply_recoil() -> void:
	_current_recoil_offset = recoil_amount
		
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
				push_error("Error: hitbox parrent is missing take_damage function")
				return
				
			var hit_dir = (collider.get_parent().global_position - global_position).normalized()
			collider.get_parent().take_damage(damage, hit_dir)
			collider.get_parent().show_hit_splatter(result.position, hit_dir)
		else:
			var sfx = AudioStreamPlayer2D.new()
			sfx.stream = load("res://src/assets/audio/sfx/gun/bullet-hit-rock.mp3")
			add_child(sfx)

			if AudioManager:
				var offset_db = AudioManager.get_sfx_volume_db_offset()
				var clip_db = AudioManager.get_sfx_clip_db(sfx.stream)
				var clip_pitch = AudioManager.get_sfx_clip_pitch(sfx.stream)
				sfx.volume_db = offset_db + clip_db
				sfx.pitch_scale = clip_pitch

			sfx.play()
			sfx.finished.connect(sfx.queue_free)
			


func consume_ammo():
	var prev_ammo := ammo
	ammo -= 1
	EventBus.player_ammo_changed.emit(ammo)
	
	if ammo <= 0:
		reload()

func reload():
	reloading = true
	var prev_ammo := ammo
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
	
