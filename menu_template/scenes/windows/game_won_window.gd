@tool
extends OverlaidWindow

signal continue_pressed
signal main_menu_pressed


func _ready():
	if OS.has_feature("web"):
		%ExitButton.hide()


func _on_exit_button_pressed():
	get_tree().quit()


func _load_scene(scene_path: String) -> void:
	_scene_tree.paused = false
	SceneLoader.load_scene(scene_path)


func _on_main_menu_button_pressed():
	_load_scene(AppConfig.main_menu_scene_path)


func _on_close_button_pressed():
	continue_pressed.emit()
	close()


func _on_main_menu_confirmation_confirmed():
	main_menu_pressed.emit()
