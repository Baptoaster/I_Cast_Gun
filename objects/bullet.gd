extends Area3D

@export var lifetime := 3.0

var direction := Vector3.ZERO
var speed := 0.0

func setup(dir: Vector3, bullet_speed: float) -> void:
	direction = dir.normalized()
	speed = bullet_speed

func _ready():
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_body_entered(body):
	queue_free()
