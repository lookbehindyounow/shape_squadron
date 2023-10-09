extends CharacterBody3D
const acceleration=2
const top_speed=10
var speed=0

func _physics_process(delta):
	var direction=transform.basis.z
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
		transform.basis=transform.basis.rotated(transform.basis.x,delta)
	if Input.is_action_pressed("pitch_down"):
		transform.basis=transform.basis.rotated(transform.basis.x,-delta)
	velocity=transform.basis.z*speed
	move_and_slide()
