extends Button

func _ready() -> void:
	visible = OS.has_feature("editor")
