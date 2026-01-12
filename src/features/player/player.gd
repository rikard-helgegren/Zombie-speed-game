extends CharacterBody2D
class_name Player

@export var speed: float = 1000.0
@export var default_weapon_scene: PackedScene

var move_direction = Vector2.ZERO


# References to child components
@onready var input_node: PlayerInput = $player_input
@onready var health_node: PlayerHealth = $player_health
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon_pivot: Node2D = $WeaponPivot
var weapon: WeaponBase

enum PlayerState { IDLE, WALK, ATTACK, DIE }
var state: PlayerState = PlayerState.IDLE
var new_state: PlayerState = PlayerState.IDLE
var is_alive := true

var max_ammo := 10
var ammo: int = max_ammo


func _ready():
	# Connect input signals
	input_node.move_input.connect(Callable(self, "_on_move_input"))
	input_node.action_input.connect(Callable(self, "_on_action_input"))
	
	# Connect health
	health_node.health_changed.connect(Callable(self, "_on_health_changed"))
	health_node.player_died.connect(Callable(self, "_on_player_died"))
	
	spawn_default_weapon()
	
	EventBus.player_health_changed.emit(health_node.current_health)
	EventBus.player_ammo_changed.emit(weapon.ammo)
	
	
func _physics_process(delta):
	Global.player_position = global_position
	move_player(delta)
	update_weapon_aim()
	
	match state:
		PlayerState.IDLE:
			idle_state()
		PlayerState.WALK:
			walk_state()
		PlayerState.DIE:
			die_state()

# ------------------------
# Input callbacks
# ------------------------
func _on_move_input(direction: Vector2):
	move_direction = direction

func _on_action_input(action_name: String):
	print("action_name: " + str(action_name))
	if is_alive:
		match action_name:
			"shoot":
				shoot()
			"reload":
				weapon.reload()

func move_player(_delta):
	velocity = move_direction * speed
	move_and_slide()


func shoot():
	if weapon:
		weapon.fire()

func _on_player_died():
	print("Player died")
	die_state()
	
	
func update_weapon_aim():
	if weapon == null:
		return

	var aim_direction = (get_global_mouse_position() - global_position).normalized()
	weapon.set_aim_direction(aim_direction)

func spawn_default_weapon():
	if not default_weapon_scene:
		push_warning("No default weapon assigned")
		return

	var weapon_instance = default_weapon_scene.instantiate() as WeaponBase
	weapon_pivot.add_child(weapon_instance)
	weapon = weapon_instance

func get_aim_position() -> Vector2:
	return get_global_mouse_position()

func idle_state():
	sprite.play("idle")
	
	if move_direction.length() > 0.1:
		change_state(PlayerState.WALK)

func walk_state():
	sprite.play("walk")
	if move_direction.length() > 0.1:
		if move_direction.x < 0:
			sprite.flip_h = true   # facing left
		elif move_direction.x > 0:
			sprite.flip_h = false  # facing right
	else:
		change_state(PlayerState.IDLE)
		
	
func die_state():
	if (is_alive):
		is_alive = false
		sprite.play("die")
		
		#TODO: add that wepon falls to ground
		weapon.hide()
		
		velocity = Vector2.ZERO  # stop moving
		set_physics_process(false) 	# Freeze movement handled in _physics_process
		#Note: calls die() when animation quits
	

func change_state(new: PlayerState):
	if state == new:
		return
	state = new



func _on_animation_finished() -> void:
	if state == PlayerState.DIE:
		die()


func die():
	pass
	# End scene, replay, menue etc.
