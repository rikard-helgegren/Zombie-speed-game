extends CharacterBody2D
class_name ZombieBase

@export var move_speed: float = 120.0
@export var max_health: int = 3
@export var death_sound: AudioStream
@export var hit_sound: AudioStream
@export var attack_range: float = 30.0
@export var detection_range: float = 300.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.0  

@onready var hitbox: Hitbox = $Hitbox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

signal zombie_died


var _can_attack: bool = true
var is_alive := true

var health: int
var target: Node2D = null

var heard_sound_position: Vector2
var has_heard_sound: bool = false

# FSM
enum ZombieState { IDLE, WALK, ATTACK, DIE }
var state: ZombieState = ZombieState.IDLE
var new_state: ZombieState = ZombieState.IDLE

func _ready():
	health = max_health
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
	print("Zombie ready, target =", target)
	MySoundEventSystem.sound_emitted.connect(_on_sound_emitted)

func _physics_process(_delta):
	if not target:
		return

	# State transitions
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


func move_zombie():
		# Movement (only if walking)
	if state == ZombieState.WALK:
		var target_pos: Vector2
		if has_heard_sound:
			target_pos = heard_sound_position
		else:
			target_pos = target.global_position

		var dir = (target_pos - global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()

	# If reached sound location
	if has_heard_sound and global_position.distance_to(heard_sound_position) < 10.0:
		has_heard_sound = false
		change_state(ZombieState.IDLE)


func take_damage(amount: int):
	health -= amount
	print("Zombie HP -" + str(amount))
	if hitbox:
		hitbox.feedback_expand()
	play_sound(hit_sound)
	
	if health <= 0:
		change_state(ZombieState.DIE)

func die():
	emit_signal("zombie_died")
	queue_free()

func play_sound(sound : AudioStream):
	var player = preload("res://src/systems/sound/sound_player.tscn").instantiate()
	get_tree().current_scene.add_child(player)
	player.play(sound, global_position, 0.0)

# --- State functions ---
func idle_state():
	sprite.play("idle")
	if player_in_range(detection_range):
		change_state(ZombieState.WALK)

func walk_state():
	sprite.play("walk")
	if player_in_range(attack_range):
		has_heard_sound = false
		change_state(ZombieState.ATTACK)

func attack_state():
	sprite.play("attack")
	if not player_in_range(attack_range):
		change_state(ZombieState.WALK)
		
	velocity = Vector2.ZERO  # stop moving during attack

	if _can_attack and player_in_range(attack_range):
		deal_damage_to_player()
		_can_attack = false
		# cooldown timer
		var t = Timer.new()
		t.one_shot = true
		t.wait_time = attack_cooldown
		add_child(t)
		t.start()
		t.timeout.connect(Callable(self, "_on_attack_cooldown_finished"))

func die_state():
	sprite.play("die")
	velocity = Vector2.ZERO  # stop moving
	set_physics_process(false) 	# Freeze movement handled in _physics_process
	#Note: calls die() when animation quits

# --- Utility ---
func change_state(new: ZombieState):
	if state == new:
		return
	state = new

func player_in_range(range: float) -> bool:
	if not target:
		return false
	return global_position.distance_to(target.global_position) <= range


func _on_animation_finished() -> void:
	if state == ZombieState.DIE:
		print("animation finished, die")
		die()

func deal_damage_to_player():
	if not target:
		return
	# Check if target has a PlayerHealth node
	if target.has_node("player_health"):
		var health_node = target.get_node("player_health") as PlayerHealth
		health_node.take_damage(attack_damage)


func _on_animation_looped() -> void:
	if  state == ZombieState.ATTACK:
		_can_attack = true

func _on_sound_emitted(sound_pos: Vector2, radius: float):
	if not is_alive:
		return

	var dist = global_position.distance_to(sound_pos)
	if dist > radius:
		return

	# Zombie heard the sound
	heard_sound_position = sound_pos
	has_heard_sound = true

	# Switch to hunt / investigate state
	change_state(ZombieState.WALK) # or HUNT_PLAYER later
