extends RigidBody3D
var life

func _ready():
	contact_monitor=true
	max_contacts_reported=1

func set_up(_transform):
	transform=_transform
	position+=2*basis.z
	linear_velocity=basis.z*100
	life=10

func _physics_process(delta):
	if get_colliding_bodies() || life<0:
		if get_colliding_bodies() && get_colliding_bodies()[0].is_in_group("jets"):
			get_colliding_bodies()[0]._on_bullet_hit()
		get_node("/root/Main").bullet_pool.append(self)
		get_node("/root/Main").remove_child(self)
	life-=delta
