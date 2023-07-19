extends Node

var pix
var bit

var pix_camera
var bit_camera


func _process(delta):
	if Input.is_action_just_pressed("mouse_escape"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.is_action_just_pressed("fullscreen"):
		get_window().mode = Window.MODE_FULLSCREEN if (!(get_window().mode == Window.MODE_FULLSCREEN)) else Window.MODE_WINDOWED
