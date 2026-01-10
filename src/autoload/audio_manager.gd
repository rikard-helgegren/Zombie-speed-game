extends Node
# Centralized audio control

func _ready():
	EventBus.pause_changed.connect(_on_pause_changed)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_pause_changed(paused: bool) -> void:
	print("Pause Audio? Todo R2")
