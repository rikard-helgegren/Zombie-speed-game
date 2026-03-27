extends MenuInteraction

@onready var upgrade_option_1 := $VBoxContainer/HBoxContainer/Panel1/TextureRect1
@onready var upgrade_option_2 := $VBoxContainer/HBoxContainer/Panel2/TextureRect2
@onready var panel_1 := $VBoxContainer/HBoxContainer/Panel1
@onready var panel_2 := $VBoxContainer/HBoxContainer/Panel2
@onready var info_text := $VBoxContainer/infoText

# Stores which upgrade the player selected
var selected_upgrade: int = -1
var hovered_upgrade: int = -1
var _shown_upgrades: Array[UpgradeDef] = []
var _shine_timer: float = 0.0
# Reference to GameManager
@onready var game_manager := get_node("/root/Game/GameManager") # adjust path if needed

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Let Panels handle hover/click for the full card area.
	upgrade_option_1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrade_option_2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_1.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_2.mouse_filter = Control.MOUSE_FILTER_STOP

	# Connect signals
	panel_1.gui_input.connect(Callable(self, "_on_upgrade_clicked1"))
	panel_2.gui_input.connect(Callable(self, "_on_upgrade_clicked2"))
	panel_1.mouse_entered.connect(Callable(self, "_on_upgrade_hovered1"))
	panel_1.mouse_exited.connect(Callable(self, "_on_upgrade_unhovered1"))
	panel_2.mouse_entered.connect(Callable(self, "_on_upgrade_hovered2"))
	panel_2.mouse_exited.connect(Callable(self, "_on_upgrade_unhovered2"))

	# Optional: highlight default selection
	_update_highlight()

func _process(delta: float):
	super._process(delta)
	if not visible:
		return
	if hovered_upgrade != -1:
		_shine_timer += delta * 5.0
		_update_highlight()
	else:
		_shine_timer = 0.0

func show_menu(upgrades: Array[UpgradeDef]):
	_shown_upgrades = upgrades
	selected_upgrade = -1
	hovered_upgrade = -1

	AudioManager.play_music_clip("music_upgrade_menu")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	upgrade_option_1.texture = upgrades[0].icon
	upgrade_option_2.texture = upgrades[1].icon
	info_text.text = "Select an upgrade"

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
		_apply_upgrade()

func _on_upgrade_hovered1():
	hovered_upgrade = 1
	_update_highlight()
	if _shown_upgrades.size() > 0:
		info_text.text = _shown_upgrades[0].description

func _on_upgrade_unhovered1():
	hovered_upgrade = -1
	_update_highlight()
	info_text.text = "Select an upgrade"

func _on_upgrade_hovered2():
	hovered_upgrade = 2
	_update_highlight()
	if _shown_upgrades.size() > 1:
		info_text.text = _shown_upgrades[1].description

func _on_upgrade_unhovered2():
	hovered_upgrade = -1
	_update_highlight()
	info_text.text = "Select an upgrade"

func _handle_stick_navigation(delta: float) -> void:
	var stick := Input.get_vector("left", "right", "up", "down", stick_deadzone)
	if stick.length() <= 0.0:
		_stick_neutral = true
		return

	if _stick_neutral:
		_stick_neutral = false
		if absf(stick.x) >= absf(stick.y):
			if stick.x > 0.0:
				_set_hovered_upgrade(2)
			elif stick.x < 0.0:
				_set_hovered_upgrade(1)

func _set_hovered_upgrade(index: int) -> void:
	if index == hovered_upgrade:
		return
	if index == 1:
		_on_upgrade_hovered1()
	elif index == 2:
		_on_upgrade_hovered2()

func _handle_select() -> void:
	if not Input.is_action_just_pressed("select"):
		return
	var index := hovered_upgrade
	if index == -1:
		index = 1
	selected_upgrade = index
	_update_highlight()
	_apply_upgrade()

func _update_highlight():
	# Keep icon colors neutral; shine is done on the card background.
	upgrade_option_1.self_modulate = Color(1, 1, 1)
	upgrade_option_2.self_modulate = Color(1, 1, 1)
	_set_panel_visual(panel_1, hovered_upgrade == 1, selected_upgrade == 1)
	_set_panel_visual(panel_2, hovered_upgrade == 2, selected_upgrade == 2)

func _set_panel_visual(panel: Panel, is_hovered: bool, is_selected: bool):
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	if is_selected:
		style.bg_color = Color(0.14, 0.29, 0.14, 0.95)
		style.border_color = Color(0.45, 1.0, 0.45)
		style.border_width_left = 4
		style.border_width_top = 4
		style.border_width_right = 4
		style.border_width_bottom = 4
	elif is_hovered:
		var pulse := (sin(_shine_timer) + 1.0) * 0.5
		style.bg_color = Color(0.18 + pulse * 0.18, 0.15 + pulse * 0.12, 0.07 + pulse * 0.03, 0.95)
		style.border_color = Color(1.0, 0.88 + pulse * 0.12, 0.35, 1.0)
		var border_size := 2 + int(round(pulse * 2.0))
		style.border_width_left = border_size
		style.border_width_top = border_size
		style.border_width_right = border_size
		style.border_width_bottom = border_size
	else:
		style.bg_color = Color(0.10, 0.10, 0.12, 0.90)
		style.border_color = Color(0.35, 0.35, 0.42, 0.90)

	panel.add_theme_stylebox_override("panel", style)


func _apply_upgrade():
	if selected_upgrade == -1:
		push_error("No upgrade selected")
		return

	var chosen_upgrade := _shown_upgrades[selected_upgrade - 1]
	game_manager.apply_upgrade(chosen_upgrade)

	visible = false
	game_manager.load_next_level()
