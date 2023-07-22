extends CharacterBody3D
class_name Player

var player_id : int

var move_speed := 10.0
var jump_force := 20.0

var base_gravity := 70.0
var fall_gravity := 80.0
var hold_gravity := 70.0
var hold_range := 10.0
var max_fall_speed := -75.0

var base_acceleration := 0.1
var base_friction := 0.3
var air_acceleration := 0.1
var air_friction := 0.1
var turn_acceleration := 0.1
var aim_acceleration := 0.2

var buffer_time := 0.1
var coyote_time := 0.2
var base_snap := 0.2

var mouse_sensitivity := 0.15
var analog_sensitivity := 0.75
var camera_offset := Vector3.ZERO # used in spring_arm.gd
var aim_limit_max := Vector3(0, 0, -20)
var aim_limit_min := Vector3(0, 0, -4)
var analog_look := Vector2()
var ignore_distance := 10
var max_clip := 2
var reload_time := 1


enum Swing {
	NONE,
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

enum ID {
	PLAYER_1,
	PLAYER_2,
}

var pix_controls := {
	"move_right": "pix_right",
	"move_left": "pix_left",
	"move_forward": "pix_forward",
	"move_back": "pix_back",
	"look_right": "pix_look_right",
	"look_left": "pix_look_left",
	"look_up": "pix_look_up",
	"look_down": "pix_look_down",
	"jump": "pix_jump",
	"primary": "pix_primary",
	"secondary": "pix_secondary",
}

var bit_controls := {
	"move_right": "bit_right",
	"move_left": "bit_left",
	"move_forward": "bit_forward",
	"move_back": "bit_back",
	"look_right": "bit_look_right",
	"look_left": "bit_look_left",
	"look_up": "bit_look_up",
	"look_down": "bit_look_down",
	"jump": "bit_jump",
	"primary": "bit_primary",
	"secondary": "bit_secondary",
}

var _velocity := Vector3.ZERO
var _current_snap := base_snap
var _move_dir := Vector3.ZERO
var _grounded := false
var _gravity := base_gravity
var _acceleration := base_acceleration
var _friction := base_friction
var _controls : Dictionary

var _aim_limit_direction := Vector3.ZERO
var aiming := false
var swinging := false
var _shoot_direction := Vector3.ZERO
var _swing_movement := Vector2.ZERO
var clip_left := max_clip

var _swing_angle := 0
var _swing_dir := Swing.NONE

@onready var camera_placeholder : Node3D = $SpringArm3D/CameraHolder/CameraPlaceholder # used by Global

@onready var _spring_arm : SpringArm3D = $SpringArm3D
@onready var _buffer_timer : Timer = $JumpBuffer
@onready var _coyote_timer : Timer = $CoyoteTime

@onready var _head : Node3D = $ModelHolder/Model/Body/Head
@onready var _hand : Node3D = $ModelHolder/Model/Body/Hand
@onready var _shoot_ray : RayCast3D = $SpringArm3D/CameraHolder/CameraPlaceholder/RayCast3D
@onready var _end : Marker3D = $SpringArm3D/CameraHolder/CameraPlaceholder/RayCast3D/End
@onready var _start : Marker3D = $SpringArm3D/CameraHolder/CameraPlaceholder/RayCast3D/Start
@onready var _reload_timer : Timer = $Reload

@onready var _model_holder : Node3D = $ModelHolder
@onready var _swing_anim : AnimationPlayer
@onready var _crosshair_anim : AnimationPlayer
@onready var _right_arrow : Sprite2D
@onready var _left_arrow : Sprite2D
@onready var _down_arrow : Sprite2D
@onready var _up_arrow : Sprite2D


func _ready():
	_shoot_ray.target_position = aim_limit_max
	_end.position = aim_limit_max
	_start.position = aim_limit_min
	call_deferred("init")


func init():
	var ui = Global.pix_camera.get_node("UI")
	_swing_anim = ui.get_node("SwingAnim")
	_crosshair_anim = ui.get_node("CrosshairAnim")
	_right_arrow = ui.get_node("Right")
	_left_arrow = ui.get_node("Left")
	_down_arrow = ui.get_node("Down")
	_up_arrow = ui.get_node("Up")


func _process(delta):
	_spring_arm.position = position + camera_offset
	_head.rotation = _spring_arm.rotation
	
	_aim_limit_direction = _head.global_position.direction_to(
			_end.global_position)
	
	get_input()


func _physics_process(delta):
	jumping(delta)
	apply_movement()
	model_controls(delta)


func get_input():
	analog_look = Vector2(
			Input.get_axis(_controls.look_left, _controls.look_right),
			Input.get_axis(_controls.look_down, _controls.look_up))
	
