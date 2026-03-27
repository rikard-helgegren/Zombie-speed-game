extends CharacterBody2D
class_name Player

@export var speed: float = 300.0
@export var default_weapon_scene: PackedScene
@export var grappling_hook_scene: PackedScene
@export var knife_scene: PackedScene

var move_direction = Vector2.ZERO
var aim_direction := Vector2.RIGHT
var _aim_using_stick := false

@export var aim_stick_deadzone: float = 0.25
@export var aim_stick_distance: float = 180.0
@export var aim_assist_max_angle_deg: float = 10.0

var _mouse_moved_recent := false


@onready var game_manager := get_node("/root/Game/GameManager")


# References to child components
@onready var input_node: PlayerInput = $player_input
@onready var health_node: PlayerHealth = $player_health
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon_pivot: Node2D = $WeaponPivot
var weapon: WeaponBase
var grappling_hook: GrapplingHook
var knife: Knife

enum PlayerState { IDLE, WALK, ATTACK, DIE }
var state: PlayerState = PlayerState.IDLE
var new_state: PlayerState = PlayerState.IDLE
var is_alive := true
var hook_weapon_selected := false
var _action_blocked := false

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
	spawn_grappling_hook()
	spawn_knife()
	
	EventBus.player_health_changed.emit(health_node.current_health)
	EventBus.player_ammo_changed.emit(weapon.ammo)
	
	add_to_group("player")
	
	if game_manager and game_manager.has_signal("level_started"):
		game_manager.level_started.connect(_on_level_started)
	
	_start_action_cooldown()
	
	
func _physics_process(delta):
	Global.player_position = global_position
	move_player(delta)
	update_weapon_aim()
	_update_grapple_visuals()
	
	match state:
		PlayerState.IDLE:
			idle_state()
		PlayerState.WALK:
			walk_state()
		PlayerState.DIE:
			die_state()


func _on_move_input(direction: Vector2):
	move_direction = direction

func _on_action_input(action_name: String):
	if _action_blocked:
		return
	if is_alive:
			match action_name:
				"shoot":
					if hook_weapon_selected:
						shoot_grapple()
					else:
						shoot()
				"melee":
					if knife:
						knife.fire()
				"reload":
					if not hook_weapon_selected:
						weapon.reload()
				"grapple_hold_start":
					_set_hook_selected(true)
				"grapple_hold_end":
					_set_hook_selected(false)
				_: 
					push_error("action_name not found: " + str(action_name))
		

func move_player(_delta):
	var move_velocity: Vector2 = move_direction * (speed + 100 * Global.player_move_speed_modifier)

	if grappling_hook and grappling_hook.active:
		if grappling_hook.should_pull_player():
			var target_position := grappling_hook.get_target_position()
			var to_target := target_position - global_position

			if to_target.length() <= grappling_hook.stop_distance:
				grappling_hook.cancel()
				velocity = move_velocity
			elif grappling_hook.is_pull_ready():
				velocity = move_velocity + to_target.normalized() * grappling_hook.pull_speed
			else:
				velocity = move_velocity
			grappling_hook.apply_target_pull(global_position)
		else:
			velocity = move_velocity
	else:
		velocity = move_velocity

	move_and_slide()


func _on_level_started() -> void:
	_start_action_cooldown()


# Avoid shooting gun when starting level.
func _start_action_cooldown() -> void:
	_action_blocked = true
	await get_tree().create_timer(0.5, true).timeout
	_action_blocked = false


func shoot():
	if weapon:
		weapon.fire()

func _on_player_died():
	state = PlayerState.DIE
	die_state()
	
	
func update_weapon_aim():
	aim_direction = _get_current_aim_direction()
	if hook_weapon_selected:
		if grappling_hook:
			grappling_hook.set_aim_direction(aim_direction)
		return

	if weapon:
		weapon.set_aim_direction(aim_direction)
	if knife:
		knife.set_aim_direction(aim_direction)

func spawn_default_weapon():
	if not default_weapon_scene:
		push_warning("No default weapon assigned")
		return

	var weapon_instance = default_weapon_scene.instantiate() as WeaponBase
	weapon_pivot.add_child(weapon_instance)
	weapon = weapon_instance

func spawn_grappling_hook():
	if grappling_hook_scene == null:
		grappling_hook_scene = preload("res://src/features/weapons/grapling_hook/grapling_hook.tscn")

	var hook_instance = grappling_hook_scene.instantiate() as GrapplingHook
	weapon_pivot.add_child(hook_instance)
	grappling_hook = hook_instance

func spawn_knife():
	if knife_scene == null:
		knife_scene = preload("res://src/features/weapons/melee/knife.tscn")

	var knife_instance = knife_scene.instantiate() as Knife
	weapon_pivot.add_child(knife_instance)
	knife = knife_instance
	knife.swing_started.connect(_on_knife_swing_started)
	knife.swing_finished.connect(_on_knife_swing_finished)

