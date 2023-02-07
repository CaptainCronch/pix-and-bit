extends SpringArm

export var mouse_sensitivity = 0.1
export var zoom_sensitivity = 1
export var min_zoom = 2
export var max_zoom = 10



func _ready():
	set_as_toplevel(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if event is InputEventMouseMotion:
		rotation_degrees.x -= event.relative.y * mouse_sensitivity
		rotation_degrees.x = clamp(rotation_degrees.x, -89.0, 89.0)
		
		rotation_degrees.y -= event.relative.x * mouse_sensitivity
		rotation_degrees.y = wrapf(rotation_degrees.y, 0.0, 360.0)


func _process(delta):
	var zoom_dir = 0
	
	if Input.is_action_just_released("zoom_in"): zoom_dir += 1
	if Input.is_action_just_released("zoom_out"): zoom_dir -= 1
	
	spring_length = clamp(spring_length + (zoom_dir * zoom_sensitivity), min_zoom, max_zoom)
