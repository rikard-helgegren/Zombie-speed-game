extends ColorRect

@export var vision_radius: float = 300.0
@export var fog_opacity: float = 0.6  # 0 = fully transparent, 1 = fully opaque
@export var edge_softness: float = 100.0  # How soft the fade edges are
var game_manager: Node
var world: Node

func _ready() -> void:
		# Hidden by default (only show during levels)
	visible = false
	# Set the ColorRect to cover the screen
	size = get_viewport_rect().size
		# Create and assign a shader material
	var shader = preload("res://shaders/fog_of_war.gdshader")
	material = ShaderMaterial.new()
	material.shader = shader
		# Defer signal connections to next frame to ensure all nodes are ready
	await get_tree().process_frame
	_setup_signal_connections()

func _setup_signal_connections() -> void:
	# Get game manager and connect to level signals
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_signal("level_started"):
		game_manager.level_started.connect(_on_level_started)
			
	# Get world and connect to level cleared
	world = get_tree().get_first_node_in_group("world")
	if world and world.has_signal("level_cleared"):
		world.level_cleared.connect(_on_level_cleared)
			
		
func _on_level_started() -> void:
		visible = true

func _on_level_cleared() -> void:
		visible = false

func _process(_delta: float) -> void:
	if visible:
		# Pass all parameters to the shader
		material.set_shader_parameter("vision_radius", vision_radius)
		material.set_shader_parameter("fog_opacity", fog_opacity)
		material.set_shader_parameter("edge_softness", edge_softness)
