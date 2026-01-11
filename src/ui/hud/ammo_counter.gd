extends HBoxContainer

@export var bullet_texture: Texture2D
@export var max_ammo := 10

var current_ammo := max_ammo

func _ready():
	_redraw()

func set_ammo(value: int):
	current_ammo = clamp(value, 0, max_ammo)
	_redraw()

func _redraw():
	for child in get_children():
		child.queue_free()

	for i in current_ammo:
		var bullet = TextureRect.new()
		bullet.texture = bullet_texture
		bullet.stretch_mode = TextureRect.STRETCH_KEEP
		add_child(bullet)
