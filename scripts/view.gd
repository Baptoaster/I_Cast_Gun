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

@export_group("TPS Mode")
@export var tps_distance = 3.0  # Distance de la caméra derrière le joueur
@export var tps_height = 0.6  # Hauteur de la caméra par rapport au personnage
@export var character_rotation_speed = 8.0  # Vitesse de rotation du personnage

var camera_rotation: Vector3
var zoom = 10
var is_aiming = false
var orbit_zoom = 10

@onready var camera = $Camera

func _ready():
	camera_rotation = rotation_degrees
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pass

func _physics_process(delta):
	
	# Gérer l'activation/désactivation du mode TPS
	if Input.is_action_just_pressed("aim"):
		is_aiming = true
		orbit_zoom = zoom
	elif Input.is_action_just_released("aim"):
		is_aiming = false
	
	if is_aiming:
		# Mode TPS : la caméra orbite autour du joueur
		
		# Calculer la position de la caméra en orbite autour du joueur
		var orbit_radius = tps_distance
		
		# Convertir les angles de camera_rotation en position orbitale
		var horizontal_angle = camera_rotation.y * PI / 180.0
		var vertical_angle = camera_rotation.x * PI / 180.0
		
		var camera_offset = Vector3(
			sin(horizontal_angle) * cos(vertical_angle) * orbit_radius,
			sin(vertical_angle) * orbit_radius + tps_height,
			-cos(horizontal_angle) * cos(vertical_angle) * orbit_radius
		)
		
		# Positionner la caméra directement
		self.global_position = target.position + camera_offset
		
		# Faire pointer la caméra vers le joueur
		self.look_at(target.position + Vector3(0, tps_height * 0.5, 0), Vector3.UP)
		camera.position = Vector3.ZERO
		
		# Rotation du personnage : il doit faire dos à la caméra
		# La direction derrière la caméra
		var camera_forward = -self.global_transform.basis.z
		var aim_direction = Vector3(camera_forward.x, 0, camera_forward.z).normalized()
		
		# Calculer l'angle cible pour le personnage (direction inverse de caméra)
		var target_angle_y = atan2(aim_direction.x, aim_direction.z) * 180.0 / PI
		
		# Interpoler la rotation du personnage
		var current_rotation = target.rotation_degrees.y
		var new_rotation_y = lerpf(current_rotation, target_angle_y, min(character_rotation_speed * delta, 1.0))
		
		var target_rotation = target.rotation_degrees
		target_rotation.y = new_rotation_y
		target.rotation_degrees = target_rotation
		
	else:
		# Mode orbite : comportement normal
		self.position = self.position.lerp(target.position, delta * 4)
		rotation_degrees = rotation_degrees.lerp(camera_rotation, delta * 6)
		camera.position = camera.position.lerp(Vector3(0, 0, zoom), 8 * delta)
	
	handle_input(delta)

# Handle input
func handle_input(delta):
	
	var input := Vector3.ZERO
	
	input.y = Input.get_axis("camera_left", "camera_right")
	input.x = Input.get_axis("camera_up", "camera_down")
	
	if is_aiming:
		# Mode TPS : rotation de la caméra basée sur camera_rotation
		camera_rotation += input.limit_length(1.0) * rotation_speed * delta
		
		# Mouvement de souris en mode TPS
		var mouse_motion = Input.get_last_mouse_velocity()
		camera_rotation.y -= -mouse_motion.x * mouse_sensitivity * delta
		camera_rotation.x -= mouse_motion.y * mouse_sensitivity * delta
		
		# Clamp rotation
		camera_rotation.x = clamp(camera_rotation.x, -85, 45)
	else:
		# Mode orbite : comportement original
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
