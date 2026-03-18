extends Control

signal back_requested

@onready var music_slider: HSlider = $VBoxContainer/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer/SfxRow/SfxSlider
@onready var back_button: Button = $VBoxContainer/Back

func _ready() -> void:
	visible = false
	_sync_slider_values()

func show_menu() -> void:
	visible = true
	_sync_slider_values()
	music_slider.grab_focus()

func hide_menu() -> void:
	visible = false

func _sync_slider_values() -> void:
	if music_slider:
		music_slider.set_value_no_signal(AudioManager.get_music_volume_linear())
	if sfx_slider:
		sfx_slider.set_value_no_signal(AudioManager.get_sfx_volume_linear())

func _on_back_pressed() -> void:
	back_requested.emit()

func _on_music_slider_value_changed(value: float) -> void:
	AudioManager.set_music_volume_linear(value)

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioManager.set_sfx_volume_linear(value)
