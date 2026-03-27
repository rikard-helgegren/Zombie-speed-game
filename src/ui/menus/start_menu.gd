extends MenuInteraction

@onready var level_selector := $MarginContainer/VBoxContainer/OptionButton
@onready var start_button := $MarginContainer/VBoxContainer/Button

# Reference to GameManager
@onready var game_manager := get_node("/root/Game/GameManager") # adjust path if needed


func _ready():
	AudioManager.play_music_clip("music_start_menu")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Populate level selector
	level_selector.clear()
	for i in range(game_manager.levels.size()):
		var level_scene: PackedScene = game_manager.levels[i]
		var level_name = level_scene.resource_path.get_file().get_basename()
		level_selector.add_item(level_name)


	start_button.pressed.connect(Callable(self, "_on_start_pressed"))

func _set_focus_on_start():
	start_button.grab_focus()

func _get_focusable_controls() -> Array[Control]:
	var controls: Array[Control] = []
	if level_selector:
		controls.append(level_selector)
	if start_button:
		controls.append(start_button)
	return controls

func _on_start_pressed():
	var level_index = level_selector.selected
	game_manager.load_level(level_index)
	self.visible = false  # hide menu
