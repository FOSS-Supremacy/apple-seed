extends CharacterBody3D
class_name obj_player

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm
@onready var camera: Camera3D = $CameraPivot/SpringArm/Camera
@onready var animator: AnimationTree = $AnimationTree
@onready var mesh: Node3D = $Mesh
@onready var skeleton: Skeleton3D = $Mesh/Armature/Skeleton3D


var move_direction : Vector3 = Vector3.ZERO
var snap_vector : Vector3 = Vector3.DOWN

@export_group("Global Variables")
@export var World:Node3D
@export var GRAVITY_ON:bool = true

@export_group("Movement variables")
@export var walk_speed : float = 2.0
@export var walk_aim_speed:float = 1.0
@export var run_speed : float = 5.0
@export var jump_strength : float = 15.0
@export var gravity : float = 50.0

var speed:float

# <-- CAMERA -->
@export_group("Camera Variables")
var PLAYER_AIM:bool = false
@export var aim_offset:Vector3
@export var spring_length_default:float = 3.0
@export var aim_speed_lerp = 3

# <-- ANIMATIONS -->
var mesh_rotation_lerp = 0.15
const ANIMATION_BLEND : float = 7.0


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_pivot.rotate_y(-event.relative.x * 0.005)
		spring_arm.rotate_x(-event.relative.y * 0.005)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/4, PI/4)

func _physics_process(delta: float) -> void:
	AnimationController(delta)
	CameraController(delta)
	
	MovementController(delta)

func AnimationController(delta):
	if is_on_floor():
		animator.set("parameters/ground_air_transition/transition_request", "grounded")
		
		if velocity.length() > 0:
			if speed == run_speed:
				animator.set("parameters/iwr_blend/blend_amount", lerp(animator.get("parameters/iwr_blend/blend_amount"), 1.0, delta * ANIMATION_BLEND))
			else:
				animator.set("parameters/iwr_blend/blend_amount", lerp(animator.get("parameters/iwr_blend/blend_amount"), 0.0, delta * ANIMATION_BLEND))
		else:
			animator.set("parameters/iwr_blend/blend_amount", lerp(animator.get("parameters/iwr_blend/blend_amount"), -1.0, delta * ANIMATION_BLEND))
	else:
		animator.set("parameters/ground_air_transition/transition_request", "air")

func CameraController(delta):
	if PLAYER_AIM:
		mesh.rotation.y = lerp_angle(mesh.rotation.y, camera_pivot.rotation.y + PI, (mesh_rotation_lerp * 2) )
		spring_arm.spring_length = lerp(spring_arm.spring_length, 1.0, delta * aim_speed_lerp)
		spring_arm.position = spring_arm.position.lerp(aim_offset, delta * aim_speed_lerp)
	else:
		spring_arm.spring_length = lerp(spring_arm.spring_length, spring_length_default, delta * aim_speed_lerp)
		spring_arm.position = spring_arm.position.lerp(Vector3(0,0,0), delta * aim_speed_lerp)
	
func MovementController(delta) -> void:
	move_direction.x = Input.get_action_strength("player_right") - Input.get_action_strength("player_left")
	move_direction.z = Input.get_action_strength("player_backward") - Input.get_action_strength("player_forward")
	move_direction = move_direction.rotated(Vector3.UP, camera_pivot.rotation.y)
	
	if GRAVITY_ON:
		velocity.y -= gravity * delta
		
	if Input.is_action_pressed("player_run") and not PLAYER_AIM:
		speed = run_speed
	elif Input.is_action_pressed("player_aim") and is_on_floor():
		speed = walk_speed
		PLAYER_AIM = true
	else:
		speed = walk_speed
		PLAYER_AIM = false
		
	var just_landed := is_on_floor() and snap_vector == Vector3.ZERO
	var is_jumping := is_on_floor() and Input.is_action_just_pressed("player_jump")
	if is_jumping:
		velocity.y = jump_strength
		snap_vector = Vector3.ZERO
	elif just_landed:
		snap_vector = Vector3.DOWN
		
	velocity.x = move_direction.x * speed
	velocity.z = move_direction.z * speed
	
	if move_direction != Vector3.ZERO and not PLAYER_AIM && is_on_floor():
		mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(velocity.x, velocity.z), mesh_rotation_lerp)
		
	apply_floor_snap()
	move_and_slide()
