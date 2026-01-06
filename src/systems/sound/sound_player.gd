extends Node2D

@onready var player := $AudioStreamPlayer2D

func play(stream: AudioStream, pos: Vector2, delay: float):
	player.stream = stream
	global_position = pos
	
	await get_tree().create_timer(delay).timeout
	
	player.play()

func _on_audio_stream_player_2d_finished():
	queue_free()
