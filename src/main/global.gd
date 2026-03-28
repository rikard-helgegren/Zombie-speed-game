extends Node

var player_position: Vector2
var player_move_speed_modifier := 0
var player_damage_modifier := 0
var player_ammo_modifier := 0
var player_reload_speed_modifier := 0
var player_fire_rate_modifier := 0
var player_hp_modifier := 0

var spawner_extra_zombies := 0
var zombies_extra_speed := 0

var zombies_node: Node2D = null

var ready_to_use_a_weapon := true
var weapon_cooldown_end_ms := 0

func can_use_weapon() -> bool:
	if ready_to_use_a_weapon:
		return true
	if Time.get_ticks_msec() >= weapon_cooldown_end_ms:
		ready_to_use_a_weapon = true
		return true
	return false

func start_weapon_cooldown(duration: float) -> void:
	var clamped_duration := maxf(duration, 0.0)
	if clamped_duration <= 0.0:
		ready_to_use_a_weapon = true
		weapon_cooldown_end_ms = 0
		return
	ready_to_use_a_weapon = false
	weapon_cooldown_end_ms = Time.get_ticks_msec() + int(ceil(clamped_duration * 1000.0))
