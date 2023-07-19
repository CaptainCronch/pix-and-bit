extends SpringArm3D

var mouse_sensitivity := 0.15
var analog_sensitivity := 0.75
var zoom_sensitivity := 1
var camera_acceleration := 1
var aim_speed := 0.1

var max_aim_zoom := 1.0
var min_zoom := 4
var max_zoom := 5
var max_offset := 3
var min_offset := 1

var aim_delta := Vector2()

var _current_aim_zoom := 0.0

@onready var _player : CharacterBody3D = $".."
@onready var _camera : Node3D = $CameraHolder/CameraPlaceholder
@onready var _camera_holder : Node3D = $CameraHolder

var aim_zoom := _current_aim_zoom


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if event is InputEventMouseMotion: #and not _player.holding_frisbee
		rotation_degrees.x -= event.relative.y * mouse_sensitivity
		rotation_degrees.y -= event.relative.x * mouse_sensitivity


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
	aim_delta.y = -_player.analog_rotation.x * analog_sensitivity
	aim_delta.x = _player.analog_rotation.y * analog_sensitivity
	rotation_degrees.y -= _player.analog_rotation.x * analog_sensitivity
	rotation_degrees.x += _player.analog_rotation.y * analog_sensitivity
	
	rotation_degrees.x = clamp(rotation_degrees.x, -89.0, 89.0)
	rotation_degrees.y = wrapf(rotation_degrees.y, 0.0, 360.0)
