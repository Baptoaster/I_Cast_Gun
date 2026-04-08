extends CharacterBody3D

enum EnemyState {
	PATROL,
	CHASE
}

@export var patrol_radius: float = 12.0
@export var detection_radius: float = 10.0
@export var patrol_speed: float = 2.0
@export var chase_speed: float = 5.0
@export var repath_interval: float = 0.3
@export var wait_time_min: float = 1.0
@export var wait_time_max: float = 3.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $DetectionArea
@onready var patrol_timer: Timer = $PatrolTimer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var state: int = EnemyState.PATROL
var player: Node3D = null
var patrol_origin: Vector3
var repath_timer := 0.0
var current_patrol_target: Vector3
var target_reached_threshold := 1.0

func _ready():
	patrol_origin = global_position
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	patrol_timer.one_shot = true
	_set_state(EnemyState.PATROL)

func _physics_process(delta):
	match state:
		EnemyState.PATROL:
			_process_patrol(delta)
		EnemyState.CHASE:
			_process_chase(delta)

func _set_state(new_state: int) -> void:
	if state == new_state:
		return

	state = new_state

	match state:
		EnemyState.PATROL:
			_enter_patrol()
		EnemyState.CHASE:
			_enter_chase()
			
func _enter_patrol() -> void:
	animation_player.play("walk")
	_pick_new_patrol_target()

func _process_patrol(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		if patrol_timer.is_stopped():
			patrol_timer.start(randf_range(wait_time_min, wait_time_max))
		return

	var next_position = nav_agent.get_next_path_position()
	_move_towards(next_position, patrol_speed, delta)

func _pick_new_patrol_target() -> void:
	var random_offset = Vector3(
		randf_range(-patrol_radius, patrol_radius),
		0,
		randf_range(-patrol_radius, patrol_radius)
	)

	var candidate = patrol_origin + random_offset
	current_patrol_target = _get_valid_nav_point(candidate)
	nav_agent.target_position = current_patrol_target

func _on_PatrolTimer_timeout() -> void:
	if state == EnemyState.PATROL:
		_pick_new_patrol_target()
		
func _enter_chase() -> void:
	animation_player.play("run")
	repath_timer = 0.0

func _process_chase(delta: float) -> void:
	if player == null:
		_set_state(EnemyState.PATROL)
		return

	repath_timer -= delta
	if repath_timer <= 0.0:
		repath_timer = repath_interval
		if not _is_player_reachable():
			_set_state(EnemyState.PATROL)
			return
		nav_agent.target_position = player.global_position

	if not _is_player_reachable():
		_set_state(EnemyState.PATROL)
		return

	var next_position = nav_agent.get_next_path_position()
	_move_towards(next_position, chase_speed, delta)
	
func _on_detection_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player = body
		if _is_player_reachable():
			_set_state(EnemyState.CHASE)

func _on_detection_body_exited(body: Node) -> void:
	if body == player:
		player = null
		_set_state(EnemyState.PATROL)
		
func _is_player_reachable() -> bool:
	if player == null:
		return false

	var distance = global_position.distance_to(player.global_position)
	if distance > detection_radius:
		return false

	var path = NavigationServer3D.map_get_path(
		get_world_3d().navigation_map,
		global_position,
		player.global_position,
		true
	)

	return path.size() > 0
	
func _move_towards(target: Vector3, speed: float, delta: float) -> void:
	var direction = (target - global_position)
	direction.y = 0
	direction = direction.normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# Gravity à gérer selon ton système
	move_and_slide()
	
func _get_valid_nav_point(point: Vector3) -> Vector3:
	# Selon Godot / navigation utilisée, tu peux "projeter" le point vers le mesh navigable.
	# Ici, on renvoie une cible approchée valide.
	return point
