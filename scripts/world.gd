extends Node2D

@export var lillypads_parent: Node2D
@onready var player_spawn_point: Marker2D = %PlayerSpawnPoint

var _lillypad_to_activate := 0
signal level_completed
signal player_died
signal player_respawned
signal lillypad_filled


func _activated_lillypad():
	_lillypad_to_activate -= 1
	lillypad_filled.emit()
	print("lilypad filled: %s" % _lillypad_to_activate)
	if _lillypad_to_activate == 0:
		level_completed.emit()
		print("Level complete!")
	else:
		player_respawn()


func player_killed():
	player_died.emit()
	print("player killed")


func player_respawn():
	player_respawned.emit()
	print("player respawned")

	player_spawn_point.spawn_player()


func _ready() -> void:
	for child in lillypads_parent.get_children():
		var lillypad = child as Lillypad
		if lillypad:
			_lillypad_to_activate += 1
			lillypad.player_filled.connect(_activated_lillypad)
	%PlayerSpawnPoint.player_killed.connect(player_killed)
