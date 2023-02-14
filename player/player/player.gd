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
export var camera_frisbee_min := Vector3(0, 0, -4)
export var frisbee_hold_time := 0.3
export var ignore_distance := 100
export var max_frisbees := 2
export var reload_time := 2


#var frisbees_returning := []
var frisbees_out := []


var _velocity := Vector3.ZERO
var _snap_vector := snap_distance
var _move_dir := Vector3.ZERO
var _grounded := false
var _gravity := base_gravity
var _acceleration := base_acceleration
var _friction := base_friction

var _health := base_health

var _frisbee_limit_direction := Vector3.ZERO
var _holding_frisbee := false
var _shoot_direction := Vector3.ZERO
var _angle_movement := Vector2.ZERO
var frisbees_left := max_frisbees


onready var _model : CSGCylinder = $Model
onready var _spring_arm : SpringArm = $SpringArm
onready var _camera : Camera = $SpringArm/CameraHolder/Camera
onready var _buffer_timer : Timer = $JumpBuffer
onready var _coyote_timer : Timer = $CoyoteTime

onready var _head : Spatial = $Head
onready var _frisbee_ray : RayCast = $SpringArm/CameraHolder/Camera/RayCast
onready var _end : Position3D = $SpringArm/CameraHolder/Camera/RayCast/End
onready var _start : Position3D = $SpringArm/CameraHolder/Camera/RayCast/Start
onready var _reload_timer : Timer = $Reload


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
	
	if Input.is_action_just_pressed("menu"):
		get_tree().quit() # temporary for testing



func _physics_process(delta):
	get_input()
	jumping(delta)
	apply_movement()
	check_collisions()
	model_controls(delta)


func get_input():
	_move_dir = Vector3.ZERO
	
	_move_dir.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	_move_dir.z = Input.get_action_strength("back") - Input.get_action_strength("forward")
	_move_dir = _move_dir.rotated(Vector3.UP, _spring_arm.rotation.y).normalized()
	
	if Input.is_action_just_pressed("action"):
		hold_frisbee()
	if Input.is_action_just_released("action"):
		shoot_frisbee()
	


func hold_frisbee():
	_holding_frisbee = true
	_angle_movement = Vector2.ZERO
	
	_shoot_direction = _frisbee_limit_direction # if too far pretend only max away
	
	if not _frisbee_ray.is_colliding(): return
	
	if _head.global_translation.distance_to(_frisbee_ray.get_collision_point()) >= camera_frisbee_min.z:
		_shoot_direction = _head.global_translation.direction_to(
				_frisbee_ray.get_collision_point()) # aim towards where crosshair hits surface
	else:
		_shoot_direction = _head.global_translation.direction_to(
				_start.global_translation) # if too close pretend only min away


func shoot_frisbee():
	_holding_frisbee = false
	
	if frisbees_left > 0:
		frisbees_left -= 1
		var new_frisbee := frisbee.instance()
		
		if (_angle_movement.length() >= ignore_distance): # ignore short swings
			var shoot_angle := wrapf(rad2deg(_angle_movement.angle()), 0, 360)
			
			if shoot_angle >= 60 and shoot_angle <= 120: # issue with 0
				new_frisbee.current_throw = new_frisbee.throw.ROLL
				new_frisbee.speed = new_frisbee.roll_speed
			elif shoot_angle >= 240 and shoot_angle <= 300: # top 45 degrees
				new_frisbee.current_throw = new_frisbee.throw.TOMAHAWK
				new_frisbee.speed = new_frisbee.tomahawk_speed
			elif shoot_angle > 120 and shoot_angle < 240: # left 120 degrees
				new_frisbee.current_throw = new_frisbee.throw.LEFT
				new_frisbee.speed = new_frisbee.angled_speed
			else: # should be 60 > angle > 300, right 120 degrees
				new_frisbee.current_throw = new_frisbee.throw.RIGHT
				new_frisbee.speed = new_frisbee.angled_speed
		
		get_tree().get_root().get_child(
				get_tree().get_root().get_child_count() - 1
				).add_child(new_frisbee) # always add child to the last child of the root node
		
		new_frisbee.player = self
		new_frisbee.global_translation = _head.global_translation
		new_frisbee.rotation.y = _head.rotation.y
		
		#new_frisbee.linear_velocity = Vector3(_velocity.x / 3, 0, _velocity.z / 3) # 1/3 of player's velocity is inherited
		new_frisbee.apply_central_impulse(_shoot_direction * new_frisbee.speed)


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


func check_collisions():
#	if frisbees_returning.size() <= 0: return
#	if _return_area.overlaps_area(frisbees_returning[0].get_node("Damage")):
#		frisbees_left += 1
#		var _frisbee_to_delete : RigidBody = frisbees_returning.pop_front()
#		frisbees_out.pop_front()
#		_frisbee_to_delete.queue_free()
	pass


func model_controls(delta):
	if _move_dir != Vector3.ZERO:
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(_move_dir.x, _move_dir.z), turn_acceleration)


func _input(event):
	if event is InputEventMouseMotion and _holding_frisbee:
		_angle_movement += Vector2(event.relative.x, -event.relative.y)


func _on_damage_area_entered(area):
	pass

var i := 0
func _on_frisbee_return_area_entered(area):
#	if frisbees_returning.size() <= 0:
#		return
#
#	var frisbee_index := frisbees_returning.find(area.get_parent())
#	if not frisbee_index == -1:
	if area.get_parent().returning:
#		frisbees_returning.pop_at(frisbee_index)
		frisbees_left += 1
		area.get_parent().queue_free()
	else:
		i += 1
		print("passed without collecting " + String(i))


func _on_frisbee_return_body_entered(body):
	if body.returning:
		frisbees_left += 1
		body.queue_free()
	else:
		i += 1
		print("passed without collecting " + String(i))


func _on_reload_timeout():
	frisbees_left += 1