	if aiming:
		_swing_movement.x += analog_look.x * analog_sensitivity
		_swing_movement.y -= analog_look.y * analog_sensitivity
		_swing_angle = wrapf(rad_to_deg(_swing_movement.angle()), 0, 360)
	
	_move_dir = Vector3.ZERO
	
	_move_dir.x = Input.get_axis(_controls.move_left, _controls.move_right)
	_move_dir.z = Input.get_axis(_controls.move_forward, _controls.move_back)
	_move_dir = _move_dir.rotated(Vector3.UP, _spring_arm.rotation.y).normalized()
	
	if Input.is_action_just_pressed(_controls.secondary):
		aiming = true
		_spring_arm.aim_zoom = _spring_arm.max_aim_zoom
	elif Input.is_action_just_released(_controls.secondary):
		aiming = false
		_spring_arm.aim_zoom = 0
	
	if Input.is_action_just_pressed(_controls.primary) and aiming:
		aim_dir()
		swinging = true
	elif Input.is_action_just_released(_controls.primary) and aiming:
		swinging = false
	if Input.is_action_pressed(_controls.primary) and aiming:
		swing_dir()


func aim_dir():
	if clip_left <= 0: return
	
	_swing_movement = Vector2.ZERO
	
	_shoot_direction = _aim_limit_direction # if too far pretend only max away
	
	if not _shoot_ray.is_colliding(): return
	
	if _head.global_position.distance_to(_shoot_ray.get_collision_point()) >= aim_limit_min.z:
		_shoot_direction = _head.global_position.direction_to(
				_shoot_ray.get_collision_point()) # aim towards where crosshair hits surface
	else:
		_shoot_direction = _head.global_position.direction_to(
				_start.global_position) # if too close pretend only min away


func swing_dir():
	if (_swing_movement.length() >= ignore_distance): # ignore short swings
		if _swing_angle >= 60 and _swing_angle <= 120: # issue with 0
			_swing_dir = Swing.DOWN
		elif _swing_angle >= 240 and _swing_angle <= 300: # top 45 degrees
			_swing_dir = Swing.UP
		elif _swing_angle > 120 and _swing_angle < 240: # left 120 degrees
			_swing_dir = Swing.LEFT
		else: # should be 60 > angle > 300, right 120 degrees
			_swing_dir = Swing.RIGHT


func jumping(delta):
	if _velocity.y >= hold_range: _gravity = base_gravity
	elif _velocity.y <= -hold_range: _gravity = fall_gravity
	else: _gravity = hold_gravity # dfferent gravities applied based on y velocity
	
	_velocity.y -= _gravity * delta # gravity
	_velocity.y = max(_velocity.y, max_fall_speed) # max fall speed
	
	_grounded = is_on_floor()
	
	if _grounded:
		_coyote_timer.start(coyote_time) # starts letting you jump
	
	var touched_ground = _grounded and _current_snap == 0.0 # resets to ground mode
	
	if Input.is_action_just_pressed(_controls.jump):
		_buffer_timer.start(buffer_time) # waits until you touch the ground to jump
	
	if not _coyote_timer.is_stopped() and not _buffer_timer.is_stopped():
		_velocity.y = jump_force
		_current_snap = 0.0
		_buffer_timer.stop()
		_coyote_timer.stop()
	
	if touched_ground:
		_current_snap = base_snap
	
	if not Input.is_action_pressed(_controls.jump) and _velocity.y > jump_force * 0.5:
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
		_velocity.x = lerp(_velocity.x, 0.0, _friction)
	
	if _move_dir.z != 0:
		_velocity.z = lerp(_velocity.z, _move_dir.z * move_speed, _acceleration)
	else:
		_velocity.z = lerp(_velocity.z, 0.0, _friction)
	
	set_velocity(_velocity)
	# TODOConverter40 looks that snap in Godot 4.0 is float, not vector like in Godot 3 - previous value `e`
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	move_and_slide()
	_velocity = velocity


func model_controls(delta):
	if _move_dir != Vector3.ZERO:
		_model_holder.rotation.y = lerp_angle(_model_holder.rotation.y, atan2(_move_dir.x, _move_dir.z) + PI, turn_acceleration)
	
	if aiming:
		_model_holder.rotation.y = lerp_angle(_model_holder.rotation.y, _spring_arm.rotation.y, aim_acceleration)


func _input(event):
	if player_id != ID.PLAYER_1: return
	if event is InputEventMouseMotion and aiming:
		_swing_movement += Vector2(event.relative.x, event.relative.y) * mouse_sensitivity
		_swing_angle = wrapf(rad_to_deg(_swing_movement.angle()), 0, 360)


func _on_reload_timeout():
	clip_left += 1
	_crosshair_anim.play("spin")
	if clip_left < max_clip:
		_reload_timer.start(reload_time)
