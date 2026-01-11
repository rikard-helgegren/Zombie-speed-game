extends CanvasLayer

#@onready var hearts = $MarginContainer/HealthHearts
#@onready var ammo = $MarginContainer3/AmmoCounter

static var heart_img = load("res://src/assets/art/HUD/hearts_full.png")
static var ammo_img = load("res://src/assets/art/HUD/bullet1.png")

@export var heart_scene: PackedScene

var heart_instance:  TextureRect = null


func _ready():
	print("HUD READY")
	EventBus.player_health_changed.connect(set_health)
	EventBus.player_ammo_changed.connect(set_ammo)


func set_health(amount):	
	for child in $MarginContainer/HealthHearts.get_children():
		child.queue_free()
		
	for i in amount:
		var texture_rect = heart_scene.instantiate()
		#texture_rect.EXPAND_FIT_HEIGHT
		#texture_rect.texture = heart_img
		#texture_rect.stretch_mode = TextureRect.STRETCH_KEEP
		$MarginContainer/HealthHearts.add_child(texture_rect)
		
		
		

func set_ammo(amount):	
	#for child in $MarginContainer3/AmmoCounter.get_children():
	#	child.queue_free()
		
	for i in amount:
		var texture_rect = TextureRect.new()
		texture_rect.texture = ammo_img
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP
		#$MarginContainer3/AmmoCounter.add_child(texture_rect)
		
