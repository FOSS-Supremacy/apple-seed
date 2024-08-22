extends AudioStreamPlayer3D

@onready var microphone = $microfone

func _physics_process(_delta):
	if Input.is_action_just_pressed("switch_microphone"):
		microphone.playing = not microphone.playing
		microphone.stream_paused = not microphone.stream_paused
