extends Node2D

var direction: Vector2
var speed: float
var target: Vector2

@onready var trail: Line2D = $Trail

var max_trail_length := 100.0

func init(dir: Vector2, spd: float, tgt: Vector2):
	direction = dir
	speed = spd
	target = tgt
	rotation = direction.angle()

	# Initialize trail
	trail.clear_points()
	trail.add_point(Vector2.ZERO)
	trail.add_point(Vector2.ZERO)

func _process(delta):
	var move = direction * speed * delta
	var next_pos = global_position + move

	# ✅ Check if we would pass the target this frame
	if global_position.distance_to(target) <= move.length():
		global_position = target
		on_hit()
		return

	global_position = next_pos
	
func on_hit():
	# Optional: spawn particles here later
	queue_free()
