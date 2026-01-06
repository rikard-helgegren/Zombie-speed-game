extends CharacterBody2D
class_name ZombieBase

@export var move_speed: float = 0 #120.0
@export var max_health: int = 3

@onready var hitbox: Hitbox = $Hitbox

signal zombie_died

var health: int

var target: Node2D
var sprite: Sprite2D = null

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

	var dir = (target.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()

func take_damage(amount: int):
	health -= amount
	print("Monster took damage: " + str(amount))

	if hitbox:
		hitbox.feedback_expand()
		
	if health <= 0:
		die()

func die():
	emit_signal("zombie_died")
	queue_free()
