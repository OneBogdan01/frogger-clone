class_name PlayerFrog
extends Area2D

@export var tile_size := 16.0
@export var hop_time := .1
@export var water_dead_effect: PackedScene

@onready var ray_direction: RayCast2D = %RayDirection
@export_flags_2d_physics var platform_layers
const MOVES := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
}
var _tween: Tween

signal player_killed

var original_parent: Node2D


func _ready() -> void:
	original_parent = get_parent()


func is_platform(area: Area2D):
	return (area.collision_layer & platform_layers) != 0


func spawn_effect(scene: PackedScene):
	var instance = scene.instantiate()
	instance.global_position = global_position
	get_parent().add_child(instance)


func destroy_player(obstacle_type: Obstacle.ObstacleType):
	match obstacle_type:
		Obstacle.ObstacleType.WATER:
			if get_overlapping_areas().any(is_platform):
				return
			spawn_effect(water_dead_effect)
		Obstacle.ObstacleType.ANIMAL:
			print("player eaten by an animal")

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


func change_shadow():
	%Shadow.frame = %Sprite2D.frame


func move_frog(direction: Vector2i):
	if _tween and _tween.is_running():
		return

	ray_direction.target_position = direction * tile_size
	ray_direction.force_raycast_update()
	if ray_direction.is_colliding() == false:
		%Sprite2D.look_at(to_global(ray_direction.target_position.rotated(PI / 2)))

		_tween = create_tween()
		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.set_trans(Tween.TRANS_SINE)
		_tween.tween_property(%Sprite2D, "frame", %Sprite2D.hframes - 1, hop_time)
		_tween.tween_property(self, "position", position + direction * tile_size, hop_time)
		await _tween.finished
		%Sprite2D.frame = 0


func move_on_platform(increment: Vector2):
	position += increment


func to_moveable(area: Area2D) -> Moveable:
	var moveable_node = area as Node2D
	return moveable_node as Moveable


func _on_area_entered(area: Area2D) -> void:
	if is_platform(area):
		print("moved by" + area.name)
		var moveable = to_moveable(area)
		moveable.moved.connect(move_on_platform)


func _on_area_exited(area: Area2D) -> void:
	print("exited" + area.name)
	if is_platform(area):
		print("disconnect by" + area.name)
		var moveable = to_moveable(area)
		moveable.moved.disconnect(move_on_platform)
