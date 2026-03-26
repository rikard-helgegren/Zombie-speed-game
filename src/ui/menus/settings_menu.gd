extends Control

signal back_requested

@onready var music_slider: HSlider = $VBoxContainer/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer/SfxRow/SfxSlider
@onready var dev_clip_scroll: ScrollContainer = $VBoxContainer/DevClipRow/DevClipScroll
@onready var dev_clip_list: VBoxContainer = $VBoxContainer/DevClipRow/DevClipScroll/DevClipList
@onready var dev_clip_volume_slider: HSlider = $VBoxContainer/DevClipVolumeRow/DevClipVolumeSlider
@onready var back_button: Button = $VBoxContainer/Back
var _dev_clip_names: Array[String] = []
var _dev_clip_button_group: ButtonGroup
var _selected_dev_clip_index := -1

func _ready() -> void:
	visible = false
	_populate_dev_clips()
	_sync_slider_values()

func show_menu() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_populate_dev_clips()
	_sync_slider_values()
	music_slider.grab_focus()

func hide_menu() -> void:
	visible = false

func _sync_slider_values() -> void:
	if music_slider:
		music_slider.set_value_no_signal(AudioManager.get_music_volume_linear())
	if sfx_slider:
		sfx_slider.set_value_no_signal(AudioManager.get_sfx_volume_linear())
	_sync_dev_clip_slider()

func _on_back_pressed() -> void:
	back_requested.emit()

func _on_music_slider_value_changed(value: float) -> void:
	AudioManager.set_music_volume_linear(value)

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioManager.set_sfx_volume_linear(value)

func _populate_dev_clips() -> void:
	if not dev_clip_list:
		return
	for child in dev_clip_list.get_children():
		child.queue_free()
	_dev_clip_names = AudioManager.get_clip_names()
	_dev_clip_names.sort()
	if _dev_clip_names.is_empty():
		_selected_dev_clip_index = -1
		if dev_clip_scroll:
			dev_clip_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dev_clip_volume_slider.editable = false
		return
	if dev_clip_scroll:
		dev_clip_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	dev_clip_volume_slider.editable = true
	_dev_clip_button_group = ButtonGroup.new()
	for index in _dev_clip_names.size():
		var name := _dev_clip_names[index]
		var button := Button.new()
		button.text = name
		button.toggle_mode = true
		button.button_group = _dev_clip_button_group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_dev_clip_button_pressed.bind(index))
		dev_clip_list.add_child(button)
	_apply_dev_clip_font_scaling(_dev_clip_names.size())
	_select_dev_clip(0)

func _sync_dev_clip_slider() -> void:
	if _dev_clip_names.is_empty():
		return
	var index := _selected_dev_clip_index
	if index < 0 or index >= _dev_clip_names.size():
		return
	var clip_name := _dev_clip_names[index]
	dev_clip_volume_slider.set_value_no_signal(AudioManager.get_clip_volume_db_by_name(clip_name))

func _on_dev_clip_button_pressed(index: int) -> void:
	if index < 0 or index >= _dev_clip_names.size():
		return
	_selected_dev_clip_index = index
	_sync_dev_clip_slider()

func _on_dev_clip_volume_changed(value: float) -> void:
	if _dev_clip_names.is_empty():
		return
	var index := _selected_dev_clip_index
	if index < 0 or index >= _dev_clip_names.size():
		return
	AudioManager.set_clip_volume_db(_dev_clip_names[index], value)

func _apply_dev_clip_font_scaling(clip_count: int) -> void:
	if not dev_clip_list:
		return
	var base_size := _get_dev_clip_base_font_size(dev_clip_list)
	var scaled_size := _get_scaled_font_size(clip_count, base_size)
	for child in dev_clip_list.get_children():
		if child is Button:
			_apply_button_font_size(child, scaled_size)

func _get_scaled_font_size(clip_count: int, base_size: int) -> int:
	var size := base_size
	if clip_count > 12:
		size = base_size - 2
	if clip_count > 18:
		size = base_size - 4
	if clip_count > 26:
		size = base_size - 6
	return max(size, 10)

func _get_dev_clip_base_font_size(control) -> int:
	if control and control.has_method("get_theme_font_size"):
		return control.get_theme_font_size("font_size")
	return 16

func _apply_button_font_size(button: Button, size: int) -> void:
	if not button:
		return
	button.add_theme_font_size_override("font_size", size)

func _select_dev_clip(index: int) -> void:
	if index < 0 or index >= _dev_clip_names.size():
		return
	_selected_dev_clip_index = index
	if dev_clip_list:
		var buttons := dev_clip_list.get_children()
		if index < buttons.size() and buttons[index] is Button:
			var button := buttons[index] as Button
			button.button_pressed = true
	_sync_dev_clip_slider()