func _on_knife_swing_started() -> void:
	if weapon:
		weapon.hide()

func _on_knife_swing_finished() -> void:
	if hook_weapon_selected:
		return
	if weapon:
		weapon.show()

func get_grappling_hook() -> GrapplingHook:
	return grappling_hook

func get_aim_position() -> Vector2:
	if _aim_using_stick:
		return global_position + aim_direction * aim_stick_distance
	return get_global_mouse_position()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_moved_recent = true

func _get_current_aim_direction() -> Vector2:
	var stick_dir := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", aim_stick_deadzone)
	if stick_dir.length() > 0.0:
		_aim_using_stick = true
		return _apply_aim_assist(stick_dir.normalized())

	if _mouse_moved_recent:
		_mouse_moved_recent = false
		var mouse_pos := get_global_mouse_position()
		var mouse_dir := mouse_pos - global_position
		if mouse_dir.length() <= 0.001:
			return aim_direction
		_aim_using_stick = false
		return mouse_dir.normalized()

	# No stick input and mouse is still: keep last aim + mode.
	return aim_direction

func _apply_aim_assist(stick_dir: Vector2) -> Vector2:
	if aim_assist_max_angle_deg <= 0.0:
		return stick_dir

	var zombies_node := _get_zombies_node()
	if zombies_node == null:
		return stick_dir

	var max_angle_rad := deg_to_rad(aim_assist_max_angle_deg)
	var best_dir := Vector2.ZERO
	var best_angle := max_angle_rad
	var best_dist := INF

	for zombie in zombies_node.get_children():
		if not (zombie is Node2D) or not is_instance_valid(zombie):
			continue
		if not _is_zombie_visible_to_player(zombie):
			continue
		var to_zombie : Vector2= zombie.global_position - global_position
		if to_zombie.length() <= 0.001:
			continue
		var dir : Vector2 = to_zombie.normalized()
		var angle_diff : float = abs(stick_dir.angle_to(dir))
		if angle_diff <= max_angle_rad:
			var dist : float = to_zombie.length()
			if angle_diff < best_angle or (is_equal_approx(angle_diff, best_angle) and dist < best_dist):
				best_angle = angle_diff
				best_dist = dist
				best_dir = dir

	return stick_dir if best_dir == Vector2.ZERO else best_dir

func _is_zombie_visible_to_player(zombie: Node2D) -> bool:
	if zombie is CanvasItem:
		if not zombie.visible:
			return false
		# Fog-of-war fades zombies by modulating alpha; treat near-zero as not visible.
		if zombie.modulate.a <= 0.05:
			return false
	return true

func _get_zombies_node() -> Node2D:
	if Global.zombies_node and is_instance_valid(Global.zombies_node):
		return Global.zombies_node

	if game_manager:
		var gm_zombies = game_manager.get("zombies_node")
		if gm_zombies and is_instance_valid(gm_zombies):
			return gm_zombies

	var world := get_tree().get_first_node_in_group("world")
	if world:
		var world_zombies := world.get_node_or_null("Zombies")
		if world_zombies and world_zombies is Node2D:
			return world_zombies

	var scene := get_tree().current_scene
	if scene:
		var scene_zombies := scene.get_node_or_null("Zombies")
		if scene_zombies and scene_zombies is Node2D:
			return scene_zombies
		var found := scene.find_child("Zombies", true, false)
		if found and found is Node2D:
			return found

	return null

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
		if grappling_hook:
			grappling_hook.cancel()
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
	game_manager.toggle_pause()

func upgrade_move_speed():
	Global.player_move_speed_modifier += 1

func upgrade_reload_speed():
	Global.player_reload_speed_modifier += 1
	
func upgrade_damage():
	Global.player_damage_modifier += 1
	
func  upgarde_ammo():
	Global.player_ammo_modifier += 1
	
func upgarde_fire_rate():
		Global.player_fire_rate_modifier += 1


func shoot_grapple() -> void:
	if not is_alive:
		return
	if grappling_hook == null:
		return

	var origin := grappling_hook.get_origin()
	var direction := get_aim_position() - origin
	grappling_hook.fire(direction, [self])

func _update_grapple_visuals() -> void:
	if not grappling_hook or not grappling_hook.active:
		return

	var origin := grappling_hook.get_origin()
	grappling_hook.update_visuals(origin)


func _set_hook_selected(selected: bool) -> void:
	if hook_weapon_selected == selected:
		return

	hook_weapon_selected = selected

	if hook_weapon_selected:
		if weapon:
			weapon.hide()
		if grappling_hook:
			grappling_hook.set_selected(true)
	else:
		if grappling_hook:
			grappling_hook.set_selected(false)
		if weapon:
			weapon.show()
