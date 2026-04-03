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

var camera_rotation:Vector3
var zoom = 10
var is_aiming = false  # Mode TPS activé
var orbit_zoom = 10  # Sauvegarde du zoom en mode orbite

@onready var camera = $Camera

func _ready():
	camera_rotation = rotation_degrees # Initial rotation
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
		
		# Forcer le joueur à regarder dans la direction de la caméra (inverser l'axe Y)
		var target_rotation = target.rotation_degrees
		target_rotation.y = camera_rotation.y + 180  # +180 pour voir le dos
		target.rotation_degrees = target_rotation
		
		# Calculer la position de la caméra en orbite autour du joueur
		# Basée sur les angles de la caméra
		var orbit_radius = tps_distance
		
		# Convertir les angles en position orbitale
		var horizontal_angle = camera_rotation.y * PI / 180.0
		var vertical_angle = camera_rotation.x * PI / 180.0
		
		var camera_offset = Vector3(
			sin(horizontal_angle) * cos(vertical_angle) * orbit_radius,
			sin(vertical_angle) * orbit_radius + tps_height,
			-cos(horizontal_angle) * cos(vertical_angle) * orbit_radius
		)
		
		# Positionner la caméra directement sans lerp pour centrer le joueur
		self.global_position = target.position + camera_offset
		
		# Appliquer la rotation de la caméra
		rotation_degrees = camera_rotation
		camera.position = Vector3.ZERO
		
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
		# Mode TPS : rotation de la caméra
		camera_rotation += input.limit_length(1.0) * rotation_speed * delta
		
		# Mouvement de souris en mode TPS
		var mouse_motion = Input.get_last_mouse_velocity()
		camera_rotation.y -= mouse_motion.x * mouse_sensitivity * delta
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
