extends Node

@export_dir var path_to_levels := "res://template_scenes/levels/"

var _levels_file_names: Array[StringName]

@export_file("*.tscn")
var next_level := "res://template_scenes/levels/"


func load_next_level():
	SceneLoader.load_scene(next_level, true)
	await SceneLoader.scene_loaded
	SceneLoader.change_scene_to_resource()


func _ready() -> void:
	var dir_access := DirAccess.open(path_to_levels)
	if dir_access:
		dir_access.list_dir_begin()
		var file_name = dir_access.get_next()
		while file_name != "":
			if dir_access.current_is_dir() == false:
				_levels_file_names.push_back(path_to_levels + file_name)
				print("Level found at path %s " % path_to_levels + file_name)
			file_name = dir_access.get_next()
	else:
		push_error("An error occurred when trying to access the path.")
