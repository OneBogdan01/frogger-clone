class_name PlayerFrog
extends Area2D

@export var tile_size := 16.0
@export var hop_time := .1
@export var water_dead_effect: PackedScene
@export var killed_dead_effect: PackedScene
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


func animate_intro(node: Node2D):
	node.position += Vector2.DOWN * tile_size
	animate_movement(node, Vector2.UP, node.position)
	animate_stretch_squash(node)


func _ready() -> void:
	original_parent = get_parent()

	animate_intro(%Sprite2D)
	animate_intro(%Shadow)


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
			spawn_effect(killed_dead_effect)
		Obstacle.ObstacleType.CAR:
			print("player killed by car")
			spawn_effect(killed_dead_effect)
		Obstacle.ObstacleType.TIME:
			print("player killed by time")
			spawn_effect(killed_dead_effect)
		Obstacle.ObstacleType.ENDMAP:
			print("player killed by map")
			spawn_effect(killed_dead_effect)

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


@export var anticipate_time := 0.06
@export var land_time := 0.07

const SQUASH := Vector2(1.30, 0.70) # crouch
const STRETCH := Vector2(0.75, 1.35) # airborne
const LANDING := Vector2(1.25, 0.75) # impact


func move_frog(direction: Vector2i) -> void:
	if _tween and _tween.is_running():
		return
	%JumpSound.play()
	ray_direction.target_position = direction * tile_size
	ray_direction.force_raycast_update()
	if ray_direction.is_colliding():
		return

	var spr: Sprite2D = %Sprite2D
	spr.look_at(to_global(ray_direction.target_position.rotated(PI / 2)))
	spr.scale = Vector2.ONE
	animate_movement(self, direction, position)
	animate_stretch_squash(spr)


func animate_movement(node: Node2D, direction: Vector2, old_position: Vector2):
	_tween = create_tween()
	_tween.tween_interval(anticipate_time)
	_tween.tween_property(
		node,
		"position",
		old_position + Vector2(direction) * tile_size,
		hop_time,
	) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func animate_stretch_squash(spr: Sprite2D):
	var deform := create_tween()
	deform.tween_property(spr, "scale", SQUASH, anticipate_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	deform.tween_callback(func(): spr.frame = spr.hframes - 1)
	deform.tween_property(spr, "scale", STRETCH, hop_time * 0.35) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	deform.tween_property(spr, "scale", Vector2(1.05, 0.95), hop_time * 0.65) \
			.set_trans(Tween.TRANS_SINE)
	deform.tween_callback(func(): spr.frame = 0)
	deform.tween_property(spr, "scale", LANDING, land_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	deform.tween_property(spr, "scale", Vector2.ONE, land_time * 2.0) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


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
