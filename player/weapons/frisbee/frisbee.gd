extends RigidBody

export var base_speed := 15
export var tomahawk_speed := 20
export var roll_speed := 35
export var angled_speed := 15
export var damage := 1
export var disable_speed := 5
export var spin_speed := 20
export var curve_speed := 10
export var return_speed := 0.1
export var return_time := 1

enum throw {
	STRAIGHT,
	TOMAHAWK,
	ROLL,
	RIGHT,
	LEFT,
}

var current_throw : int = throw.STRAIGHT
var speed := base_speed
var player : KinematicBody
var returning := false
var active := true

var _horizontal_speed := 0.0

onready var _model : CSGCylinder = $Model
onready var _damage_area : Area = $Damage
onready var _return_timer : Timer = $Return


func _ready():
	match current_throw:
		throw.STRAIGHT:
			rotation_degrees.z = 0
		throw.TOMAHAWK:
			rotation_degrees.z = 90
			gravity_scale = 3
		throw.ROLL:
			rotation_degrees.z = -90
			gravity_scale = 2
			linear_damp *= 1.5
		throw.RIGHT:
			rotation_degrees.z = -45
		throw.LEFT:
			rotation_degrees.z = 45
		_:
			pass


func _physics_process(delta):
	_horizontal_speed = Vector3(linear_velocity.x, linear_velocity.y, linear_velocity.z).length()
	
	_model.rotate(Vector3.UP, spin_speed * inverse_lerp(0, speed, _horizontal_speed) * delta)
	
	# ratio of forward velocity to side velocity is directly proportional to ratio of current velocity to 0
	# remove a portion of forward velocity and add it to the side velocity
	match current_throw:
		throw.STRAIGHT:
			pass
		throw.TOMAHAWK:
			pass
		throw.ROLL:
			pass
		throw.RIGHT:
			if active: add_central_force(Vector3(curve_speed, 0, 0).rotated(Vector3.UP, rotation.y))
		throw.LEFT:
			if active: add_central_force(Vector3(-curve_speed, 0, 0).rotated(Vector3.UP, rotation.y))
		_:
			pass
	
	if _horizontal_speed <= disable_speed and active:
		disable()
	
	if returning:
		#add_central_force(global_translation.direction_to(player.global_translation + Vector3.UP) * return_speed)
		global_translation = lerp(global_translation, player.global_translation + Vector3.UP, return_speed)
		rotation += Vector3(1, 1, 1) * spin_speed * delta


func back():
	player.frisbees_returning.append(self)
	active = true
	_damage_area.set_collision_mask_bit(1, true)
	$InactiveCollider.disabled = true
	_damage_area.monitorable = true
	_damage_area.monitoring = true
	gravity_scale = 0
	returning = true


func disable():
	if returning or not active: return
	
	_return_timer.start(return_time)
	active = false
	$Collider.disabled = true
	$InactiveCollider.disabled = false
	_damage_area.monitorable = false
	_damage_area.monitoring = false
	axis_lock_angular_x = false
	axis_lock_angular_z = false
	axis_lock_angular_y = false


func _on_body_entered(body):
	if not body.get_collision_layer_bit(0): return
	if current_throw == throw.TOMAHAWK: disable()
	elif current_throw == throw.RIGHT or current_throw == throw.LEFT:
		if _horizontal_speed <= (disable_speed) and active:
			disable() 
#	if Vector2(linear_velocity.x, linear_velocity.z).length() <= disable_speed:
#		$SelfDestruct.start($SelfDestruct.time_left / 2)


func _on_return_timeout():
	back()


func _on_damage_area_entered(area):
	pass
