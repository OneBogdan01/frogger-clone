extends Node
## Node for opening a pause menu when detecting a 'ui_cancel' event.

@export var pause_menu_packed: PackedScene
var pause_menu: Node


func pause() -> void:
	if pause_menu.visible:
		return

	pause_menu.show()
	if pause_menu is CanvasLayer:
		await pause_menu.visibility_changed
	else:
		await pause_menu.hidden


# If pause menu should take precedence, override _input() instead.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		pause()


func _ready() -> void:
	pause_menu = pause_menu_packed.instantiate()
	pause_menu.hide()
	get_tree().current_scene.call_deferred("add_child", pause_menu)
