extends Node2D

@onready var player := $AudioStreamPlayer2D
@onready var _base_volume_db: float = player.volume_db

func play(stream: AudioStream, pos: Vector2, delay: float):
	player.stream = stream
	player.volume_db = _base_volume_db + AudioManager.get_sfx_volume_db_offset()
	global_position = pos
	
	await get_tree().create_timer(delay).timeout
	
	player.play()

func _on_audio_stream_player_2d_finished():
	queue_free()
