extends CanvasLayer

@export var heart_scene: PackedScene
@export var ammo_scene: PackedScene


func _ready():
	print("HUD READY")
	EventBus.player_health_changed.connect(set_health)
	EventBus.player_ammo_changed.connect(set_ammo)


func set_health(amount):	
	for child in $MarginContainer/HealthHearts.get_children():
		child.queue_free()
		
	for i in amount:
		var texture_rect = heart_scene.instantiate()
		$MarginContainer/HealthHearts.add_child(texture_rect)
		
		
		

func set_ammo(amount):	
	print("setting ammo:" + str(amount))
	for child in $MarginContainer3/AmmoCounter.get_children():
		child.queue_free()
		
	for i in amount:
		var texture_rect = ammo_scene.instantiate()
		$MarginContainer3/AmmoCounter.add_child(texture_rect)
		
