extends Node2D

@export var under_water_color: Color
@export var outside_color: Color = Color.WHITE
@export var transition_duration := 1.3
@export var under_water := false


func _ready() -> void:
	if under_water:
		scale.x = 1.0 / get_parent().scale.x
		%OverWater.start()
		show()


func _enter_water():
	var tween = create_tween()
	tween.tween_property(self, "modulate", under_water_color, transition_duration)
	await tween.finished
	%ObstacleCollider.disabled = false
	%UnderWater.start()


func _exit_water():
	var tween = create_tween()
	tween.tween_property(self, "modulate", outside_color, transition_duration)
	await tween.finished
	%ObstacleCollider.disabled = true
	%OverWater.start()
