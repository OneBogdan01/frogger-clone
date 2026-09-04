class_name Lillypad
extends Area2D

signal player_filled

@export_group("Pad impact")
@export var impact_squash := Vector2(1.26, 0.72)
@export var impact_time := 0.07
@export var rebound := Vector2(0.90, 1.12)
@export var rebound_time := 0.13
@export var wobble := Vector2(1.05, 0.96)
@export var wobble_time := 0.11
@export var settle_time := 0.18

@export_group("Frog")
@export var frog_squash := Vector2(1.12, 0.88)
@export var frog_lag := 0.03
@export var frog_dip := 6.0
@export var frog_turn_delay := 0.08 # beat between landing and turning
@export var frog_turn_time := 0.22
@export var frog_turn_squash := Vector2(0.88, 1.10) # narrows as it pivots
var _base_scale := Vector2.ONE
var _frog_base_y := 0.0
var _filled := false
var _tween: Tween
var _frog_tween: Tween
var _frog_scale: Vector2


func _ready() -> void:
	_base_scale = %Visuals.scale
	_frog_base_y = %Frog.position.y
	_frog_scale = %Frog.scale
	%Frog.rotation = 0.0 # default art looks up
	%FilledSprite.hide()
	%Frog.hide()


func _land_frog() -> void:
	if _frog_tween and _frog_tween.is_valid():
		_frog_tween.kill()

	# appear already deformed — mid-landing is never at rest scale
	%Frog.scale = _frog_scale * frog_squash
	%Frog.position.y = _frog_base_y
	%Frog.rotation = 0.0
	%Frog.show()

	var recover := rebound_time + wobble_time

	_frog_tween = create_tween()
	_frog_tween.set_parallel(true)

	# --- landing: ride the pad down, then come back up, lagged behind it
	_frog_tween.tween_property(%Frog, "position:y", _frog_base_y + frog_dip, impact_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_frog_tween.chain().tween_property(%Frog, "position:y", _frog_base_y, recover) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(frog_lag)
	_frog_tween.parallel().tween_property(%Frog, "scale", _frog_scale, recover) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT).set_delay(frog_lag)

	# --- turn: starts only once the landing has settled
	_frog_tween.chain().tween_interval(frog_turn_delay)

	_frog_tween.chain().tween_property(%Frog, "rotation", PI, frog_turn_time) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# squeeze narrow through the pivot, then back out — sells it as a body turning
	_frog_tween.parallel().tween_property(%Frog, "scale", _frog_scale * frog_turn_squash, frog_turn_time * 0.4) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_frog_tween.chain().tween_property(%Frog, "scale", _frog_scale, frog_turn_time * 0.6) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _scale_step(t: Tween, node: Node2D, base: Vector2, mult: Vector2, dur: float) -> PropertyTweener:
	return t.tween_property(node, "scale", base * mult, dur)


func _on_area_entered(area: Area2D) -> void:
	# assume player can only collide with this
	if _filled:
		return
	_filled = true

	%CollisionShape2D.set_deferred("disabled", true)
	player_filled.emit()
	area.queue_free()
	_squash()
	_land_frog()


func _squash() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()

	_scale_step(_tween, %Visuals, _base_scale, impact_squash, impact_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_callback(%FilledSprite.show)
	_scale_step(_tween, %Visuals, _base_scale, rebound, rebound_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_scale_step(_tween, %Visuals, _base_scale, wobble, wobble_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_scale_step(_tween, %Visuals, _base_scale, Vector2.ONE, settle_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
