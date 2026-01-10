extends Node
class_name GameState

@export var pause_menu_path: NodePath
@onready var pause_menu := get_node(pause_menu_path)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

var is_paused: bool = false

func set_paused(value: bool) -> void:
	if is_paused == value:
		return

	is_paused = value
	EventBus.pause_changed.emit(is_paused)

func toggle_pause() -> void:
	set_paused(!is_paused)
