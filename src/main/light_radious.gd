extends ColorRect

@export var vision_radius: float = 300.0
var game_manager: Node
var world: Node

func _ready() -> void:
	print("[LightRadious] _ready() called")
	# Hidden by default (only show during levels)
	visible = false
	# Set the ColorRect to cover the screen
	size = get_viewport_rect().size
	print("[LightRadious] Size set to: ", size)
	# Create and assign a shader material
	var shader = preload("res://shaders/fog_of_war.gdshader")
	material = ShaderMaterial.new()
	material.shader = shader
	print("[LightRadious] Shader loaded and material created")
	# Defer signal connections to next frame to ensure all nodes are ready
	await get_tree().process_frame
	_setup_signal_connections()

func _setup_signal_connections() -> void:
	# Get game manager and connect to level signals
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_signal("level_started"):
		game_manager.level_started.connect(_on_level_started)
		print("[LightRadious] Connected to game_manager.level_started")
	else:
		print("[LightRadious] ERROR: Could not find game_manager or signal not found")
	# Get world and connect to level cleared
	world = get_tree().get_first_node_in_group("world")
	if world and world.has_signal("level_cleared"):
		world.level_cleared.connect(_on_level_cleared)
		print("[LightRadious] Connected to world.level_cleared")
	else:
		print("[LightRadious] ERROR: Could not find world or signal not found")

func _on_level_started() -> void:
	print("[LightRadious] Level started - showing fog")
	visible = true

func _on_level_cleared() -> void:
	print("[LightRadious] Level cleared - hiding fog")
	visible = false

func _process(_delta: float) -> void:
	if visible:
		# Just pass the vision radius to the shader
		material.set_shader_parameter("vision_radius", vision_radius)
