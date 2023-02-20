extends KinematicBody

export var move_speed := 10.0
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
export var aim_acceleration := 0.2

export var buffer_time := 0.1
export var coyote_time := 0.2
export var snap_distance := Vector3(0, 0.2, 0)

export var base_health := 5

export var camera_offset := Vector3.ZERO
export var camera_frisbee_max := Vector3(0, 0, -20)
export var camera_frisbee_min := Vector3(0, 0, -4)
export var frisbee_hold_time := 0.3
export var ignore_distance := 100
export var max_frisbees := 2
export var reload_time := 1


enum {
	NONE,
	UP,
	DOWN,
	LEFT,
	RIGHT,
}


var _velocity := Vector3.ZERO
var _snap_vector := snap_distance
var _move_dir := Vector3.ZERO
var _grounded := false
var _gravity := base_gravity
var _acceleration := base_acceleration
var _friction := base_friction

var _health := base_health

var _frisbee_limit_direction := Vector3.ZERO
var aiming := false
var _shoot_direction := Vector3.ZERO
var _angle_movement := Vector2.ZERO
var frisbees_left := max_frisbees

var _shoot_angle := 0
var _aim_dir_general := NONE


onready var _spring_arm : SpringArm = $SpringArm
onready var _camera : Camera = $SpringArm/CameraHolder/Camera
onready var _buffer_timer : Timer = $JumpBuffer
onready var _coyote_timer : Timer = $CoyoteTime

onready var _head : Spatial = $ModelHolder/Model/Body/Head
onready var _left_wrist : Spatial = $ModelHolder/Model/Body/LeftWrist
onready var _right_wrist : Spatial = $ModelHolder/Model/Body/RightWrist
onready var _hand : Spatial = $ModelHolder/Model/Body/Hand
onready var _frisbee_ray : RayCast = $SpringArm/CameraHolder/Camera/RayCast
onready var _end : Position3D = $SpringArm/CameraHolder/Camera/RayCast/End
onready var _start : Position3D = $SpringArm/CameraHolder/Camera/RayCast/Start
onready var _reload_timer : Timer = $Reload

onready var _right_ring : CSGCylinder = $ModelHolder/RightRing
onready var _left_ring : CSGCylinder = $ModelHolder/LeftRing
onready var _model_holder : Spatial = $ModelHolder
onready var _frisbee_anim : AnimationPlayer = $SpringArm/CameraHolder/Camera/CenterContainer/Crosshair/FrisbeeAnim
onready var _crosshair_anim : AnimationPlayer = $SpringArm/CameraHolder/Camera/CenterContainer/Crosshair/CrosshairAnim
onready var _right_arrow : TextureRect = $SpringArm/CameraHolder/Camera/CenterContainer/Crosshair/Right
onready var _left_arrow : TextureRect = $SpringArm/CameraHolder/Camera/CenterContainer/Crosshair/Left
onready var _down_arrow : TextureRect = $SpringArm/CameraHolder/Camera/CenterContainer/Crosshair/Down
onready var _up_arrow : TextureRect = $SpringArm/CameraHolder/Camera/CenterContainer/Crosshair/Up


var frisbee := preload("res://player/weapons/frisbee/frisbee.tscn")


func _ready():
	_frisbee_ray.cast_to = camera_frisbee_max
	_end.translation = camera_frisbee_max
	_start.translation = camera_frisbee_min


func _process(delta):
	_spring_arm.translation = translation + camera_offset
	_head.rotation = _spring_arm.rotation
	
	_frisbee_limit_direction = _head.global_translation.direction_to(
			_end.global_translation)
	
	get_input()


func _physics_process(delta):
	jumping(delta)
	apply_movement()
	model_controls(delta)


func get_input():
	_move_dir = Vector3.ZERO
	
	_move_dir.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	_move_dir.z = Input.get_action_strength("back") - Input.get_action_strength("forward")
	_move_dir = _move_dir.rotated(Vector3.UP, _spring_arm.rotation.y).normalized()
	
	if Input.is_action_just_pressed("action_secondary"):
		aiming = true
		_spring_arm.aim_zoom = _spring_arm.max_aim_zoom
	elif Input.is_action_just_released("action_secondary"):
		aiming = false
		_spring_arm.aim_zoom = 0
	
	if Input.is_action_just_pressed("action") and aiming:
		hold_frisbee()
	elif Input.is_action_just_released("action") and aiming:
		shoot_frisbee()
	if Input.is_action_pressed("action") and aiming:
		shoot_direction()
	
	if Input.is_action_just_pressed("menu"):
		get_tree().quit() # temporary for testing


