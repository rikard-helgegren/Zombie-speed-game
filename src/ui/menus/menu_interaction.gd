class_name MenuInteraction
extends Control

@export var stick_deadzone := 0.5
@export var debug_input := false
var _stick_neutral := true
var _last_focus_time_ms := 0

func _process(delta: float) -> void:
	if not visible:
		return
	if not _should_handle_input():
		return
	_handle_stick_navigation(delta)
	_handle_select()

func _should_handle_input() -> bool:
	return true

func _handle_stick_navigation(delta: float) -> void:
	var stick := Input.get_vector("left", "right", "up", "down", stick_deadzone)
	if stick.length() <= 0.0:
		if debug_input and not _stick_neutral:
			print("[menu_input] stick returned to neutral")
		_stick_neutral = true
		return

	if _stick_neutral:
		_stick_neutral = false
			if debug_input:
				var now_ms: int = Time.get_ticks_msec()
				var focus: Control = get_viewport().gui_get_focus_owner()
				var focus_name: String = "none"
				if focus:
					focus_name = focus.name
			print("[menu_input] stick activated len=", stick.length(),
				" x=", "%.2f" % stick.x, " y=", "%.2f" % stick.y,
				" focus=", focus_name, " dt_ms=", now_ms - _last_focus_time_ms)
		if absf(stick.y) >= absf(stick.x):
			if stick.y > 0.0:
				_focus_next()
			elif stick.y < 0.0:
				_focus_prev()

func _handle_select() -> void:
	if not Input.is_action_just_pressed("select"):
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused is Button:
		(focused as Button).emit_signal("pressed")

func _focus_next() -> void:
	_focus_from_list(1)

func _focus_prev() -> void:
	_focus_from_list(-1)

func _focus_from_list(dir: int) -> void:
	var controls := _get_focusable_controls()
	if controls.is_empty():
		return
	var current := get_viewport().gui_get_focus_owner()
	var index := controls.find(current)
	if index == -1:
		controls[0].grab_focus()
		return
	var next_index := (index + dir + controls.size()) % controls.size()
	controls[next_index].grab_focus()
	if debug_input:
		_last_focus_time_ms = Time.get_ticks_msec()
		print("[menu_input] focus moved to=", controls[next_index].name, " dir=", dir)

func _get_focusable_controls() -> Array[Control]:
	return []
