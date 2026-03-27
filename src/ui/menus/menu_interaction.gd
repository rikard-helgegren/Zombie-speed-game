extends Control
class_name MenuInteraction

@export var stick_deadzone := 0.5
@export var debug_input := false
var _stick_neutral := true
var _last_focus_time_ms := 0

func _process(delta: float) -> void:
	if not visible:
		return
	if not _should_handle_input():
		return
	if not _is_option_popup_open():
		_handle_stick_navigation(delta)
	_handle_select()
	_handle_cancel()

func _should_handle_input() -> bool:
	return true

func _handle_stick_navigation(delta: float) -> void:
	if _is_option_popup_open():
		return
	var stick := Input.get_vector("menu_left", "menu_right", "menu_up", "menu_down", stick_deadzone)
	if stick.length() <= 0.1:
		_stick_neutral = true
		return

	if _stick_neutral:
		_stick_neutral = false
		if absf(stick.y) >= absf(stick.x):
			if stick.y > 0.0:
				_focus_next()
			elif stick.y < 0.0:
				_focus_prev()

func _handle_select() -> void:
	if not Input.is_action_just_pressed("select"):
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused is OptionButton:
		var option_button := focused as OptionButton
		var popup := option_button.get_popup()
		if popup:
			if popup.visible:
				_activate_popup_selection(popup)
			else:
				option_button.show_popup()
		return
	if focused is Button:
		(focused as Button).emit_signal("pressed")

func _handle_cancel() -> void:
	if not Input.is_action_just_pressed("menu_cancel"):
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused is OptionButton:
		var option_button := focused as OptionButton
		var popup := option_button.get_popup()
		if popup and popup.visible:
			popup.hide()

func _is_option_popup_open() -> bool:
	var focused := get_viewport().gui_get_focus_owner()
	if focused is OptionButton:
		var option_button := focused as OptionButton
		var popup := option_button.get_popup()
		return popup != null and popup.visible
	return false

func _activate_popup_selection(popup: PopupMenu) -> void:
	var index := popup.get_focused_item()
	if index == -1:
		return
	if popup.has_method("activate_item"):
		popup.call("activate_item", index)
		return
	if popup.has_method("activate_item_by_index"):
		popup.call("activate_item_by_index", index)
		return
	if popup.has_method("activate_item_id"):
		var id := popup.get_item_id(index)
		popup.call("activate_item_id", id)
		return
	if popup.has_signal("index_pressed"):
		popup.emit_signal("index_pressed", index)
	if popup.has_signal("id_pressed"):
		var id_fallback := popup.get_item_id(index)
		popup.emit_signal("id_pressed", id_fallback)

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
