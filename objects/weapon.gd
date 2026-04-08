extends Node3D

@export var bullet_scene: PackedScene
@export var muzzle_path: NodePath
@export var bullet_speed := 60.0

@onready var muzzle: Marker3D = get_node(muzzle_path)

func aim_at(target_point: Vector3) -> void:
	look_at(target_point, Vector3.UP)

func fire(target_point: Vector3) -> void:
	if bullet_scene == null:
		return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	var origin = muzzle.global_transform.origin
	bullet.global_transform.origin = origin

	var direction = (target_point - origin).normalized()
	bullet.setup(direction, bullet_speed)
