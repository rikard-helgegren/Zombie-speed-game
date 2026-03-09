extends Node2D
class_name Crosshair

# Radial cooldown ring styling.
const RING_RADIUS := 18.0
const RING_THICKNESS := 3.0
const RING_SEGMENTS := 64
const OUTLINE_COLOR := Color(0.75, 0.75, 0.75, 0.85)
const FILL_COLOR := Color(1, 1, 1, 0.95)

# Cached player + hook references.
var _player: Player = null
var _hook: GrapplingHook = null
# Cooldown state for the ring.
var _cooldown_active := false
var _cooldown_progress := 1.0
# Ready flash + wobble timers.
var _ready_flash := 0.0
var _wobble_time := 0.0
var _wobble_phase := 0.0


func _process(delta):
	global_position = get_global_mouse_position()
	_resolve_hook()

	if _hook:
		# Hide ring entirely when grappling hook is not selected.
		if not _hook.is_selected():
			_cooldown_active = false
			_ready_flash = 0.0
			_wobble_time = 0.0
			_cooldown_progress = 1.0
			queue_redraw()
			return
		# Track cooldown state and progress.
		var active := _hook.is_on_cooldown()
		var progress := _hook.get_cooldown_progress()
		if _cooldown_active and not active:
			_ready_flash = 0.2
			_wobble_time = 0.25
		_cooldown_active = active
		_cooldown_progress = progress

	# Update animations for any effects that are still active.
	if _ready_flash > 0.0:
		_ready_flash = maxf(_ready_flash - delta, 0.0)
	if _wobble_time > 0.0:
		_wobble_time = maxf(_wobble_time - delta, 0.0)
		_wobble_phase += delta * 20.0

	if _cooldown_active or _ready_flash > 0.0 or _wobble_time > 0.0:
		queue_redraw()


func _resolve_hook() -> void:
	# Resolve hook only once; the player is in the "player" group.
	if _hook:
		return
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node and player_node.has_method("get_grappling_hook"):
		_player = player_node as Player
		_hook = player_node.get_grappling_hook() as GrapplingHook


func _draw() -> void:
	# Only draw the ring when the hook is selected and cooling down.
	if not _hook or not _hook.is_selected():
		return
	if not _cooldown_active and _ready_flash <= 0.0 and _wobble_time <= 0.0:
		return

	var radius := RING_RADIUS
	if _wobble_time > 0.0:
		radius *= 1.0 + 0.06 * sin(_wobble_phase)

	# Ring outline (only while cooling down).
	if _cooldown_active:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, RING_SEGMENTS, OUTLINE_COLOR, RING_THICKNESS, true)

	# Filled sector shows cooldown progress (clockwise from top).
	if _cooldown_active and _cooldown_progress > 0.0:
		_draw_sector(Vector2.ZERO, radius - (RING_THICKNESS * 0.3), -PI / 2.0, -PI / 2.0 + TAU * _cooldown_progress, FILL_COLOR)

	# Small flash when the cooldown completes.
	if _ready_flash > 0.0:
		var flash_alpha := minf(_ready_flash * 5.0, 1.0)
		var flash_color := Color(1, 1, 1, flash_alpha)
		draw_arc(Vector2.ZERO, radius + 1.5, 0.0, TAU, RING_SEGMENTS, flash_color, RING_THICKNESS + 1.0, true)
		draw_circle(Vector2(0, -radius), 2.0, flash_color)


func _draw_sector(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color) -> void:
	# Draw a filled pie-slice by triangulating a fan of points.
	var points := PackedVector2Array()
	points.append(center)
	var angle_span := maxf(end_angle - start_angle, 0.0)
	var steps : int = max(3, int(RING_SEGMENTS * (angle_span / TAU)))
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var angle := lerpf(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_polygon(points, PackedColorArray([color]))
