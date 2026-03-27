extends MenuInteraction

@onready var start_button := $MarginContainer/VBoxContainer/Button
@onready var level_selector := $MarginContainer/VBoxContainer/OptionButton

# Reference to GameManager
@onready var game_manager := get_node("/root/Game/GameManager") # adjust path if needed

# Right-stick navigation tuning.
const AIM_STICK_DEADZONE := 0.5
var _aim_stick_neutral := true

#TODO: make button shaded when having focus

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

func _process(delta: float) -> void:
	super._process(delta)
	if not visible:
		return
	_handle_option_button_aim_stick()

func _get_focusable_controls() -> Array[Control]:
	var controls: Array[Control] = []
	if level_selector:
		controls.append(level_selector)
	if start_button:
		controls.append(start_button)
	return controls
	
func _handle_option_button_aim_stick() -> void:
	if not level_selector:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused != level_selector:
		_aim_stick_neutral = true
		return
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", AIM_STICK_DEADZONE)
	if stick.length() <= 0.0:
		_aim_stick_neutral = true
		return
	if not _aim_stick_neutral:
		return
	_aim_stick_neutral = false
	if absf(stick.y) < absf(stick.x):
		return
	var item_count : int = level_selector.get_item_count()
	if item_count <= 0:
		return
	var next_index : int = level_selector.selected
	if stick.y > 0.0:
		next_index += 1
	elif stick.y < 0.0:
		next_index -= 1
	next_index = clamp(next_index, 0, item_count - 1)
	if next_index != level_selector.selected:
		level_selector.select(next_index)

func _on_start_pressed():
	var level_index = level_selector.selected
	game_manager.load_level(level_index)
	self.visible = false  # hide menu
