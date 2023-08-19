extends Node

var pix : CharacterBody3D
var bit : CharacterBody3D

var p1_camera : Camera3D
var p2_camera : Camera3D

var left_view : SubViewport
var right_view : SubViewport


func _ready():
	get_tree().get_root().connect("size_changed", _on_window_resize)


func _process(delta):
	if Input.is_action_just_pressed("mouse_escape"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.is_action_just_pressed("pix_menu"):
		get_tree().quit() # temporary for testing
	
	if Input.is_action_just_pressed("fullscreen"):
		get_window().mode = Window.MODE_FULLSCREEN if (!(get_window().mode == Window.MODE_FULLSCREEN)) else Window.MODE_WINDOWED


func _on_window_resize():
	var window_size = get_tree().get_root().get_visible_rect().size
	left_view.size = Vector2(window_size.x/2, window_size.y)
	right_view.size = Vector2(window_size.x/2, window_size.y)
