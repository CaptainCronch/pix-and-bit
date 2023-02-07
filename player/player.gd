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
export var air_acceleration := 0.05
export var air_friction := 0.1
export var turn_acceleration := 0.1

export var buffer_time := 0.1
export var coyote_time := 0.2
export var snap_distance := Vector3(0, 0.2, 0)

export var base_health := 5

var _velocity := Vector3.ZERO
var _snap_vector := snap_distance
var _move_dir := Vector3.ZERO
var _grounded := false
var _gravity := base_gravity
var _acceleration := base_acceleration
var _friction := base_friction
var _health := base_health

onready var _spring_arm : SpringArm = $CameraHolder
onready var _model : CSGCylinder = $Model
onready var _buffer_timer : Timer = $JumpBuffer
onready var _coyote_timer : Timer = $CoyoteTime


func _ready():
	pass


func _process(delta):
	_spring_arm.translation = translation + Vector3(0, 1.25, 0)
	
	if Input.is_action_just_pressed("menu"):
		get_tree().quit()


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


func jumping(delta):
	
	if _velocity.y >= hold_range: _gravity = base_gravity
	elif _velocity.y <= -hold_range: _gravity = fall_gravity
	else: _gravity = hold_gravity
	
	_velocity.y -= _gravity * delta
	_velocity.y = max(_velocity.y, max_fall_speed)
	
	_grounded = is_on_floor()
	
	if _grounded:
		_coyote_timer.start(coyote_time)
	
	var touched_ground = _grounded and _snap_vector == Vector3.ZERO
	
	if Input.is_action_just_pressed("jump"):
		_buffer_timer.start(buffer_time)
	
	if not _coyote_timer.is_stopped() and not _buffer_timer.is_stopped():
		_velocity.y = jump_force
		_snap_vector = Vector3.ZERO
		_buffer_timer.stop()
		_coyote_timer.stop()
	
	if touched_ground:
		_snap_vector = snap_distance
	
	if not Input.is_action_pressed("jump") and _velocity.y > jump_force * 0.5:
		_velocity.y = jump_force * 0.5


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
