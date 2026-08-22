class_name PlayerFrog
extends Area2D

@export var tile_size := 16.0
@export var hop_time := .1
@onready var ray_direction: RayCast2D = %RayDirection

const MOVES := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
}
var _tween: Tween

signal player_killed


func destroy_player(obstacle_type: Obstacle.ObstacleType):
	#TODO animate kill
	#match obstacle_type:
	#Obstacle.ObstacleType.Water:
	#pass
	player_killed.emit()
	queue_free()


func _process(_delta: float) -> void:
	for action in MOVES:
		if Input.is_action_just_pressed(action):
			move_frog(MOVES[action])
			return


func move_frog(direction: Vector2i):
	if _tween and _tween.is_running():
		return

	ray_direction.target_position = direction * tile_size
	ray_direction.force_raycast_update()
	if ray_direction.is_colliding() == false:
		_tween = create_tween()
		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.set_trans(Tween.TRANS_SINE)
		_tween.tween_property(self, "position", position + direction * tile_size, hop_time)
		await _tween.finished


func _on_area_entered(area: Area2D) -> void:
	print(area.name)
