extends VSlider

@export var starting_time := 60.0

signal time_run_out


func _ready() -> void:
	reset()


func reset():
	max_value = starting_time
	value = starting_time


func _physics_process(delta: float) -> void:
	value -= delta
	if value <= 0.0:
		time_run_out.emit()
		reset()
