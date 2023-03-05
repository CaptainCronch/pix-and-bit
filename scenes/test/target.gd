extends CSGCombiner3D


func _on_area_entered(area):
	$CSGTorus3D/Particles.emitting = true
	$AudioStreamPlayer3D.play()
