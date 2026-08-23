extends Marker2D

@export var player_scene: PackedScene
@export var parent: Node2D
@export var spawn_on_ready := true

signal player_killed


func trigger_player_dead():
	player_killed.emit()


func _ready() -> void:
	if spawn_on_ready:
		spawn_player()


func spawn_player():
	if parent == null:
		parent = self
	var player_instance = player_scene.instantiate() as PlayerFrog
	player_instance.global_position = global_position
	player_instance.player_killed.connect(trigger_player_dead)
	parent.add_child.call_deferred(player_instance)
