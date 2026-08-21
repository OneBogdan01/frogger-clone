extends Node

var screenshot_num = 0
const SCREENSHOT_SAVE_PATH := "res://store_assets/screenshots/screenshot_%s.png"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("screenshot"):
		screenshot()


func screenshot():
	var file_path = SCREENSHOT_SAVE_PATH % screenshot_num
	while FileAccess.file_exists(file_path):
		screenshot_num += 1
		file_path = SCREENSHOT_SAVE_PATH % screenshot_num
	var img = get_viewport().get_texture().get_image()
	img.save_png(file_path)
	screenshot_num += 1
