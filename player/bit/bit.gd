extends Player


var grenade := preload("res://player/weapons/grenade/grenade.tscn")


func _ready():
	super()
	player_id = ID.PLAYER_1
	Global.bit = self
	_controls = pix_controls
	reload_time = 1
	_reload_timer.wait_time = reload_time
	max_clip = 6
	clip_left = max_clip
	call_deferred("init")


func init():
	var ui = Global.p2_camera.get_node("UI")
	_swing_anim = ui.get_node("SwingAnim")
	_crosshair_anim = ui.get_node("CrosshairAnim")
	_right_arrow = ui.get_node("Right")
	_left_arrow = ui.get_node("Left")
	_down_arrow = ui.get_node("Down")
	_up_arrow = ui.get_node("Up")


func get_input():
	super()
	if Input.is_action_just_released(_controls.primary) and aiming:
		shoot_grenade()


func shoot_grenade():
	if clip_left > 0:
		clip_left -= 1
		_reload_timer.start(reload_time)
		var new_grenade := grenade.instantiate()
		
		_right_arrow.visible = false
		_left_arrow.visible = false
		_up_arrow.visible = false
		_down_arrow.visible = false
		
		match _swing_dir:
			Swing.DOWN:
				new_grenade.current_throw = new_grenade.throw.TOMAHAWK
				_down_arrow.visible = true
			Swing.UP:
				new_grenade.current_throw = new_grenade.throw.ROLL
				_up_arrow.visible = true
			Swing.LEFT:
				new_grenade.current_throw = new_grenade.throw.LEFT
				_left_arrow.visible = true
			Swing.RIGHT:
				new_grenade.current_throw = new_grenade.throw.RIGHT
				_right_arrow.visible = true
			Swing.NONE:
				new_grenade.current_throw = new_grenade.throw.STRAIGHT
		
		get_tree().get_root().get_child(
				get_tree().get_root().get_child_count() - 1
				).add_child(new_grenade) # always add child to the last child of the root node (to skip autoloads)
		
		new_grenade.global_position = _hand.global_position
		new_grenade.rotation.y = _head.rotation.y
		
		#new_grenade.linear_velocity = Vector3(_velocity.x / 3, 0, _velocity.z / 3) # 1/3 of player's velocity is inherited
		new_grenade.apply_central_impulse(_shoot_direction * new_grenade.speed * 2)
		new_grenade.active = true
		
		_swing_dir = Swing.NONE
		
		_swing_anim.play("RESET")
		_swing_anim.play("out")
