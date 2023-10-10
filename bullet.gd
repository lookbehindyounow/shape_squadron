extends RigidBody3D

func _process(delta):
	if position.length()>1000:
		queue_free()
