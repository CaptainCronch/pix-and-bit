extends SpringArm3D

var mouse_sensitivity := 0.15
var zoom_sensitivity := 1
var camera_acceleration := 1
var aim_speed := 0.1

var max_aim_zoom := 1.0
var min_zoom := 4
var max_zoom := 5
var max_offset := 3
var min_offset := 1

var _current_aim_zoom := 0.0

@onready var _player : CharacterBody3D = $".."
@onready var _camera : Camera3D = $CameraHolder/Camera3D
@onready var _camera_holder : Node3D = $CameraHolder

var aim_zoom := _current_aim_zoom


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if event is InputEventMouseMotion: #and not _player.holding_frisbee
		rotation_degrees.x -= event.relative.y * mouse_sensitivity
		rotation_degrees.x = clamp(rotation_degrees.x, -89.0, 89.0)
		
		rotation_degrees.y -= event.relative.x * mouse_sensitivity
		rotation_degrees.y = wrapf(rotation_degrees.y, 0.0, 360.0)


func _process(delta):
	if Input.is_action_just_pressed("mouse_escape"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.is_action_just_pressed("fullscreen"):
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (!((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))) else Window.MODE_WINDOWED
	
	_current_aim_zoom = lerp(_current_aim_zoom, aim_zoom, aim_speed)
	
	spring_length = lerp(min_zoom - _current_aim_zoom, max_zoom - _current_aim_zoom,
			clamp(inverse_lerp(50, -50, rotation_degrees.x), 0, 1))
	
	# the camera offset is always proportional to the rotation
	_player.camera_offset.y = lerp(min_offset - _current_aim_zoom,
			max_offset - _current_aim_zoom,
			clamp(inverse_lerp(70.0, -30.0, rotation_degrees.x), 0, 1))
	
	var aim_offset = Vector3(_current_aim_zoom, 0, 0).rotated(Vector3.UP, rotation.y)
	_camera.global_position = lerp(_camera.global_position + aim_offset,
			_camera_holder.global_position + aim_offset, camera_acceleration)
	
	_camera.rotation = rotation
