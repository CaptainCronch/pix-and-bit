extends Player

@onready var _right_ring : CSGCylinder3D = $ModelHolder/RightRing
@onready var _left_ring : CSGCylinder3D = $ModelHolder/LeftRing

var frisbee := preload("res://player/weapons/frisbee/frisbee.tscn")


func _ready():
	super()
	player_id = ID.PLAYER_1
	Global.pix = self
	_controls = pix_controls


func _process(delta):
	super(delta)


func get_input():
	super()
	if Input.is_action_just_released(_controls.primary) and aiming:
		shoot_frisbee()


func shoot_frisbee():
	if clip_left > 0:
		clip_left -= 1
		_reload_timer.start(reload_time)
		var new_frisbee := frisbee.instantiate()
		
		_right_arrow.visible = false
		_left_arrow.visible = false
		_up_arrow.visible = false
		_down_arrow.visible = false
		
		match _swing_dir:
			Swing.DOWN:
				new_frisbee.current_throw = new_frisbee.throw.TOMAHAWK
				_down_arrow.visible = true
			Swing.UP:
				new_frisbee.current_throw = new_frisbee.throw.ROLL
				_up_arrow.visible = true
			Swing.LEFT:
				new_frisbee.current_throw = new_frisbee.throw.LEFT
				_left_arrow.visible = true
			Swing.RIGHT:
				new_frisbee.current_throw = new_frisbee.throw.RIGHT
				_right_arrow.visible = true
			Swing.NONE:
				new_frisbee.current_throw = new_frisbee.throw.STRAIGHT
		
		get_tree().get_root().get_child(
				get_tree().get_root().get_child_count() - 1
				).add_child(new_frisbee) # always add child to the last child of the root node (to skip autoloads)
		
		new_frisbee.player = self
		new_frisbee.global_position = _hand.global_position
		new_frisbee.rotation.y = _head.rotation.y
		
		#new_frisbee.linear_velocity = Vector3(_velocity.x / 3, 0, _velocity.z / 3) # 1/3 of player's velocity is inherited
		new_frisbee.apply_central_impulse(_shoot_direction * new_frisbee.speed * 2)
		new_frisbee.active = true
		
		_swing_dir = Swing.NONE
		
		_swing_anim.play("RESET")
		_swing_anim.play("out")
