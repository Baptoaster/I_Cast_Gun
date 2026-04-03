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

@export_group("AIM Mode")
@export var tps_distance = 3.0
@export var tps_height = 0.6
@export var character_rotation_speed = 8.0

var camera_rotation: Vector3
var zoom = 10
var is_aiming = false
var orbit_zoom = 10

@onready var camera = $Camera


func _ready():
	camera_rotation = rotation_degrees
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta):

	# ===== TOGGLE AIM =====
	if Input.is_action_just_pressed("aim"):
		is_aiming = true
		orbit_zoom = zoom
		align_character_to_camera(delta)

	elif Input.is_action_just_released("aim"):
		is_aiming = false

	# ===== AIM MODE =====
	if is_aiming:
		
		var orbit_radius = tps_distance
		
		var horizontal_angle = deg_to_rad(camera_rotation.y)
		var vertical_angle = deg_to_rad(camera_rotation.x)
		
		var camera_offset = Vector3(
			sin(horizontal_angle) * cos(vertical_angle) * orbit_radius,
			sin(vertical_angle) * orbit_radius + tps_height,
			-cos(horizontal_angle) * cos(vertical_angle) * orbit_radius
		)
		
		global_position = target.global_position + camera_offset
		
		look_at(target.global_position + Vector3(0, tps_height * 0.5, 0), Vector3.UP)
		camera.position = Vector3.ZERO
		
		# Rotation fluide du personnage
		var forward = -global_transform.basis.z
		var flat_forward = Vector3(forward.x, 0, forward.z).normalized()
		
		if flat_forward.length() > 0.001:
			var target_angle = atan2(flat_forward.x, flat_forward.z)
			var current_angle = deg_to_rad(target.rotation_degrees.y)
			
			var new_angle = lerp_angle(
				current_angle,
				target_angle,
				min(character_rotation_speed * delta, 1.0)
			)
			
			target.rotation_degrees.y = rad_to_deg(new_angle)

	# ===== ORBIT MODE =====
	else:
		self.position = self.position.lerp(target.position, delta * 4)
		rotation_degrees = rotation_degrees.lerp(camera_rotation, delta * 6)
		camera.position = camera.position.lerp(Vector3(0, 0, zoom), 8 * delta)

	handle_input(delta)


# ===== INPUT =====
func handle_input(delta):

	var input := Vector3.ZERO
	
	input.y = Input.get_axis("camera_left", "camera_right")
	input.x = Input.get_axis("camera_up", "camera_down")
	
	if is_aiming:
		camera_rotation += input.limit_length(1.0) * rotation_speed * delta
		
		var mouse_motion = Input.get_last_mouse_velocity()
		camera_rotation.y -= -mouse_motion.x * mouse_sensitivity * delta
		camera_rotation.x -= mouse_motion.y * mouse_sensitivity * delta
		
		camera_rotation.x = clamp(camera_rotation.x, -85, 45)
	else:
		camera_rotation += input.limit_length(1.0) * rotation_speed * delta
		
		var mouse_motion = Input.get_last_mouse_velocity()
		camera_rotation.y -= mouse_motion.x * mouse_sensitivity * delta
		camera_rotation.x -= mouse_motion.y * mouse_sensitivity * delta
		
		camera_rotation.x = clamp(camera_rotation.x, -80, -10)
		
		zoom += Input.get_axis("zoom_in", "zoom_out") * zoom_speed * delta
		zoom = clamp(zoom, zoom_maximum, zoom_minimum)


# ===== ALIGN CHARACTER (FIX MAJEUR) =====
func align_character_to_camera(delta):
	self.position = self.position.lerp(target.position, delta * 4)
	rotation_degrees = rotation_degrees.lerp(camera_rotation, delta * 6)
	camera.position = camera.position.lerp(Vector3(0, 0, zoom), 8 * delta)
	
	var forward = -global_transform.basis.z
	var flat_forward = Vector3(forward.x, 0, forward.z).normalized()
	
	if flat_forward.length() > 0.001:
		var angle = atan2(flat_forward.x, flat_forward.z)
		target.rotation_degrees.y = rad_to_deg(angle)
