extends MultiMeshInstance3D

@export var obstacle_collision_shape:PackedScene

func _ready():
	for x in range(10):
		for z in range(10):
			self.multimesh.set_instance_transform(z*10+x,Transform3D(Basis(),Vector3(5*x,2.5,5*z)))
			var obst_col_sh=obstacle_collision_shape.instantiate()
			obst_col_sh.position=Vector3(5*x,2.5,5*z)
			get_parent().add_child(obst_col_sh)
