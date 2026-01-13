extends Control

@onready var start_button := $VBoxContainer/Button
@onready var level_selector := $VBoxContainer/OptionButton

# Reference to GameManager
@onready var game_manager := get_node("/root/Game/GameManager") # adjust path if needed


func _ready():
	# Populate level selector
	level_selector.clear()
	for i in range(game_manager.levels.size()):
		var level_scene: PackedScene = game_manager.levels[i]
		var level_name = level_scene.resource_path.get_file().get_basename()
		level_selector.add_item(level_name)

	# Connect Start button properly (Godot 4)
	start_button.pressed.connect(Callable(self, "_on_start_pressed"))



	
func _on_start_pressed():
	var level_index = level_selector.selected
	game_manager.load_level(level_index)
	self.visible = false  # hide menu
