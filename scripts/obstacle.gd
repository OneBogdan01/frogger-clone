class_name Obstacle
extends Area2D

enum ObstacleType {
	Water,
	Car,
	Snake,
	Crocodile,
	EndMap,
}
@export var obstacle_type: ObstacleType


func _on_area_entered(area: Area2D) -> void:
	var player = area as PlayerFrog
	if player == null:
		push_error("Player not found interacting with" + name)
		return
	player.destroy_player(obstacle_type)
