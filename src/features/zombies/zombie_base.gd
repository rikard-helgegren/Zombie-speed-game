extends CharacterBody2D
class_name ZombieBase

@export var move_speed: float = 120.0
@export var max_health: int = 3
@export var death_sound: AudioStream
@export var hit_sound: AudioStream
@export var attack_range: float = 30.0
@export var detection_range: float = 300.0

@onready var hitbox: Hitbox = $Hitbox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

signal zombie_died

var health: int
var target: Node2D = null

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

func _physics_process(delta):
	if not target:
		return

	# State transitions
	match state:
		ZombieState.IDLE:
			idle_state()
		ZombieState.WALK:
			walk_state(delta)
		ZombieState.ATTACK:
			attack_state()
		ZombieState.DIE:
			die_state()
	
	# Movement (only if walking)
	if state == ZombieState.WALK:
		var dir = (target.global_position - global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()

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

func walk_state(delta):
	sprite.play("walk")
	if player_in_range(attack_range):
		change_state(ZombieState.ATTACK)

func attack_state():
	sprite.play("attack")
	if not player_in_range(attack_range):
		change_state(ZombieState.WALK)
	# TODO: deal damage on animation frame

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
	print("animation finished, die")
	die()
