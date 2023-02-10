extends KinematicBody

export var move_speed := 13.0
export var jump_force := 26.0

export var base_gravity := 70.0
export var fall_gravity := 80.0
export var hold_gravity := 70.0
export var hold_range := 10.0
export var max_fall_speed := -75.0

export var base_acceleration := 0.1
export var base_friction := 0.3
export var air_acceleration := 0.1
export var air_friction := 0.1
export var turn_acceleration := 0.1

export var buffer_time := 0.1
export var coyote_time := 0.2
export var snap_distance := Vector3(0, 0.2, 0)

export var base_health := 5

export var camera_offset := Vector3.ZERO
export var camera_frisbee_max := Vector3(0, 0, -20)
export var camera_frisbee_min := Vector3(0, 0, -2)


var _velocity := Vector3.ZERO
var _snap_vector := snap_distance
var _move_dir := Vector3.ZERO
var _grounded := false
var _gravity := base_gravity
var _acceleration := base_acceleration
var _friction := base_friction
var _health := base_health
var _frisbee_limit_direction := Vector3.ZERO

onready var _spring_arm : SpringArm = $CameraHolder
onready var _camera : Camera = $CameraHolder/Camera
onready var _model : CSGCylinder = $Model
onready var _buffer_timer : Timer = $JumpBuffer
onready var _coyote_timer : Timer = $CoyoteTime
onready var _head : Position3D = $Head
onready var _frisbee_ray : RayCast = $CameraHolder/Camera/RayCast
onready var _end : Position3D = $CameraHolder/Camera/RayCast/End
onready var _start : Position3D = $CameraHolder/Camera/RayCast/Start

var frisbee := preload("res://player/player/weapons/frisbee/frisbee.tscn")


func _ready():
	_frisbee_ray.cast_to = camera_frisbee_max
	_end.translation = camera_frisbee_max
	_start.translation = camera_frisbee_min


func _process(delta):
	_spring_arm.translation = translation + camera_offset
	
	_frisbee_limit_direction = _head.global_translation.direction_to(
			_end.global_translation)
	
	if Input.is_action_just_pressed("menu"):
		get_tree().quit() # temporary


func _physics_process(delta):
	get_input()
	jumping(delta)
	apply_movement()
	model_controls(delta)


func get_input():
	_move_dir = Vector3.ZERO
	
	_move_dir.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	_move_dir.z = Input.get_action_strength("back") - Input.get_action_strength("forward")
	_move_dir = _move_dir.rotated(Vector3.UP, _spring_arm.rotation.y).normalized()
	
	if Input.is_action_just_pressed("action"):
		shoot_frisbee()


func shoot_frisbee():
	var new_frisbee = frisbee.instance()
	
	get_tree().get_root().get_child(
			get_tree().get_root().get_child_count() - 1
			).add_child(new_frisbee) # always add child to the last child of the root node
	
	new_frisbee.global_translation = _head.global_translation
	
	var shoot_direction := _frisbee_limit_direction # if too far pretend only max away
	if _frisbee_ray.is_colliding():
		if _head.global_translation.distance_to(_frisbee_ray.get_collision_point()) >= (camera_frisbee_min.z):
			shoot_direction = _head.global_translation.direction_to(
					_frisbee_ray.get_collision_point()) # aim towards where crosshair hits surface
		else:
			shoot_direction = _head.global_translation.direction_to(
					_start.global_translation) # if too close pretend only min away
	
	new_frisbee.linear_velocity = Vector3(_velocity.x / 3, 0, _velocity.z / 3)
	new_frisbee.apply_central_impulse(shoot_direction * new_frisbee.speed)


func jumping(delta):
	if _velocity.y >= hold_range: _gravity = base_gravity
	elif _velocity.y <= -hold_range: _gravity = fall_gravity
	else: _gravity = hold_gravity # dfferent gravities applied based on y velocity
	
	_velocity.y -= _gravity * delta # gravity
	_velocity.y = max(_velocity.y, max_fall_speed) # max fall speed
	
	_grounded = is_on_floor()
	
	if _grounded:
		_coyote_timer.start(coyote_time) # starts letting you jump
	
	var touched_ground = _grounded and _snap_vector == Vector3.ZERO # resets to ground mode
	
	if Input.is_action_just_pressed("jump"):
		_buffer_timer.start(buffer_time) # waits until you touch the ground to jump
	
	if not _coyote_timer.is_stopped() and not _buffer_timer.is_stopped():
		_velocity.y = jump_force
		_snap_vector = Vector3.ZERO
		_buffer_timer.stop()
		_coyote_timer.stop()
	
	if touched_ground:
		_snap_vector = snap_distance
	
	if not Input.is_action_pressed("jump") and _velocity.y > jump_force * 0.5:
		_velocity.y = jump_force * 0.5 # jump cut when you let go of jump


func apply_movement():
	
	if _grounded:
		_acceleration = base_acceleration
		_friction = base_friction
	else:
		_acceleration = air_acceleration
		_friction = air_friction
	
	if _move_dir.x != 0:
		_velocity.x = lerp(_velocity.x, _move_dir.x * move_speed, _acceleration)
	else:
		_velocity.x = lerp(_velocity.x, 0, _friction)
	
	if _move_dir.z != 0:
		_velocity.z = lerp(_velocity.z, _move_dir.z * move_speed, _acceleration)
	else:
		_velocity.z = lerp(_velocity.z, 0, _friction)
	
	_velocity = move_and_slide_with_snap(_velocity, _snap_vector, Vector3.UP, true)


func model_controls(delta):
	if _move_dir != Vector3.ZERO:
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(_move_dir.x, _move_dir.z), turn_acceleration)


func _on_buffer_timeout():
	pass # Replace with function body.


func _on_coyote_timeout():
	pass # Replace with function body.
