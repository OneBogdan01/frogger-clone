extends Area2D

@export var tile_size := 16.0

var _direction: Vector2


func _ready() -> void:
	position = position.snapped(Vector2.ONE * tile_size)
	position += Vector2.ONE * tile_size / 2


# TODO make frog like movement
func _physics_process(_delta: float) -> void:
	position += _direction * tile_size
	_direction = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_down"):
		_direction.y = 1
	elif event.is_action_pressed("move_up"):
		_direction.y = -1
	elif event.is_action_pressed("move_right"):
		_direction.x = 1
	elif event.is_action_pressed("move_left"):
		_direction.x = -1
