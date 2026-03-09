extends CharacterBody2D
class_name Player

@export var speed: float = 300.0
@export var default_weapon_scene: PackedScene
@export var grappling_hook_scene: PackedScene

var move_direction = Vector2.ZERO


@onready var game_manager := get_node("/root/Game/GameManager")


# References to child components
@onready var input_node: PlayerInput = $player_input
@onready var health_node: PlayerHealth = $player_health
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon_pivot: Node2D = $WeaponPivot
var weapon: WeaponBase
var grappling_hook: GrapplingHook

enum PlayerState { IDLE, WALK, ATTACK, DIE }
var state: PlayerState = PlayerState.IDLE
var new_state: PlayerState = PlayerState.IDLE
var is_alive := true
var hook_weapon_selected := false

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
	
	EventBus.player_health_changed.emit(health_node.current_health)
	EventBus.player_ammo_changed.emit(weapon.ammo)
	
	add_to_group("player")
	
	
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
	if is_alive:
			match action_name:
				"shoot":
					if hook_weapon_selected:
						shoot_grapple()
					else:
						shoot()
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
		var target_position := grappling_hook.get_target_position()
		var to_target := target_position - global_position

		if to_target.length() <= grappling_hook.stop_distance:
			grappling_hook.cancel()
			velocity = move_velocity
		else:
			velocity = move_velocity + to_target.normalized() * grappling_hook.pull_speed
		grappling_hook.apply_target_pull(global_position)
	else:
		velocity = move_velocity

	move_and_slide()


func shoot():
	if weapon:
		weapon.fire()

func _on_player_died():
	state = PlayerState.DIE
	die_state()
	
	
func update_weapon_aim():
	var aim_direction = (get_global_mouse_position() - global_position).normalized()
	if hook_weapon_selected:
		if grappling_hook:
			grappling_hook.set_aim_direction(aim_direction)
		return

	if weapon:
		weapon.set_aim_direction(aim_direction)

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

func get_grappling_hook() -> GrapplingHook:
	return grappling_hook

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
	var direction := get_global_mouse_position() - origin
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
