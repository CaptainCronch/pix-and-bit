extends RigidBody

export var speed := 15
export var damage := 1
export var disable_speed := 3

var _active := true


func _ready():
	pass


func _physics_process(delta):
	if Vector2(linear_velocity.x, linear_velocity.z).length() <= disable_speed:
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
