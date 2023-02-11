extends RigidBody

enum throw {
	STRAIGHT,
	TOMAHAWK,
	ROLL,
	RIGHT,
	LEFT,
}

export var speed := 15
export var damage := 1
export var disable_speed := 3
export var spin_speed := 0.1

var _active := true
var _current_throw : int = throw.STRAIGHT

onready var _model : CSGCylinder = $Model


func _ready():
	pass


func _physics_process(delta):
	var horizontal_speed = Vector2(linear_velocity.x, linear_velocity.z).length()
	
	_model.rotate(Vector3.UP, spin_speed * inverse_lerp(0, speed, horizontal_speed))
	
	if  horizontal_speed <= disable_speed:
		$Collider.disabled = true
		$InactiveCollider.disabled = false
		$Damage.monitorable = false
		$Damage.monitoring = false
		axis_lock_angular_x = false
		axis_lock_angular_z = false
		axis_lock_angular_y = false


func _on_body_entered(body):
	if Vector2(linear_velocity.x, linear_velocity.z).length() <= disable_speed:
		$SelfDestruct.start($SelfDestruct.time_left / 2)


func _on_self_destruct_timeout():
	queue_free()
