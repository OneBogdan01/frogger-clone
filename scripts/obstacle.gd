class_name Obstacle
extends Area2D

enum ObstacleType {
	WATER,
	CAR,
	ANIMAL,
	ENDMAP,
	TIME,
}
@export var obstacle_type: ObstacleType


func _physics_process(_delta: float) -> void:
	for area in get_overlapping_areas():
		var player = area as PlayerFrog
		if player == null:
			push_error("Player not found interacting with" + name)
			return
		player.destroy_player(obstacle_type)
