extends Node3D

enum CameraMode { ORBIT, AIM }

@export_group("Properties")
@export var target: Node

@export_group("Zoom")
@export var zoom_minimum = 16
@export var zoom_maximum = 4
@export var zoom_speed = 10

@export_group("Rotation")
@export var rotation_speed = 120
@export var mouse_sensitivity = 0.1

@export_group("Aim")
@export var aim_shoulder_x = 0.6
@export var aim_shoulder_y = 0.2
@export var aim_distance = 3.0

var camera_rotation: Vector3
var zoom = 10
var current_mode = CameraMode.ORBIT
var is_aiming: bool = false

@onready var camera = $Camera

func _ready():

	camera_rotation = rotation_degrees # Initial rotation

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):

	# Set position and rotation to targets

	self.position = self.position.lerp(target.position, delta * 4)
	rotation_degrees = rotation_degrees.lerp(camera_rotation, delta * 6)

	# Lerp camera toward the target offset for the current mode
	var target_offset: Vector3
	if current_mode == CameraMode.AIM:
		target_offset = Vector3(aim_shoulder_x, aim_shoulder_y, aim_distance)
	else:
		target_offset = Vector3(0, 0, zoom)

	camera.position = camera.position.lerp(target_offset, 8 * delta)

	handle_input(delta)

# Handle input

func handle_input(delta):

	# Switch camera mode on aim input
	is_aiming = Input.is_action_pressed("aim")
	current_mode = CameraMode.AIM if is_aiming else CameraMode.ORBIT

	# Rotation

	var input := Vector3.ZERO

	input.y = Input.get_axis("camera_left", "camera_right")
	input.x = Input.get_axis("camera_up", "camera_down")

	camera_rotation += input.limit_length(1.0) * rotation_speed * delta

	# Mouse orbit
	var mouse_motion = Input.get_last_mouse_velocity()
	camera_rotation.y -= mouse_motion.x * mouse_sensitivity * delta
	camera_rotation.x -= mouse_motion.y * mouse_sensitivity * delta

	# Clamp pitch — tighter when aiming
	if is_aiming:
		camera_rotation.x = clamp(camera_rotation.x, -60, -5)
	else:
		camera_rotation.x = clamp(camera_rotation.x, -80, -10)

	# Zooming (orbit mode only)
	if not is_aiming:
		zoom += Input.get_axis("zoom_in", "zoom_out") * zoom_speed * delta
		zoom = clamp(zoom, zoom_maximum, zoom_minimum)
