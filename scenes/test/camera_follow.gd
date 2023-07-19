extends Camera3D

@export var player = 0
var _target : Node3D

func _ready():
	if player == 0:
		_target = Global.pix.camera_placeholder
		Global.pix_camera = self
	else:
		_target = Global.bit.camera_placeholder
		Global.bit_camera = self


func _process(delta):
	global_position = _target.global_position
	global_rotation = _target.global_rotation
