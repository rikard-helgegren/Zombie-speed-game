extends CharacterBody2D
class_name ZombieBase

@export var move_speed: float = 120.0
@export var max_health: int = 4
@export var death_sound: AudioStream
@export var hit_sound: AudioStream
@export var attack_range: float = 30.0
@export var detection_range: float = 300.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.0  
@export var recoil_strength: float = 220.0
@export var recoil_duration: float = 0.06
@export var groan_sound: AudioStream
@export var groan_enabled := true
@export var groan_start_distance: float = 600.0
@export var groan_full_distance: float = 180.0
@export var groan_min_db: float = -28.0
@export var groan_max_db: float = -8.0
@export var groan_fade_speed: float = 6.0
@export var groan_cooldown_min: float = 2.0
@export var groan_cooldown_max: float = 5.0

const TAKE_DAMAGE_SOUNDS_DIR := "res://src/assets/audio/zombie_sounds/take-damage"

@onready var hitbox: Hitbox = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var body_collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var hit_splatter: Node2D = $HitSplatter

signal zombie_died


var _can_attack: bool = true
var can_deal_damage_on_frame := false
var is_alive := true

var health: int
var target: Node2D = null

var heard_sound_position: Vector2
var has_heard_sound: bool = false

var recoil_velocity: Vector2 = Vector2.ZERO
var recoil_time_left: float = 0.0
var grapple_velocity: Vector2 = Vector2.ZERO
var grapple_active := false
var _take_damage_sounds: Array[AudioStream] = []
var _rng := RandomNumberGenerator.new()
var _groan_player: AudioStreamPlayer2D = null
var _groan_base_db: float = 0.0
var _groan_base_pitch: float = 1.0
var _groan_target_db: float = -80.0
var _groan_cooldown_timer: float = 0.0

const FACING_EPSILON := 0.01
const NAV_UPDATE_INTERVAL := 0.2
const DIE_SPRITE_OFFSET := Vector2(40.0, 0.0)
var hitbox_shape_default_position: Vector2
var hitbox_shape_default_rotation: float
var body_collision_shape_default_position: Vector2
var body_collision_shape_default_rotation: float
var facing_pivot_x: float
var _nav_update_timer := 0.0
var attack_timer: Timer
var _collision_extra_offset := Vector2.ZERO

# FSM
enum ZombieState { IDLE, WALK, ATTACK, DIE }
var state: ZombieState = ZombieState.IDLE
var new_state: ZombieState = ZombieState.IDLE


func _ready():
	health = max_health
	_rng.randomize()
	_load_take_damage_sounds()
	_init_groan_player()
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
	if hitbox_shape:
		hitbox_shape_default_position = hitbox_shape.position
		hitbox_shape_default_rotation = hitbox_shape.rotation
	if body_collision_shape:
		body_collision_shape_default_position = body_collision_shape.position
		body_collision_shape_default_rotation = body_collision_shape.rotation
	if sprite:
		facing_pivot_x = sprite.position.x
	if hit_splatter:
		hit_splatter.top_level = true
		hit_splatter.visible = false
	MySoundEventSystem.sound_emitted.connect(_on_sound_emitted)
	sprite.frame_changed.connect(_on_sprite_frame_changed)

	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_cooldown_finished)
	add_child(attack_timer)

	
func _physics_process(delta):
	if target == null:
		target = get_tree().get_first_node_in_group("player")
		if target == null:
			return

	if state == ZombieState.WALK:
		_nav_update_timer += delta
		if _nav_update_timer >= NAV_UPDATE_INTERVAL:
			_nav_update_timer = 0.0
			update_navigation_target()

		if agent.is_navigation_finished():
			if has_heard_sound:
				has_heard_sound = false
				if not player_in_range(detection_range * 2):
					change_state(ZombieState.IDLE)

	_update_groan_audio(delta)

	match state:
		ZombieState.IDLE:
			idle_state()
		ZombieState.WALK:
			walk_state()
		ZombieState.ATTACK:
			attack_state()
		ZombieState.DIE:
			die_state()

	move_zombie()

func update_navigation_target():
	# Point agent toward sound or player, whichever takes priority
	if has_heard_sound:
		agent.target_position = heard_sound_position
	elif target:
		agent.target_position = target.global_position

