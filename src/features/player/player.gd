extends CharacterBody2D
class_name Player

@export var speed: float = 500.0
@export var default_weapon_scene: PackedScene

var move_direction = Vector2.ZERO

# References to child components
@onready var input_node: PlayerInput = $player_input
@onready var health_node: PlayerHealth = $player_health
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon_pivot: Node2D = $WeaponPivot
#@onready var weapon: WeaponBase = $WeaponPivot/Weapon
var weapon: WeaponBase


func _ready():
	# Connect input signals
	 # Connect input
	input_node.move_input.connect(Callable(self, "_on_move_input"))
	input_node.action_input.connect(Callable(self, "_on_action_input"))
	
	# Connect health
	health_node.health_changed.connect(Callable(self, "_on_health_changed"))
	health_node.player_died.connect(Callable(self, "_on_player_died"))
	
	spawn_default_weapon()
	
	
func _physics_process(delta):
	move_player(delta)
	update_animation()
	update_weapon_aim()

# ------------------------
# Input callbacks
# ------------------------
func _on_move_input(direction: Vector2):
	move_direction = direction

func _on_action_input(action_name: String):
	match action_name:
		"attack":
			attack()
		"shoot":
			shoot()

# ------------------------
# Movement
# ------------------------
func move_player(delta):
	velocity = move_direction * speed
	move_and_slide()

# ------------------------
# Example actions
# ------------------------
func attack():
	print("Player attacks")

func shoot():
	if weapon:
		weapon.fire()

# ------------------------
# Health callbacks
# ------------------------
func _on_health_changed(new_health):
	print("Player health:", new_health)
	# You could update HUD here or via signals

func _on_player_died():
	print("Player died")
	queue_free() # or trigger level restart

func update_animation():
	if move_direction.length() > 0.1:
		if sprite.animation != "walk":
			sprite.play("walk")

		# Flip sprite when moving left/right
		if move_direction.x != 0:
			sprite.flip_h = move_direction.x < 0
	else:
		if sprite.animation != "idle":
			sprite.play("idle")
			
func update_weapon_aim():
	var mouse_pos = get_global_mouse_position()
	var direction = mouse_pos - weapon.global_position

	weapon.set_aim_direction(direction)

func spawn_default_weapon():
	if not default_weapon_scene:
		push_warning("No default weapon assigned")
		return

	var weapon_instance = default_weapon_scene.instantiate() as WeaponBase
	weapon_pivot.add_child(weapon_instance)
	weapon = weapon_instance
