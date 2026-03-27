extends MenuInteraction

@onready var first_button: Button = $PanelContainer/VBoxContainer/Resume
@onready var main_container: VBoxContainer = $PanelContainer/VBoxContainer
@onready var pause_panel: PanelContainer = $PanelContainer
@onready var settings_menu: Control = $SettingsMenu
@onready var controls_menu: Control = $ControlsMenu
@onready var backdrop: ColorRect = $ColorRect
@onready var game_manager := get_node("/root/Game/GameManager")
var _controls_open_mode := "computer"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	settings_menu.visible = false
	controls_menu.visible = false
	settings_menu.back_requested.connect(_on_settings_back_requested)
	controls_menu.back_requested.connect(_on_controls_back_requested)

func _should_handle_input() -> bool:
	return not settings_menu.visible and not controls_menu.visible

func _get_focusable_controls() -> Array[Control]:
	if not main_container:
		return []
	var controls: Array[Control] = []
	for child in main_container.get_children():
		if child is Control and child.focus_mode != Control.FOCUS_NONE and child.visible:
			controls.append(child)
	return controls
	
func show_menu():
	move_to_front()
	visible = true
	if backdrop:
		backdrop.visible = true
	if pause_panel:
		pause_panel.visible = true
	main_container.visible = true
	settings_menu.visible = false
	controls_menu.visible = false
	first_button.grab_focus()

func _on_resume_pressed():
	MyGameState.set_paused(false)
	get_tree().paused = false
	visible = false
	settings_menu.visible = false
	controls_menu.visible = false
	main_container.visible = true
	game_manager._update_mouse_mode()

func _on_restart_pressed():
	MyGameState.set_paused(false)
	get_tree().paused = false	
	game_manager.restart_level()

func _on_quit_pressed():
	get_tree().quit()

func _on_settings_pressed() -> void:
	main_container.visible = false
	if pause_panel:
		pause_panel.visible = false
	settings_menu.show_menu()
	settings_menu.move_to_front()

func _on_settings_back_requested() -> void:
	settings_menu.hide_menu()
	if pause_panel:
		pause_panel.visible = true
	main_container.visible = true
	first_button.grab_focus()

func _on_controls_pressed() -> void:
	main_container.visible = false
	if pause_panel:
		pause_panel.visible = false
	controls_menu.show_menu(_controls_open_mode)
	controls_menu.move_to_front()

func _on_controls_back_requested() -> void:
	controls_menu.hide_menu()
	if pause_panel:
		pause_panel.visible = true
	main_container.visible = true
	first_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and event.button_index == 2:
		_controls_open_mode = "xbox"
		return
	if event is InputEventMouseButton and event.pressed:
		_controls_open_mode = "computer"
		return
	if event is InputEventKey and event.pressed:
		_controls_open_mode = "computer"