func move_zombie():
	if recoil_time_left > 0.0:
		update_facing_from_x(recoil_velocity.x)
		velocity = recoil_velocity
		recoil_time_left -= get_physics_process_delta_time()
		move_and_slide()
		return

	if grapple_active:
		update_facing_from_x(grapple_velocity.x)
		velocity = grapple_velocity
		move_and_slide()
		return

	if state != ZombieState.WALK:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var next_pos := agent.get_next_path_position()
	var dir := next_pos - global_position

	if dir.length() > 1.0:
		dir = dir.normalized()
		update_facing_from_x(dir.x)
		velocity = dir * (move_speed + 50 * Global.zombies_extra_speed)
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func apply_grapple_pull(direction: Vector2, speed: float) -> void:
	grapple_velocity = direction.normalized() * speed
	grapple_active = true


func clear_grapple_pull() -> void:
	grapple_active = false

func update_facing_from_x(x_direction: float) -> void:
	if absf(x_direction) <= FACING_EPSILON:
		return

	var facing_left := x_direction < 0.0
	sprite.flip_h = facing_left

	# Mirror hitbox and body collision when zombie turns
	if not hitbox_shape or not body_collision_shape:
		return

	_apply_collision_from_facing(facing_left, _collision_extra_offset)

func _apply_collision_from_facing(facing_left: bool, extra_offset: Vector2) -> void:
	if not hitbox_shape or not body_collision_shape:
		return

	var base_hitbox_pos := hitbox_shape_default_position + extra_offset
	var base_body_pos := body_collision_shape_default_position + extra_offset
	var mirrored_hitbox_x := (2.0 * facing_pivot_x) - base_hitbox_pos.x if facing_left else base_hitbox_pos.x
	hitbox_shape.position.x = mirrored_hitbox_x
	hitbox_shape.position.y = base_hitbox_pos.y
	hitbox_shape.rotation = -hitbox_shape_default_rotation if facing_left else hitbox_shape_default_rotation

	var hitbox_x_delta := mirrored_hitbox_x - base_hitbox_pos.x
	body_collision_shape.position.x = base_body_pos.x + hitbox_x_delta
	body_collision_shape.position.y = base_body_pos.y
	body_collision_shape.rotation = -body_collision_shape_default_rotation if facing_left else body_collision_shape_default_rotation


func take_damage(amount: int, hit_dir: Vector2):
	health -= amount
	if hitbox:
		hitbox.feedback_expand()
	play_sound(hit_sound)
	var damage_sound := _get_random_damage_sound()
	if damage_sound:
		play_sound(damage_sound, 0.2)
	
	change_state(ZombieState.WALK)
	
	apply_recoil(hit_dir)
	
	if health <= 0:
		change_state(ZombieState.DIE)

func die():
	var world := get_tree().get_first_node_in_group("world")
	if world:
		world.on_zombie_died()

	emit_signal("zombie_died")
	queue_free()

func play_sound(sound : AudioStream, delay := 0.0):
	var player = preload("res://src/systems/sound/sound_player.tscn").instantiate()
	get_tree().current_scene.add_child(player)
	player.play(sound, global_position, delay)

func _init_groan_player() -> void:
	if not groan_enabled:
		return
	var stream := groan_sound
	if stream == null and AudioManager:
		var path := AudioManager.get_clip_path("sfx_zombie_groan")
		if path != "":
			stream = load(path)
	if stream == null:
		return
	if "loop" in stream:
		stream.loop = false
	_groan_player = AudioStreamPlayer2D.new()
	_groan_player.name = "GroanPlayer"
	_groan_player.stream = stream
	_groan_player.autoplay = false
	_groan_player.volume_db = -80.0
	add_child(_groan_player)
	_groan_base_db = _groan_player.volume_db
	_groan_base_pitch = _groan_player.pitch_scale

func _update_groan_audio(delta: float) -> void:
	if not groan_enabled or not is_alive:
		return
	if _groan_player == null:
		return
	if target == null:
		return
	if state == ZombieState.WALK:
		_groan_target_db = -80.0
		_groan_player.stop()
		_groan_cooldown_timer = 0.0
		return

	_groan_target_db = _compute_groan_target_db()
	var clip_db := 0.0
	var clip_pitch := 1.0
	if AudioManager:
		clip_db = AudioManager.get_sfx_clip_db(_groan_player.stream)
		clip_pitch = AudioManager.get_sfx_clip_pitch(_groan_player.stream)
	var sfx_offset := AudioManager.get_sfx_volume_db_offset() if AudioManager else 0.0
	var target_db := _groan_target_db + sfx_offset + clip_db
	_groan_player.volume_db = lerp(_groan_player.volume_db, target_db, clamp(groan_fade_speed * delta, 0.0, 1.0))
	_groan_player.pitch_scale = _groan_base_pitch * clip_pitch
	_groan_cooldown_timer -= delta
	if _groan_cooldown_timer <= 0.0 and not _groan_player.playing:
		_groan_player.play()
		_groan_cooldown_timer = _rng.randf_range(groan_cooldown_min, groan_cooldown_max)

