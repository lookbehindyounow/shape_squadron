extends CharacterBody3D
var Jet=preload("res://JetMethods.gd")
const acceleration=2
const top_speed=10
var speed=0
var hits_taken=0
var crashes=0
signal hit
var cooldown=0
var target_o_clock=0

var suggestions_on=true
func _unhandled_input(event):
	if InputMap.event_is_action(event,"toggle_suggestions") && event.pressed:
		suggestions_on=not suggestions_on

func _physics_process(delta):
	if suggestions_on:
		var suggestions=Jet.autopilot(transform,get_node("/root/Main/Enemy").position)
		target_o_clock=suggestions[0]
	else:
		target_o_clock=Jet.track(transform,get_node("/root/Main/Enemy").position)
		
	if Input.is_action_pressed("accelerate"):
		speed=min(speed+acceleration*delta,top_speed)
	if Input.is_action_pressed("decelerate"):
		speed=min(speed-acceleration*delta,top_speed)
	var rolling=0
	var pitching=0
	if Input.is_action_pressed("roll_left"):
		rolling-=1
	if Input.is_action_pressed("roll_right"):
		rolling+=1
	if Input.is_action_pressed("pitch_up"):
		pitching-=1
	if Input.is_action_pressed("pitch_down"):
		pitching+=1
	transform.basis=Jet.turn(transform.basis,rolling,pitching,delta)
	velocity=transform.basis.z*speed
	move_and_slide()
	
	if Input.is_action_pressed("shoot"):
		if cooldown>0.05:
			Jet.shoot(self)
			cooldown=0
		else:
			cooldown+=delta
	
	var collisions=[]
	for i in range(get_slide_collision_count()):
		if Jet.collide(get_slide_collision(i).get_collider()):
			hits_taken+=1
		else:
			crashes+=1
		hit.emit()
