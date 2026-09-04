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
	%HUD.time_slider.time_run_out.connect(%World.player_killed)
	%World.player_respawned.connect(%HUD.time_slider.reset)
	%World.player_died.connect(_player_died)
	%World.lillypad_filled.connect(_on_world_lillypad_filled)
	%World.level_completed.connect(load_next_level)


func _player_died():
	var has_health = false
	for node in %HUD.health_container.get_children():
		var tex_rect = node as TextureRect
		if tex_rect and tex_rect.visible:
			tex_rect.hide()
			has_health = true
			break
	if has_health == false:
		%GameOverController.game_over()
	else:
		%World.player_respawn()


func _on_world_lillypad_filled() -> void:
	%HUD.score.increase_score(%HUD.time_slider.ratio)
