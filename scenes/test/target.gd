extends CSGCombiner


func _on_area_entered(area):
	$CSGTorus/Particles.emitting = true
	$AudioStreamPlayer3D.play()
