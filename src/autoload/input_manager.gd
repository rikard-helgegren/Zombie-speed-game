extends Node
# Input abstraction layer
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if  event.is_action_pressed("pause"):
		MyGameState.toggle_pause()
	elif Input.is_action_just_pressed("exit"):
		get_tree().quit()
