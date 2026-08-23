extends Node2D
@export var lillypads_parent: Node2D

var _lillypad_to_activate := 0
signal level_completed


func _activated_lillypad():
	_lillypad_to_activate -= 1
	if _lillypad_to_activate == 0:
		level_completed.emit()
		print("Level complete!")
	else:
		_player_respawn()


func _player_killed():
	#TODO add health check
	_player_respawn()


func _player_respawn():
	%PlayerSpawnPoint.spawn_player()


func _ready() -> void:
	for child in lillypads_parent.get_children():
		var lillypad = child as Lillypad
		if lillypad:
			_lillypad_to_activate += 1
			lillypad.player_filled.connect(_activated_lillypad)
	%PlayerSpawnPoint.player_killed.connect(_player_killed)
