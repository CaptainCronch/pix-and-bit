extends RigidBody3D

var base_speed := 15
var tomahawk_speed := 20
var roll_speed := 30
var angled_speed := 20
var damage := 1
var disable_speed := 3
var spin_speed := 20
var curve_speed := 10
var return_speed := 0.15
var return_time := 1
var roll_deceleration = 0.1

enum throw {
	STRAIGHT,
	TOMAHAWK,
	ROLL,
	RIGHT,
	LEFT,
}

var current_throw : int = throw.STRAIGHT
var speed := base_speed
var returning := false
var active := false
var can_disable := false

var _horizontal_speed := 0.0

@onready var _model : CSGSphere3D = $Model
@onready var _damage_area : Area3D = $Damage
@onready var _self_destruct : Timer = $SelfDestruct
@onready var _explode_timer : Timer = $Explode


func _ready():
	match current_throw:
		throw.STRAIGHT:
			rotation_degrees.z = 0
			gravity_scale = 1
		throw.TOMAHAWK:
			speed = tomahawk_speed
			rotation_degrees.z = 90
			gravity_scale = 4
			physics_material_override.bounce = 1.0
			physics_material_override.friction = 0.5
		throw.ROLL:
			speed = roll_speed
			rotation_degrees.z = -90
			gravity_scale = 1.5
			physics_material_override.bounce = 0.0
		throw.RIGHT:
			speed = angled_speed
			rotation_degrees.z = -45
		throw.LEFT:
			speed = angled_speed
			rotation_degrees.z = 45
	
	# disable buffer
	await get_tree().create_timer(0.2).timeout
	can_disable = true


func _physics_process(delta):
	_horizontal_speed = Vector3(linear_velocity.x, linear_velocity.y, linear_velocity.z).length()
	
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
			pass
		throw.LEFT:
			pass
		_:
			pass


func _on_body_entered(body):
	_explode_timer.start()


func _on_damage_area_entered(area):
	pass


func _on_self_destruct_timeout():
	queue_free()


func _on_explode_timeout():
	_self_destruct.start()
	set_collision_layer(0)
	set_collision_mask(0)
	freeze = true
