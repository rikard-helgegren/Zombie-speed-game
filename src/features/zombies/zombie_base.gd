extends CharacterBody2D
class_name ZombieBase

@export var move_speed: float = 0 #120.0
@export var max_health: int = 3
@export var death_sound: AudioStream
@export var hit_sound: AudioStream

@onready var hitbox: Hitbox = $Hitbox


signal zombie_died

var health: int

var target: Node2D
var sprite: Sprite2D = null

enum ZombieState {
	IDLE,
	WALK,
	ATTACK,
	DIE
}

func _ready():
	sprite = get_node_or_null("Sprite2D")
	health = max_health
	target = get_tree().get_first_node_in_group("Player")
	# assign first node in "player" group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
	print("Zombie ready, target =", target)

func _physics_process(_delta):
	if not target:
		return
		
func _process(delta: float) -> void:
	
	if state == new_state:
		return
	else:
		state = new_state
		match state:
			ZombieState.IDLE:
				idle_state()
			ZombieState.WALK:
				walk_state(delta)
			ZombieState.ATTACK:
				attack_state()
			ZombieState.DIE:
				die_state()

	var dir = (target.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()

func take_damage(amount: int):
	health -= amount
	print("Monster HP -" + str(amount))
	await get_tree().create_timer(0.1).timeout #await to make look better when bullet travels
	play_sound(hit_sound)
	
	if hitbox:
		hitbox.feedback_expand()
		
	if health <= 0:
		die()

func die():
	emit_signal("zombie_died")
	queue_free()


func play_sound(sound : AudioStream):
	var player = preload("res://src/systems/sound/sound_player.tscn").instantiate()
	get_tree().current_scene.add_child(player)
	
	player.play(sound, global_position, 0.0)


func idle_state():
	play_animation("idle")
	if player_detected:
		change_state(ZombieState.WALK)

func walk_state(delta):
	play_animation("walk")
	move_towards_player(delta)
	if in_attack_range:
		change_state(ZombieState.ATTACK)

func attack_state():
	play_animation("attack")
	if not in_attack_range:
		change_state(ZombieState.WALK)

func die_state():
	play_animation("die")
