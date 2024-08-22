extends Node3D

@onready var sky = $WorldEnvironment

func _ready():
	sky.environment = load("res://scenes/world/day.tres")

func _input(event):
	if Input.is_action_just_pressed("full_screen"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	#else:
		#DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
