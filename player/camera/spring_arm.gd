extends SpringArm

export var mouse_sensitivity := 0.15
export var zoom_sensitivity := 1
export var camera_acceleration := 1
export var aim_speed := 0.1

export var max_aim_zoom := 1.0
export var min_zoom := 4
export var max_zoom := 5
export var max_offset := 3
export var min_offset := 1

var _current_aim_zoom := 0.0

onready var _player : KinematicBody = $".."
onready var _camera : Camera = $CameraHolder/Camera
onready var _camera_holder : Spatial = $CameraHolder

var aim_zoom := _current_aim_zoom


func _ready():
	set_as_toplevel(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_camera.set_as_toplevel(true)


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
		OS.window_fullscreen = !OS.window_fullscreen
	
	_current_aim_zoom = lerp(_current_aim_zoom, aim_zoom, aim_speed)
	
	spring_length = lerp(min_zoom - _current_aim_zoom, max_zoom - _current_aim_zoom,
			clamp(inverse_lerp(50, -50, rotation_degrees.x), 0, 1))
	
	# the camera offset is always proportional to the rotation
	_player.camera_offset.y = lerp(min_offset - _current_aim_zoom,
			max_offset - _current_aim_zoom,
			clamp(inverse_lerp(70.0, -30.0, rotation_degrees.x), 0, 1))
	
	var aim_offset = Vector3(_current_aim_zoom, 0, 0).rotated(Vector3.UP, rotation.y)
	_camera.global_translation = lerp(_camera.global_translation + aim_offset,
			_camera_holder.global_translation + aim_offset, camera_acceleration)
	
	_camera.rotation = rotation
