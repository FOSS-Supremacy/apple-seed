extends Node3D

# ------------------------- Export Variables -------------------------
@export var player: obj_player
@export var camera: Camera3D

@export_group("Nodes")
@export var grapple_target: Marker3D
@export var hook_left: Marker3D
@export var hook_right: Marker3D

@export_subgroup("Raycasts")
@export var GrappleRaycast: RayCast3D
@export var HookLeftRaycast: RayCast3D
@export var HookRightRaycast: RayCast3D

@export_subgroup("Left Hook")
@export var left_launcher: Marker3D
@export var rope_left: Node3D
@export var line_left: CSGCylinder3D

@export_subgroup("Right Hook")
@export var right_launcher: Marker3D
@export var rope_right: Node3D
@export var line_right: CSGCylinder3D

#< ---- ---- >
@export_group("System Settings")
@export var grapple_speed: float = 5.0

# ------------------------- Variables -------------------------
var target_position: Vector3
var HookRightPoint: Vector3
var HookLeftPoint: Vector3
var hooks_fired: bool = false

@onready var parent = $".."

# ------------------------- Main -------------------------
func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("fire") and player.PLAYER_AIM:
		fire_hooks()

func update(delta: float) -> void:
	parent.RaycastController(target_position, grapple_target, GrappleRaycast)

# ------------------------- Hook Firing Functions -------------------------
func fire_hooks() -> void:
	if GrappleRaycast.is_colliding():
		target_position = GrappleRaycast.get_collision_point()

		# Use RaycastController to set the hooks in the correct positions
		parent.RaycastController(HookLeftPoint, hook_left, HookLeftRaycast)
		parent.RaycastController(HookRightPoint, hook_right, HookRightRaycast)
		
		# Draw the strings using global_transform for the global world
		parent.draw_hook(line_left, rope_left, HookLeftPoint, left_launcher.global_transform.origin)
		parent.draw_hook(line_right, rope_right, HookRightPoint, right_launcher.global_transform.origin)
		
		parent.hooks_fired = true
