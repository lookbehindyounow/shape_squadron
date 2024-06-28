extends StaticBody3D

func _ready():
	$MultiMeshInstance3d.multimesh.instance_count=100
	for x in range(10):
		for z in range(10):
			var pos=Transform3D().translated(Vector3(5*x,2.5,18+5*z))
			$MultiMeshInstance3d.multimesh.set_instance_transform(10*x+z,pos)
			
			var collision_shape=CollisionShape3D.new()
			var shape=BoxShape3D.new()
			shape.size=(Vector3(1,5,1))
			collision_shape.set_shape(shape)
			collision_shape.set_transform(pos)
			add_child(collision_shape)
