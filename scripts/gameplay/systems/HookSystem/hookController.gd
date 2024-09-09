extends Node

@export var player:CharacterBody3D

@onready var hook_aiming = $HookAiming
@onready var hook_automatic = $HookAutomatic
@onready var gas_propulsion: Node3D = $GasPropulsion

@onready var center_point: Marker3D = $CenterPoint

@export_group("Hook Settings")
var rope_length_left: float = 0.0
var rope_length_right: float = 0.0
var lock_rope_length: bool = false
var suspension_velocity: float = 100.0 


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
		update_hooks(delta)

# ------------------------- Hook Random Functions -------------------------
func draw_hook(line: CSGCylinder3D, rope: Node3D, hook_position: Vector3, launcher_position: Vector3, length: float) -> void:
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

func update_hooks(delta) -> void:
	if hook_aiming.hook_left and hook_aiming.hook_right:
		if player.is_on_floor():
			lock_rope_length = false

			# Update string length normally (Apparently it doesn't work.)
			rope_length_left = (hook_aiming.hook_left.global_transform.origin - hook_aiming.left_launcher.global_transform.origin).length()
			rope_length_right = (hook_aiming.hook_right.global_transform.origin - hook_aiming.right_launcher.global_transform.origin).length()
		else:
			if not lock_rope_length:
				rope_length_left = (hook_aiming.hook_left.global_transform.origin - hook_aiming.left_launcher.global_transform.origin).length()
				rope_length_right = (hook_aiming.hook_right.global_transform.origin - hook_aiming.right_launcher.global_transform.origin).length()
				lock_rope_length = true

		# Draw the hooks with the locked length
		draw_hook(hook_aiming.line_left, hook_aiming.rope_left, hook_aiming.hook_left.global_transform.origin, hook_aiming.left_launcher.global_transform.origin, rope_length_left)
		draw_hook(hook_aiming.line_right, hook_aiming.rope_right, hook_aiming.hook_right.global_transform.origin, hook_aiming.right_launcher.global_transform.origin, rope_length_right)
