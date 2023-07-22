extends SpringArm3D

var camera_acceleration := 1
var aim_speed := 0.1

var max_aim_zoom := 1.0
var min_zoom := 4
var max_zoom := 5
var max_offset := 3
var min_offset := 1

var _current_aim_zoom := 0.0

@onready var _player : Player = $".."
@onready var _camera : Node3D = $CameraHolder/CameraPlaceholder
@onready var _camera_holder : Node3D = $CameraHolder

var aim_zoom := _current_aim_zoom


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if _player.player_id != _player.ID.PLAYER_1: return
	if event is InputEventMouseMotion: #and not _player.holding_frisbee
		rotation_degrees.x -= event.relative.y * _player.mouse_sensitivity
		rotation_degrees.y -= event.relative.x * _player.mouse_sensitivity


func _process(delta):
	rotate_camera()
	
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


func rotate_camera():
	if _player.swinging: return
	rotation_degrees.y -= _player.analog_look.x * _player.analog_sensitivity
	rotation_degrees.x += _player.analog_look.y * _player.analog_sensitivity
	
	rotation_degrees.x = clamp(rotation_degrees.x, -89.0, 89.0)
	rotation_degrees.y = wrapf(rotation_degrees.y, 0.0, 360.0)
