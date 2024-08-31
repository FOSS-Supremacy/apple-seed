extends Node


# ------------------------- Export Variables -------------------------
@export var player: CharacterBody3D
@export var camera: Camera3D

@export_group("Nodes")
@export var grapple_target: Marker3D
@export var hook_left: Marker3D
@export var hook_right: Marker3D

@export_subgroup("Left Hook")
@export var left_launcher: Marker3D
@export var rope_left: Node3D
@export var line_left: CSGCylinder3D

@export_subgroup("Right Hook")
@export var right_launcher: Marker3D
@export var rope_right: Node3D
@export var line_right: CSGCylinder3D

@export_group("System Settings")
@export var grapple_speed: float = 5.0

# ------------------------- Variables -------------------------
var left_hook_position: Vector3
var right_hook_position: Vector3
var target_position: Vector3
var left_hook_fired: bool = false
var right_hook_fired: bool = false

# automatic swinging
var detected_objects: Array = []
var objects_right: Array = []
var objects_left: Array = []

# ------------------------- Main -------------------------
func handle_input(event: InputEvent) -> void:
	pass

func update(delta:float) -> void:
	pass

# ------------------------- Automatic Swinging Functions -------------------------
