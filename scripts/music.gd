extends Node3D

@onready var speakers = [ $back_left_speaker, $back_right_speaker, $front_left_speaker, $front_right_speaker ]

func _physics_process(_delta):
	if Input.is_action_just_pressed("play_pause_music"):
		for speaker in speakers:
			speaker.playing = not speaker.playing
			speaker.stream_paused = not speaker.stream_paused
	if Input.is_action_just_pressed("decrease_music_volume"):
		for speaker in speakers:
			speaker.unit_size = speaker.unit_size - 0.2
	if Input.is_action_just_pressed("increase_music_volume"):
		for speaker in speakers:
			speaker.unit_size = speaker.unit_size + 0.2
