extends MeshInstance3D
var life=8
var total_life=life

func _ready():
	mesh.material=StandardMaterial3D.new()
	mesh.material.set_transparency(1)
	mesh.material.flags_unshaded=true
	mesh.material.albedo_color.a=0

func _physics_process(delta):
	if life>total_life-0.5:
		mesh.material.albedo_color.a=((total_life-life)/0.5)**2
	else:
		mesh.material.albedo_color.a=(life/(total_life-0.5))**2
	scale+=Vector3(1,1,1)/50
	if life<0:
		queue_free()
	life-=delta
