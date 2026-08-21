extends Label

@onready var last_frame := Time.get_ticks_usec()

var fps_display_visible: bool:
	set(b):
		set_process(b)
		fps_display_visible = b
		visible = b


func _ready() -> void:
	hide()


func _process(_delta: float) -> void:
	var fps_time = "FPS: %s \n" % [Engine.get_frames_per_second()]
	var new_time := Time.get_ticks_usec()
	var ms_time = "MS: %s" % [(new_time - last_frame) * 0.001]
	text = fps_time + ms_time
	last_frame = new_time
