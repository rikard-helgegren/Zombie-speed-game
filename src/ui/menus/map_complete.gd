extends Control

const PULSE_HZ := 1.0
const PULSE_AMOUNT := 0.08

@onready var label: Label = $Label
var _time := 0.0
var _base_scale := Vector2.ONE

func _ready() -> void:
	if label:
		_base_scale = label.scale
		_update_pivot()
		label.resized.connect(_update_pivot)

func _process(delta: float) -> void:
	_time += delta
	if label:
		var pulse := 1.0 + sin(_time * TAU * PULSE_HZ) * PULSE_AMOUNT
		label.scale = _base_scale * pulse

func _update_pivot() -> void:
	if label:
		label.pivot_offset = label.size * 0.5
