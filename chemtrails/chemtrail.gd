extends MeshInstance3D
var life
var total_life
var alive=false

var chillin=false # for testing
func _unhandled_input(event):
	if InputMap.event_is_action(event,"toggle_chillin") && event.pressed:
		chillin=not chillin

func _ready():
	mesh.material=StandardMaterial3D.new()
	mesh.material.set_transparency(1)
	mesh.material.flags_unshaded=true
	mesh.material.albedo_color.a=0

func set_up(_transform,_life):
	life=_life
	total_life=_life
	scale=Vector3.ONE
	transform=_transform
	basis=basis.rotated(basis.x,PI/2)
	alive=true

func _physics_process(delta):
	if alive and not chillin:
		if life>total_life-0.5:
			mesh.material.albedo_color.a=((total_life-life)/0.5)**2
		else:
			mesh.material.albedo_color.a=(life/(total_life-0.5))**2
		scale+=1.1*Vector3(1,1,1)*delta
		if life<0:
			mesh.material.albedo_color.a=0
			alive=false
			get_node("/root/Main").chemtrail_pool.append(self)
		life-=delta