func hold_frisbee():
	
	if frisbees_left <= 0:return
	
	_right_arrow.visible = false
	_left_arrow.visible = false
	_up_arrow.visible = false
	_down_arrow.visible = false
	_frisbee_anim.play("RESET")
	
	_angle_movement = Vector2.ZERO
	
	_shoot_direction = _frisbee_limit_direction # if too far pretend only max away
	
	if not _frisbee_ray.is_colliding(): return
	
	if _head.global_translation.distance_to(_frisbee_ray.get_collision_point()) >= camera_frisbee_min.z:
		_shoot_direction = _head.global_translation.direction_to(
				_frisbee_ray.get_collision_point()) # aim towards where crosshair hits surface
	else:
		_shoot_direction = _head.global_translation.direction_to(
				_start.global_translation) # if too close pretend only min away


func shoot_direction():
	
	if (_angle_movement.length() >= ignore_distance): # ignore short swings
		if _shoot_angle >= 60 and _shoot_angle <= 120: # issue with 0
			_aim_dir_general = DOWN
		elif _shoot_angle >= 240 and _shoot_angle <= 300: # top 45 degrees
			_aim_dir_general = UP
		elif _shoot_angle > 120 and _shoot_angle < 240: # left 120 degrees
			_aim_dir_general = LEFT
		else: # should be 60 > angle > 300, right 120 degrees
			_aim_dir_general = RIGHT


func shoot_frisbee():
	if frisbees_left > 0:
		frisbees_left -= 1
		_reload_timer.start(reload_time)
		var new_frisbee := frisbee.instance()
		
		match _aim_dir_general:
			DOWN:
				new_frisbee.current_throw = new_frisbee.throw.ROLL
				new_frisbee.speed = new_frisbee.roll_speed
			UP:
				new_frisbee.current_throw = new_frisbee.throw.TOMAHAWK
				new_frisbee.speed = new_frisbee.tomahawk_speed
			LEFT:
				new_frisbee.current_throw = new_frisbee.throw.LEFT
				new_frisbee.speed = new_frisbee.angled_speed
			RIGHT:
				new_frisbee.current_throw = new_frisbee.throw.RIGHT
				new_frisbee.speed = new_frisbee.angled_speed
			NONE:
				new_frisbee.current_throw = new_frisbee.throw.STRAIGHT
				new_frisbee.speed = new_frisbee.base_speed
		
		get_tree().get_root().get_child(
				get_tree().get_root().get_child_count() - 1
				).add_child(new_frisbee) # always add child to the last child of the root node (to skip autoloads)
		
		new_frisbee.player = self
		new_frisbee.global_translation = _hand.global_translation
		new_frisbee.rotation.y = _head.rotation.y
		
		#new_frisbee.linear_velocity = Vector3(_velocity.x / 3, 0, _velocity.z / 3) # 1/3 of player's velocity is inherited
		new_frisbee.apply_central_impulse(_shoot_direction * new_frisbee.speed)
		new_frisbee.active = true
		
		_aim_dir_general = NONE


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
		_model_holder.rotation.y = lerp_angle(_model_holder.rotation.y, atan2(_move_dir.x, _move_dir.z) + PI, turn_acceleration)
	
	if aiming:
		_model_holder.rotation.y = lerp_angle(_model_holder.rotation.y, _spring_arm.rotation.y, aim_acceleration)


func ui_controls():
	pass


func _input(event):
	if event is InputEventMouseMotion and aiming:
		_angle_movement += Vector2(event.relative.x, -event.relative.y)
		_shoot_angle = wrapf(rad2deg(_angle_movement.angle()), 0, 360)


func _on_damage_area_entered(area):
	pass


func _on_reload_timeout():
	frisbees_left += 1
	_crosshair_anim.play("spin")
	if frisbees_left < max_frisbees:
		_reload_timer.start(reload_time)
