extends Node3D

@export_group("Properties")
@export var target: Node

@export_group("Zoom")
@export var zoom_minimum = 16
@export var zoom_maximum = 4
@export var zoom_speed = 10

@export_group("Rotation")
@export var rotation_speed = 120
@export var mouse_sensitivity = 0.1

var camera_rotation:Vector3
var zoom = 10

@onready var camera = $Camera

func _ready():
	
	camera_rotation = rotation_degrees # Initial rotation
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pass

func _physics_process(delta):
	
	# Set position and rotation to targets
	
	self.position = self.position.lerp(target.position, delta * 4)
	rotation_degrees = rotation_degrees.lerp(camera_rotation, delta * 6)
	
	camera.position = camera.position.lerp(Vector3(0, 0, zoom), 8 * delta)
	
	handle_input(delta)

# Handle input

func handle_input(delta):
	
	# Rotation
	
	var input := Vector3.ZERO
	
	input.y = Input.get_axis("camera_left", "camera_right")
	input.x = Input.get_axis("camera_up", "camera_down")
	
	camera_rotation += input.limit_length(1.0) * rotation_speed * delta
		
		# Mouvement de souris en mode orbite
	var mouse_motion = Input.get_last_mouse_velocity()
	camera_rotation.y -= mouse_motion.x * mouse_sensitivity * delta
	camera_rotation.x -= mouse_motion.y * mouse_sensitivity * delta
		
		# Clamp rotation
	camera_rotation.x = clamp(camera_rotation.x, -80, -10)
		
		# Zooming (seulement en mode orbite)
	zoom += Input.get_axis("zoom_in", "zoom_out") * zoom_speed * delta
	zoom = clamp(zoom, zoom_maximum, zoom_minimum)
