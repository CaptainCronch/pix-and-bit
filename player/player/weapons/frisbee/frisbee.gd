extends RigidBody

export var base_speed := 15
export var tomahawk_speed := 20
export var roll_speed := 35
export var angled_speed := 15
export var damage := 1
export var disable_speed := 5
export var spin_speed := 0.1
export var curve_speed := 10
export var return_speed := 0.3

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

var _active := true

onready var _model : CSGCylinder = $Model
onready var _damage_area : Area = $Damage


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
	var horizontal_speed := Vector3(linear_velocity.x, linear_velocity.y / 2, linear_velocity.z).length()
	var forward_speed_ratio := inverse_lerp(0, speed, linear_velocity.x)
	
	_model.rotate(Vector3.UP, spin_speed * inverse_lerp(0, speed, horizontal_speed))
	
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
			if _active: add_central_force(Vector3(curve_speed, 0, 0).rotated(Vector3.UP, rotation.y))
		throw.LEFT:
			if _active: add_central_force(Vector3(-curve_speed, 0, 0).rotated(Vector3.UP, rotation.y))
		_:
			pass
	
	if  horizontal_speed <= disable_speed and _active:
		disable()
	
	if returning:
		global_translation = lerp(global_translation, player.global_translation + Vector3.UP, return_speed)
		rotation += Vector3(1, 1, 1) * spin_speed


func back():
	_damage_area.set_collision_mask_bit(1, true)
	$InactiveCollider.disabled = true
	_damage_area.monitorable = true
	_damage_area.monitoring = true
	gravity_scale = 0
	returning = true


func disable():
	_active = false
	$Collider.disabled = true
	$InactiveCollider.disabled = false
	_damage_area.monitorable = false
	_damage_area.monitoring = false
	axis_lock_angular_x = false
	axis_lock_angular_z = false
	axis_lock_angular_y = false


func _on_body_entered(body):
	if current_throw == throw.TOMAHAWK and body.get_collision_layer_bit(0): disable()
#	if Vector2(linear_velocity.x, linear_velocity.z).length() <= disable_speed:
#		$SelfDestruct.start($SelfDestruct.time_left / 2)


func _on_return_timeout():
	pass


func _on_damage_area_entered(area):
	pass
