extends Control

@onready var upgrade_option_1 := $VBoxContainer/HBoxContainer/Panel1/TextureRect1
@onready var upgrade_option_2 := $VBoxContainer/HBoxContainer/Panel2/TextureRect2
@onready var confirm_button := $VBoxContainer/Button

# Stores which upgrade the player selected
var selected_upgrade: int = -1
var _shown_upgrades: Array[UpgradeDef] = []

# Reference to GameManager
@onready var game_manager := get_node("/root/Game/GameManager") # adjust path if needed

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Make TextureRects clickable
	upgrade_option_1.mouse_filter = Control.MOUSE_FILTER_PASS
	upgrade_option_2.mouse_filter = Control.MOUSE_FILTER_PASS

	# Connect signals
	upgrade_option_1.gui_input.connect(Callable(self, "_on_upgrade_clicked1"))
	upgrade_option_2.gui_input.connect(Callable(self, "_on_upgrade_clicked2"))
	confirm_button.pressed.connect(Callable(self, "_on_confirm_pressed"))

	# Optional: highlight default selection
	_update_highlight()

func show_menu(upgrades: Array[UpgradeDef]):
	_shown_upgrades = upgrades
	selected_upgrade = -1

	upgrade_option_1.texture = upgrades[0].icon
	upgrade_option_2.texture = upgrades[1].icon

	visible = true
	_update_highlight()

func _on_upgrade_clicked1(event: InputEvent):
	_on_upgrade_clicked(event, 1)
	
func _on_upgrade_clicked2(event: InputEvent):
	_on_upgrade_clicked(event, 2)

func _on_upgrade_clicked(event: InputEvent, option_index: int):
	if event is InputEventMouseButton and event.pressed:
		selected_upgrade = option_index
		_update_highlight()

func _update_highlight():
	# Simple visual feedback for selected option
	upgrade_option_1.modulate = Color(1, 1, 1)
	upgrade_option_2.modulate = Color(1, 1, 1)

	if selected_upgrade == 1:
		upgrade_option_1.modulate = Color(0.7, 1, 0.7) # green tint
	elif selected_upgrade == 2:
		upgrade_option_2.modulate = Color(0.7, 1, 0.7)


func _on_confirm_pressed():
	if selected_upgrade == -1:
		push_error("No upgrade selected")
		return

	var chosen_upgrade := _shown_upgrades[selected_upgrade - 1]
	game_manager.apply_upgrade(chosen_upgrade)

	visible = false
	game_manager.load_next_level()


func level_ended():
	pass
	#upgrade_menu.show_menu([upgrade_texture_1, upgrade_texture_2])
