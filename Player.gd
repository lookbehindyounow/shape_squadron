extends CharacterBody3D
const acceleration=2
const top_speed=10
var speed=0
var bullet_scene=preload("res://bullet.tscn")
var hits_taken=0
var crashes=0
signal hit

func _physics_process(delta):
	if Input.is_action_pressed("accelerate"):
		speed+=acceleration*delta
		if speed>top_speed:
			speed=top_speed
	if Input.is_action_pressed("decelerate"):
		speed-=acceleration*delta
		if speed<-top_speed:
			speed=-top_speed
	if Input.is_action_pressed("roll_left"):
		transform.basis=transform.basis.rotated(transform.basis.z,-delta)
	if Input.is_action_pressed("roll_right"):
		transform.basis=transform.basis.rotated(transform.basis.z,delta)
	if Input.is_action_pressed("pitch_up"):
		transform.basis=transform.basis.rotated(transform.basis.x,-delta)
	if Input.is_action_pressed("pitch_down"):
		transform.basis=transform.basis.rotated(transform.basis.x,delta)
	velocity=transform.basis.z*speed
	move_and_slide()
	
	if Input.is_action_pressed("shoot") && Time.get_ticks_msec()%100:
		shoot()
	
	for i in range(get_slide_collision_count()):
		if get_slide_collision(i).get_collider().is_in_group("bullets"):
			hits_taken+=1
		else:
			crashes+=1
		hit.emit()

func shoot():
	var bullet=bullet_scene.instantiate()
	bullet.global_transform=self.global_transform
	bullet.position+=self.transform.basis.z
	bullet.linear_velocity=transform.basis.z*25
	get_node("/root/Main").add_child(bullet)
