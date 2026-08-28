extends Label

@export var max_score_per_time := 1000.0

var _score := 0:
	set(value):
		_score = value
		text = str(_score)


func _ready() -> void:
	_score = 0


func increase_score(time_ratio: float):
	var increment := (int)(time_ratio * max_score_per_time)
	print("Score increased by: %s from %s" % [time_ratio, increment])
	_score += increment
