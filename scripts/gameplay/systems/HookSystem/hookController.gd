extends Node

@export var player:CharacterBody3D

@onready var hook_aiming = $HookAiming
@onready var hook_automatic = $HookAutomatic

enum HookState { AIMING, AUTOMATIC }
var current_state: HookState = HookState.AIMING

var hooks_fired: bool = false

func _input(event: InputEvent) -> void:
	match current_state:
		HookState.AIMING:
			hook_aiming.handle_input(event)
		HookState.AUTOMATIC:
			hook_automatic.handle_input(event)
			
func _process(delta: float) -> void:
	print(hook_aiming.HookLeftPoint)
	
	if Input.is_action_pressed("player_aim"):
		current_state = HookState.AIMING
	else:
		current_state = HookState.AUTOMATIC
	
	match current_state:
		HookState.AIMING:
			hook_aiming.update(delta)
		HookState.AUTOMATIC:
			hook_automatic.update(delta)
			
	if hooks_fired:
		update_hooks()

# ------------------------- Hook Random Functions -------------------------
func draw_hook(line: CSGCylinder3D, rope: Node3D, hook_position: Vector3, launcher_position: Vector3) -> void:
	var length = (hook_position - launcher_position).length()
	rope.global_transform.origin = launcher_position
	rope.look_at(hook_position, Vector3.UP)
	line.height = length
	line.position.z = length / -2

func RaycastController(point: Vector3, target: Node3D, raycast: RayCast3D) -> Vector3:
	raycast.force_raycast_update()
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider != player:
			point = raycast.get_collision_point()
			target.global_transform.origin = point
	return point

func update_hooks() -> void:
	if hook_aiming.hook_left and hook_aiming.hook_right:
		draw_hook(hook_aiming.line_left, hook_aiming.rope_left, hook_aiming.hook_left.global_transform.origin, hook_aiming.left_launcher.global_transform.origin)
		draw_hook(hook_aiming.line_right, hook_aiming.rope_right, hook_aiming.hook_right.global_transform.origin, hook_aiming.right_launcher.global_transform.origin)
