extends CharacterBody3D
var Jet=preload("res://JetMethods.gd")
var health=50
const acceleration=2
const top_speed=15
const roll_speed=1
const pitch_speed=1
var speed=0
var hits_taken=0
var crashes=0
var cooldown=0
var HUD_points=[[[0,0],[0,0],false]]
signal die

#var suggestions_on=false
#func _unhandled_input(event):
#	if InputMap.event_is_action(event,"toggle_suggestions") && event.pressed:
#		suggestions_on=not suggestions_on

func _physics_process(delta):
	var enemies=get_node("/root/Main").enemies
	HUD_points=[]
	for enemy in enemies:
		HUD_points.append(Jet.track(transform,enemy.position,enemy.velocity))
	
#	if suggestions_on:
#		var suggestions=Jet.autopilot(transform,HUD_points)
	
	var accelerating=0
	if Input.is_action_pressed("accelerate"):
		accelerating+=1
	if Input.is_action_pressed("decelerate"):
		accelerating-=1
	speed=min(speed+(accelerating*acceleration*delta),top_speed)
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
	
	for i in range(get_slide_collision_count()):
		if not get_slide_collision(i).get_collider().is_in_group("bullets"):
			die.emit()

func _on_bullet_hit():
	health-=1
	if health<=0:
		die.emit()
