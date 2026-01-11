extends HBoxContainer

@export var max_hearts := 5
@export var heart_full: Texture2D
@export var heart_empty: Texture2D


var current_health := max_hearts

func _ready():
	
	_redraw()

func set_health(value: int):
	current_health = clamp(value, 0, max_hearts)
	_redraw()

func _redraw():
	for child in get_children():
		child.queue_free()

	for i in max_hearts:
		var heart = TextureRect.new()
		heart.texture = heart_full if i < current_health else heart_empty
		heart.stretch_mode = TextureRect.STRETCH_KEEP
		add_child(heart)
		
