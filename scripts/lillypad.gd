class_name Lillypad
extends Area2D

signal player_filled


func _on_area_entered(area: Area2D) -> void:
	# assume player can only collide with this
	%CollisionShape2D.set_deferred("disabled", true)
	player_filled.emit()
	%FilledSprite.show()
	area.queue_free()
