extends Control


@onready var first_button: Button = $PanelContainer/VBoxContainer/Resume

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
func show_menu():
	first_button.grab_focus()

func _on_resume_pressed():
	MyGameState.set_paused(false)
	get_tree().paused = false
	visible = false


func _on_restart_pressed():
	MyGameState.set_paused(false)
	get_tree().reload_current_scene()


func _on_quit_pressed():
	get_tree().quit()
