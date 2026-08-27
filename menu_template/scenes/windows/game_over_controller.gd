extends Node

@export var game_over_menu_packed: PackedScene
var game_over_menu: Node


func game_over() -> void:
	if game_over_menu.visible:
		return

	game_over_menu.show()
	if game_over_menu is CanvasLayer:
		await game_over_menu.visibility_changed
	else:
		await game_over_menu.hidden


func _ready() -> void:
	game_over_menu = game_over_menu_packed.instantiate()
	game_over_menu.hide()
	get_tree().current_scene.call_deferred("add_child", game_over_menu)
