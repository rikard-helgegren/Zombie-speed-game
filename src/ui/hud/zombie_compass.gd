extends Control

@export var radius: float = 28.0
@export var outline_width: float = 3.0
@export var circle_color := Color(1.0, 0.9, 0.1, 1.0)
@export var arrow_rotation_offset: float = PI * 0.5

var _player: Node2D = null
var _dir := Vector2.UP
var _has_target := false

@onready var _head: TextureRect = $ZombieHead
@onready var _arrow: TextureRect = $Arrow

func _ready() -> void:
	set_process(true)
	_update_icon_layout()
	_arrow.visible = false

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if _player == null:
			_has_target = false
			_arrow.visible = false
			queue_redraw()
			return

	var zombies_node := Global.zombies_node
	if zombies_node == null or not is_instance_valid(zombies_node):
		_has_target = false
		_arrow.visible = false
		queue_redraw()
		return

	var closest: Node2D = null
	var closest_dist := INF
	for zombie in zombies_node.get_children():
		if zombie == null or not is_instance_valid(zombie):
			continue
		if not (zombie is Node2D):
			continue
		var dist := _player.global_position.distance_to(zombie.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = zombie

	if closest == null:
		_has_target = false
		_arrow.visible = false
		queue_redraw()
		return

	_dir = (closest.global_position - _player.global_position).normalized()
	_has_target = _dir.length() > 0.0
	_arrow.visible = _has_target
	if _has_target:
		_arrow.rotation = _dir.angle() + arrow_rotation_offset
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_arc(center, radius, 0.0, TAU, 64, circle_color, outline_width, true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_icon_layout()

func _update_icon_layout() -> void:
	if _head == null or _arrow == null:
		return
	var center := size * 0.5
	_head.pivot_offset = _head.size * 0.5
	_arrow.pivot_offset = _arrow.size * 0.5
	_head.position = center - _head.size * 0.5
	_arrow.position = center - _arrow.size * 0.5
