extends CanvasLayer
# In-game HUD

func _ready():
	var pause_menu = preload("res://src/ui/menus/pause_menu.tscn").instantiate()
	add_child(pause_menu)
