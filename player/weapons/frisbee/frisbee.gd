extends RigidBody

export var base_speed := 15
export var tomahawk_speed := 20
export var roll_speed := 30
export var angled_speed := 20
export var damage := 1
export var disable_speed := 3
export var spin_speed := 20
export var curve_speed := 10
export var return_speed := 0.15
export var return_time := 1
export var roll_deceleration = 0.1

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
var active := false
var can_disable := false

var _turning := true
var _horizontal_speed := 0.0

onready var _model : CSGCylinder = $Model
onready var _damage_area : Area = $Damage


func _ready():
	match current_throw:
		throw.STRAIGHT:
			rotation_degrees.z = 0
			gravity_scale = 0.3
		throw.TOMAHAWK:
			rotation_degrees.z = 90
			gravity_scale = 4
			physics_material_override.bounce = 1.0
			physics_material_override.friction = 0.5
		throw.ROLL:
			rotation_degrees.z = -90
			gravity_scale = 1.5
			physics_material_override.bounce = 0.0
		throw.RIGHT:
			rotation_degrees.z = -45
		throw.LEFT:
			rotation_degrees.z = 45
		_:
			pass
	
	# disable buffer
	yield(get_tree().create_timer(0.2), "timeout")
	can_disable = true


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
			if active and _turning: add_central_force(Vector3(curve_speed, 0, 0).rotated(Vector3.UP, rotation.y))
		throw.LEFT:
			if active and _turning: add_central_force(Vector3(-curve_speed, 0, 0).rotated(Vector3.UP, rotation.y))
		_:
			pass
	
	if _horizontal_speed <= disable_speed:
		disable()


func disable():
	if not active or not can_disable: return
	
	$SelfDestruct.start()
	active = false
	$Collider.disabled = true
	$InactiveCollider.disabled = false
	_damage_area.monitorable = false
	_damage_area.monitoring = false
	axis_lock_angular_x = false
	axis_lock_angular_z = false
	axis_lock_angular_y = false
	gravity_scale = 1.5
	physics_material_override.bounce = 0.3
	physics_material_override.friction = 0.5


func _on_body_entered(body):
	if not body.get_collision_layer_bit(0) or body.get_collision_layer_bit(5): return
	if current_throw == throw.TOMAHAWK: disable()
	elif current_throw == throw.RIGHT or current_throw == throw.LEFT:
		if _horizontal_speed <= (disable_speed) and active:
			disable() 


func _on_damage_area_entered(area):
	pass


func _on_self_destruct_timeout():
	queue_free()


func _on_turn_timeout():
	_turning = false
