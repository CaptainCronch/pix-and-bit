extends Player


func _ready():
	super()
	player_id = ID.PLAYER_2
	Global.bit = self
	_controls = bit_controls
