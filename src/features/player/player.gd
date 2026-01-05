extends CharacterBody2D
class_name Player

@export var speed: float = 500.0

var move_direction = Vector2.ZERO

# References to child components
@onready var input_node: PlayerInput = $player_input
@onready var health_node: PlayerHealth = $player_health

func _ready():
	# Connect input signals
	 # Connect input
	input_node.move_input.connect(Callable(self, "_on_move_input"))
	input_node.action_input.connect(Callable(self, "_on_action_input"))
	
	# Connect health
	health_node.health_changed.connect(Callable(self, "_on_health_changed"))
	health_node.player_died.connect(Callable(self, "_on_player_died"))
	
	
	
func _physics_process(delta):
	move_player(delta)

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
	print("Player shoots")

# ------------------------
# Health callbacks
# ------------------------
func _on_health_changed(new_health):
	print("Player health:", new_health)
	# You could update HUD here or via signals

func _on_player_died():
	print("Player died")
	queue_free() # or trigger level restart
