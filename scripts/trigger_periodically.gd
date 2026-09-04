extends Node2D
## TODO AI code below, clean up later

@export var under_water_color: Color
@export var outside_color: Color = Color.WHITE
@export var transition_duration := 1.3
@export var under_water := false

@export_group("Snap")
@export var anticipation_time := 0.30
@export var anticipation_squash := Vector2(1.14, 0.80) # widen + flatten: wind-up
@export var snap_time := 0.07
@export var snap_stretch := Vector2(0.90, 1.18) # narrow + tall: lunge
@export var settle_time := 0.20
@export var close_time := 0.14

@export_group("Close")
@export var close_anticipation_time := 0.10
@export var close_anticipation_stretch := Vector2(0.94, 1.10) # gape wider: recoil
@export var close_impact_time := 0.06
@export var close_impact_squash := Vector2(1.16, 0.82) # hard flatten: the slam
@export var close_rebound_time := 0.10
@export var close_rebound := Vector2(0.97, 1.05)
@export var close_settle_time := 0.14
const FRAME_CLOSED := 0
const FRAME_OPEN := 1

var _base_scale := Vector2.ONE
var _snap_tween: Tween
var _color_tween: Tween


func _ready() -> void:
	if under_water:
		await get_tree().create_timer(randf_range(0.3, %OverWater.wait_time * 3.0)).timeout
		%OverWater.start()
		show()
	_base_scale = scale
	%HeadSprite.frame = FRAME_CLOSED


func _scale_step(t: Tween, mult: Vector2, dur: float) -> PropertyTweener:
	return t.tween_property(self, "scale", _base_scale * mult, dur)


func _fade_to(color: Color) -> void:
	if _color_tween and _color_tween.is_valid():
		_color_tween.kill()
	_color_tween = create_tween()
	_color_tween.tween_property(self, "modulate", color, transition_duration)


func _open_mouth() -> void:
	if _snap_tween and _snap_tween.is_valid():
		_snap_tween.kill()
	_snap_tween = create_tween()

	# 1. anticipation — slow, eases into the crouch so the player can read it
	_scale_step(_snap_tween, anticipation_squash, anticipation_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 2. the snap — frame flip and hitbox both land on this instant
	_snap_tween.tween_callback(
		func() -> void:
			%HeadSprite.frame = FRAME_OPEN
			%ObstacleCollider.disabled = false
	)
	_scale_step(_snap_tween, snap_stretch, snap_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. settle — slight overshoot back to rest
	_scale_step(_snap_tween, Vector2.ONE, settle_time) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close_mouth() -> void:
	if _snap_tween and _snap_tween.is_valid():
		_snap_tween.kill()
	_snap_tween = create_tween()

	# hitbox off immediately — forgiving, and the player shouldn't die
	# to a mouth that's visually on its way shut
	%ObstacleCollider.disabled = true

	# 1. recoil — gapes slightly wider before slamming
	_scale_step(_snap_tween, close_anticipation_stretch, close_anticipation_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 2. impact — frame flips here, at the moment of the slam
	_snap_tween.tween_callback(
		func() -> void:
			%HeadSprite.frame = FRAME_CLOSED
	)
	_scale_step(_snap_tween, close_impact_squash, close_impact_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# 3. rebound + settle — decaying, so it reads as weight
	_scale_step(_snap_tween, close_rebound, close_rebound_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_scale_step(_snap_tween, Vector2.ONE, close_settle_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _enter_water() -> void:
	_fade_to(under_water_color)
	_open_mouth()
	%UnderWater.start()


func _exit_water() -> void:
	_fade_to(outside_color)
	_close_mouth()
	%OverWater.start()