func _compute_groan_target_db() -> float:
	var dist := global_position.distance_to(target.global_position)
	var range: float = maxf(groan_start_distance - groan_full_distance, 0.001)
	var t : float = clamp((groan_start_distance - dist) / range, 0.0, 1.0)
	return lerp(groan_min_db, groan_max_db, t)

func _load_take_damage_sounds() -> void:
	_take_damage_sounds.clear()
	var dir := DirAccess.open(TAKE_DAMAGE_SOUNDS_DIR)
	if dir == null:
		push_warning("ZombieBase: missing take-damage sounds dir: %s" % TAKE_DAMAGE_SOUNDS_DIR)
		return
	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if not file_name.to_lower().ends_with(".mp3"):
			continue
		var stream := load("%s/%s" % [TAKE_DAMAGE_SOUNDS_DIR, file_name])
		if stream:
			_take_damage_sounds.append(stream)
	dir.list_dir_end()

func _get_random_damage_sound() -> AudioStream:
	if _take_damage_sounds.is_empty():
		return null
	return _take_damage_sounds[_rng.randi_range(0, _take_damage_sounds.size() - 1)]

# --- State Functions ---
func idle_state():
	sprite.play("idle")
	if player_in_range(detection_range):
		has_heard_sound = false
		change_state(ZombieState.WALK)

func walk_state():
	sprite.play("walk")
	if player_in_range(attack_range):
		change_state(ZombieState.ATTACK)
	# Detect player within 2x range to switch from heard sound to direct chase
	elif player_in_range(detection_range * 2):
		has_heard_sound = false
	
	if not player_in_range(detection_range * 2) and not has_heard_sound:
		change_state(ZombieState.IDLE)

func attack_state():
	sprite.play("attack")

	if not player_in_range(attack_range):
		_can_attack = true
		attack_timer.stop()  # Cancel cooldown
		change_state(ZombieState.WALK)
		return
		
	velocity = Vector2.ZERO

	if _can_attack:
		can_deal_damage_on_frame = true
		_can_attack = false
		attack_timer.start()

func die_state():
	is_alive = false
	recoil_time_left = 0.0
	sprite.play("die")
	velocity = Vector2.ZERO 

# --- Utility ---
func change_state(new_state: ZombieState):
	if state == new_state:
		return

	state = new_state

	if state == ZombieState.DIE:
		_collision_extra_offset = DIE_SPRITE_OFFSET
		if sprite:
			sprite.offset = DIE_SPRITE_OFFSET
		if sprite:
			_apply_collision_from_facing(sprite.flip_h, _collision_extra_offset)
	else:
		_collision_extra_offset = Vector2.ZERO
		if sprite:
			sprite.offset = Vector2.ZERO

	if state == ZombieState.WALK:
		_nav_update_timer = NAV_UPDATE_INTERVAL
		update_navigation_target()

func player_in_range(range_to_player: float) -> bool:
	if target == null:
		return false
	return global_position.distance_to(target.global_position) <= range_to_player

func _on_attack_cooldown_finished():
	_can_attack = true

func _on_animation_finished() -> void:
	if state == ZombieState.DIE:
		die()

func deal_damage_to_player():
	if target == null:
		return

	var health_node := target.get_node_or_null("player_health") as PlayerHealth
	if health_node:
		health_node.take_damage(attack_damage)

func _on_sprite_frame_changed():
	if state == ZombieState.ATTACK and sprite.animation == "attack" and sprite.frame == 3 and can_deal_damage_on_frame:
		deal_damage_to_player()
		can_deal_damage_on_frame = false

func _on_animation_looped() -> void:
	if  state == ZombieState.ATTACK:
		_can_attack = true

func _on_sound_emitted(sound_pos: Vector2, radius: float):
	if not is_alive:
		return

	if global_position.distance_to(sound_pos) > radius:
		return

	# Zombie heard the sound
	heard_sound_position = sound_pos
	has_heard_sound = true

	# Switch to hunt / investigate state
	change_state(ZombieState.WALK) # or HUNT_PLAYER later


func apply_recoil(hit_dir: Vector2):
	recoil_velocity = hit_dir.normalized() * recoil_strength
	recoil_time_left = recoil_duration
	
	
func show_hit_splatter(pos: Vector2, hit_dir: Vector2) -> void:
	hit_splatter.global_position = pos + hit_dir * 0.4
	hit_splatter.visible = true
	await get_tree().create_timer(0.1).timeout
	hit_splatter.visible = false
