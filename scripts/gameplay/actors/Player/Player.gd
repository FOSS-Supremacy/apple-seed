extends CharacterBody3D
class_name obj_player

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm
@onready var camera: Camera3D = $CameraPivot/SpringArm/Camera
@onready var animator: AnimationTree = $AnimationTree
@onready var mesh: Node3D = $Mesh
@onready var player_body = $Mesh/Armature
@onready var skeleton: Skeleton3D = $Mesh/Armature/Skeleton3D

var move_direction: Vector3 = Vector3.ZERO
var snap_vector: Vector3 = Vector3.DOWN
var speed: float

@export_group("Global Variables")
@export var World: Node3D
@export var GRAVITY_ON: bool = true

@export_group("Movement variables")
@export var walk_speed: float = 2.0
@export var run_speed: float = 5.0
@export var jump_strength: float = 15.0
@export var gravity: float = 50.0

# <-- Grappling Hook System -->
var grappling: bool = false
var grapple_point: Vector3 = Vector3.ZERO
@export var grapple_speed: float = 20.0
@onready var raycast: RayCast3D = $Mesh/odm/HookRaycast
@onready var hook_camera: Camera3D = $Mesh/odm/HookCamera3D

# <-- CAMERA -->
@export_group("Camera Variables")
var PLAYER_AIM: bool = false
@export var aim_offset: Vector3
@export var spring_length_default: float = 3.0
@export var aim_speed_lerp = 3

# <-- ANIMATIONS -->
var mesh_rotation_lerp = 0.15
const ANIMATION_BLEND: float = 7.0


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Ensure the hook_camera is not active initially
	camera.current = true
	hook_camera.current = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Rotates the camera around the player based on mouse movement
		camera_pivot.rotate_y(-event.relative.x * 0.005)
		spring_arm.rotate_x(-event.relative.y * 0.005)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI / 4, PI / 4)

		# Rotate the raycast if needed
		raycast.rotate_x(-event.relative.y * 0.005)
		raycast.rotation.x = clamp(spring_arm.rotation.x, -PI / 4, PI / 4)

	# Detect left click for the grappling hook
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if raycast.is_colliding():
			# If the raycast collides with an object, start the grappling hook system
			grappling = true
			grapple_point = raycast.get_collision_point()
			# Switch to the hook camera
			camera.current = false
			hook_camera.current = true

	# Change to hook camera
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_RIGHT
		and event.pressed
	):
		hook_camera.current = !hook_camera.current


func _physics_process(delta: float) -> void:
	AnimationController(delta)
	CameraController(delta)

	if grappling:
		GrappleMovement(delta)
	else:
		MovementController(delta)


func AnimationController(delta):
	if is_on_floor():
		animator.set("parameters/ground_air_transition/transition_request", "grounded")

		if velocity.length() > 0:
			if speed == run_speed:
				animator.set(
					"parameters/iwr_blend/blend_amount",
					lerp(
						animator.get("parameters/iwr_blend/blend_amount"),
						1.0,
						delta * ANIMATION_BLEND
					)
				)
			else:
				animator.set(
					"parameters/iwr_blend/blend_amount",
					lerp(
						animator.get("parameters/iwr_blend/blend_amount"),
						0.0,
						delta * ANIMATION_BLEND
					)
				)
		else:
			animator.set(
				"parameters/iwr_blend/blend_amount",
				lerp(
					animator.get("parameters/iwr_blend/blend_amount"), -1.0, delta * ANIMATION_BLEND
				)
			)
	else:
		animator.set("parameters/ground_air_transition/transition_request", "air")


func CameraController(delta: float) -> void:
	# If the player is grappling, don't modify the camera
	if grappling:
		# Ensure camera settings are not changed while grappling
		return

	# Check if the player is aiming
	if PLAYER_AIM:
		# Adjusts the mesh (player body) rotation to follow the camera when aiming
		mesh.rotation.y = lerp_angle(
			mesh.rotation.y, camera_pivot.rotation.y + PI, mesh_rotation_lerp * 2
		)

		# Adjusts the camera length (closer to the player) when aiming
		spring_arm.spring_length = lerp(spring_arm.spring_length, 1.0, delta * aim_speed_lerp)

		# Adjusts the camera position to a closer offset when aiming
		spring_arm.position = spring_arm.position.lerp(aim_offset, delta * aim_speed_lerp)
	else:
		# When the player is not aiming, the camera returns to its default length
		spring_arm.spring_length = lerp(
			spring_arm.spring_length, spring_length_default, delta * aim_speed_lerp
		)

		# Returns the camera to its original position (behind the player)
		spring_arm.position = spring_arm.position.lerp(Vector3(0, 0, 0), delta * aim_speed_lerp)


# Standard character movement function
func MovementController(delta) -> void:
	move_direction.x = (
		Input.get_action_strength("player_right") - Input.get_action_strength("player_left")
	)
	move_direction.z = (
		Input.get_action_strength("player_backward") - Input.get_action_strength("player_forward")
	)
	move_direction = move_direction.rotated(Vector3.UP, camera_pivot.rotation.y)

	if GRAVITY_ON:
		velocity.y -= gravity * delta

	if Input.is_action_pressed("player_run") and not PLAYER_AIM:
		speed = run_speed
	else:
		speed = walk_speed

	var just_landed := is_on_floor() and snap_vector == Vector3.ZERO
	var is_jumping := is_on_floor() and Input.is_action_just_pressed("player_jump")
	if is_jumping:
		velocity.y = jump_strength
		snap_vector = Vector3.ZERO
	elif just_landed:
		snap_vector = Vector3.DOWN

	velocity.x = move_direction.x * speed
	velocity.z = move_direction.z * speed

	if move_direction != Vector3.ZERO and not PLAYER_AIM and is_on_floor():
		mesh.rotation.y = lerp_angle(
			mesh.rotation.y, atan2(velocity.x, velocity.z), mesh_rotation_lerp
		)

	apply_floor_snap()
	move_and_slide()


# Grappling hook movement function
func GrappleMovement(delta: float) -> void:
	# Pulls the character towards the grapple point
	var direction_to_grapple = (grapple_point - global_transform.origin).normalized()
	velocity = direction_to_grapple * grapple_speed

	# If the character gets close enough to the contact point, stop the grappling hook
	if global_transform.origin.distance_to(grapple_point) < 1.0:
		grappling = false
		# Switch back to the main camera
		camera.current = true
		hook_camera.current = false

	# Apply grappling hook movement
	move_and_slide()
