extends Camera2D
class_name GameCamera

var _shake_intensity: float = 0.0 # Placeholder
var _shake_decay: float = 0.0 # Placeholder
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func _process(delta: float) -> void:
	if _shake_intensity > 0:
		_shake_intensity = maxf(_shake_intensity - _shake_decay * delta, 0.0)
		var x_val := _rng.randf_range(-_shake_intensity, _shake_intensity)
		var y_val := _rng.randf_range(-_shake_intensity, _shake_intensity)
		offset = Vector2(x_val, y_val)

func shake(duration: float, intensity: float) -> void:
	_shake_intensity = intensity
	if duration > 0:
		_shake_decay = intensity / duration
	else:
		_shake_decay = intensity # Instant decay backup
