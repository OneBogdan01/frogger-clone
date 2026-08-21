extends Control

@onready var sub_viewport_container: SubViewportContainer = %SubViewportContainer
@onready var screenshots = %Screenshots.get_children()
@onready var sub_viewport: SubViewport = %SubViewport

const IMG_SAVE_PATH = "res://store_assets/screenshots/"
const IMG_SAVE_PATH_WITH_EXT = IMG_SAVE_PATH + "%s.png"


func _ready() -> void:
	take_all_screenshots()


func take_all_screenshots():
	DirAccess.make_dir_recursive_absolute(IMG_SAVE_PATH)
	ProjectSettings.set("display/window/stretch/mode", "disabled")

	%Screenshots.reparent(sub_viewport)

	screenshot_all()
	OS.shell_open(ProjectSettings.globalize_path(IMG_SAVE_PATH))


func screenshot_all():
	for screen in screenshots:
		screen.hide()
	for screen in screenshots:
		screen.show()
		get_window().size = screen.size
		sub_viewport.size = screen.size
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		take_screenshot(screen.name)
		screen.hide()
	get_tree().quit()


func take_screenshot(file_name: String):
	file_name = file_name.to_lower()
	var img = sub_viewport.get_viewport().get_texture().get_image()
	print("save with name ", file_name)
	print(IMG_SAVE_PATH_WITH_EXT % file_name)
	img.save_png(IMG_SAVE_PATH_WITH_EXT % file_name)
