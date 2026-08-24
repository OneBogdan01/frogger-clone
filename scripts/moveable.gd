class_name Moveable
extends Area2D

@export var speed: float = 100.0
@export var multiply_on_reset: Vector2 = Vector2(0.0, 1.0)
@export var distance_to_reset := 320 + 32

var _direction := Vector2.RIGHT
var _distance_traveled := 0.0
signal moved(increment: Vector2)
@export_enum("Left", "Right") var dir: String = "Right":
	set(value):
		dir = value
		_direction = Vector2.LEFT if value == "Left" else Vector2.RIGHT


func reset_position():
	position.x *= multiply_on_reset.x
	position.y *= multiply_on_reset.y
	_distance_traveled = 0.0


func _ready() -> void:
	_distance_traveled = position.x


func _physics_process(delta: float) -> void:
	var increment := delta * speed * _direction
	moved.emit(increment)
	position += increment
	_distance_traveled += increment.x
	if _distance_traveled > distance_to_reset:
		reset_position()
