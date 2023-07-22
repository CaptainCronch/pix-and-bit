extends CharacterBody3D


func _process(delta):
	velocity = (Global.pix.global_position - global_position).normalized() * 9
	move_and_slide()
