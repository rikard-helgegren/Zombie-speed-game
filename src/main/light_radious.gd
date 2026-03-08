extends ColorRect

@export var vision_radius: float = 300.0
@export var fog_opacity: float = 0.6  # 0 = fully transparent, 1 = fully opaque
@export var edge_softness: float = 100.0  # How soft the fade edges are
var player: Node2D
var game_manager: Node
var world: Node
var zombies_node: Node2D

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
		print("[LightRadious] Level started - refreshing references")
		
		# Wait a frame to ensure all nodes are ready
		await get_tree().process_frame
		
		# Get player - search fresh each time
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			print("[LightRadious] Player found: ", player)
		else:
			print("[LightRadious] WARNING: No player found")
			player = null
		
		# Get zombies node - search fresh each time
		var world_node = get_tree().get_first_node_in_group("world")
		if world_node:
			zombies_node = world_node.get_node("Zombies")
			print("[LightRadious] Zombies node found: ", zombies_node)
		else:
			print("[LightRadious] WARNING: World node not found")
			zombies_node = null

func _on_level_cleared() -> void:
		print("[LightRadious] Level cleared - hiding fog and resetting zombies")
		visible = false
		# Reset zombie visibility before level changes
		if zombies_node:
			var reset_count = 0
			for zombie in zombies_node.get_children():
				if zombie and is_instance_valid(zombie):
					var modulation = zombie.modulate
					modulation.a = 1.0
					zombie.modulate = modulation
					reset_count += 1
			print("[LightRadious] Reset visibility for ", reset_count, " zombies")

func _process(_delta: float) -> void:
	if visible:
		# Pass all parameters to the shader
		material.set_shader_parameter("vision_radius", vision_radius)
		material.set_shader_parameter("fog_opacity", fog_opacity)
		material.set_shader_parameter("edge_softness", edge_softness)
		
		# Update zombie visibility
		if player and zombies_node:
			update_zombie_visibility()
		elif not player:
			print("[LightRadious] WARNING: Player not available in _process")
		elif not zombies_node:
			print("[LightRadious] WARNING: Zombies node not available in _process")

var _original_mods := {}  # zombie -> original modulate color

func update_zombie_visibility() -> void:
	# Check all zombies and adjust them based on distance from player
	if not zombies_node:
		return
	
	for zombie in zombies_node.get_children():
		if not zombie or not is_instance_valid(zombie):
			continue
		
		# remember original modulation
		if not _original_mods.has(zombie):
			_original_mods[zombie] = zombie.modulate
		
		var distance = player.global_position.distance_to(zombie.global_position)
		
		# visibility factor v: 0 when fully outside, 1 at vision_radius
		var v = clamp((vision_radius + edge_softness - distance) / edge_softness, 0.0, 1.0)
		# smooth it for gradient
		v = smoothstep(0.0, 1.0, v)
		
		# color shifts from black to original using v
		var orig = _original_mods[zombie]
		var new_color = Color(0,0,0).lerp(orig, v)
		# opacity equals v (fully transparent when pitch black)
		new_color.a = v
		zombie.modulate = new_color
