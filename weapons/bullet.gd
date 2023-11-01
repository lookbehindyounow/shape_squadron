extends RigidBody3D
var life=10
signal hit

func _ready():
	contact_monitor=true
	max_contacts_reported=1
	continuous_cd=1

func _process(delta):
	life-=delta
	if life<0:
		queue_free()
	
	if get_colliding_bodies():
		if get_colliding_bodies()[0].is_in_group("jets"):
			hit.connect(get_colliding_bodies()[0]._on_bullet_hit)
			hit.emit()
		queue_free()
