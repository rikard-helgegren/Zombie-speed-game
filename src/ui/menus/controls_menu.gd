extends Control

signal back_requested

@onready var back_button: Button = $VBoxContainer/Back
@onready var grid_computer: GridContainer = $VBoxContainer/GridContainerComputer
@onready var grid_xbox: GridContainer = $VBoxContainer/GridContainerXbox

func _ready() -> void:
	visible = false

func show_menu(mode: String = "computer") -> void:
	_set_mode(mode)
	visible = true
	if back_button:
		back_button.grab_focus()

func hide_menu() -> void:
	visible = false

func _on_back_pressed() -> void:
	back_requested.emit()

func _set_mode(mode: String) -> void:
	var show_computer := mode != "xbox"
	var show_xbox := mode != "computer"
	if grid_computer:
		grid_computer.visible = show_computer
	if grid_xbox:
		grid_xbox.visible = show_xbox
