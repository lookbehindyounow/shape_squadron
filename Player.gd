extends CharacterBody3D
var Jet=preload("res://JetMethods.gd")
var health=50
const acceleration=2
const top_speed=15
const roll_speed=1
const pitch_speed=1
const yaw_speed=0.2
var speed=0
var hits_taken=0
var crashes=0
var cooldown=0
var missiles=10
var missile_cooldowns=[0,0]
var missiles_following=[]
var HUD_points=[]
var roll_momentum=0
var pitch_momentum=0
var yaw_momentum=0

var ave_enemy_pos=Vector3.ZERO

#var suggestions_on=false
#func _unhandled_input(event):
#	if InputMap.event_is_action(event,"toggle_suggestions") && event.pressed:
#		suggestions_on=not suggestions_on

func _physics_process(delta):
	var gaming=get_node("/root/Main").gaming
	var enemies=get_node("/root/Main").enemies
	HUD_points=[]
	for enemy in enemies:
		HUD_points.append(Jet.track(transform,enemy.position,enemy.velocity,gaming))
	if not gaming:
		HUD_points=HUD_points.map(func(HUD_point): return [HUD_point[0],false,HUD_point[0][2]])
	
#	if suggestions_on:
#		var suggestions=Jet.autopilot(transform,HUD_points)
	
	if gaming:
		var rolling=0
		var pitching=0
		var yawing=0
		var accelerating=0
		
		if Input.is_action_pressed("accelerate"):
			accelerating+=1
		if Input.is_action_pressed("decelerate"):
			accelerating-=1
		
		if Input.is_action_pressed("pitch_up"):
			pitching-=1
		if Input.is_action_pressed("pitch_down"):
			pitching+=1
			
		if Input.is_action_pressed("slow_turn"):
			pitching*=0.2
			if Input.is_action_pressed("roll_left"):
				yawing+=1
			if Input.is_action_pressed("roll_right"):
				yawing-=1
		else:
			if Input.is_action_pressed("roll_left"):
				rolling-=1
			if Input.is_action_pressed("roll_right"):
				rolling+=1
		
		if Input.is_action_pressed("shoot"):
			if cooldown<0:
				Jet.shoot(self)
				cooldown=0.05
			else:
				cooldown-=delta
		
		if Input.is_action_just_pressed("missile"):
			for i in range(missile_cooldowns.size()):
				if missiles && missile_cooldowns[i]<0:
					var locked=null
					var mindex=null
					for j in range(HUD_points.size()):
						if HUD_points[j][0][1]<0.3 && (HUD_points[j][0][2]-position).length()<50:
							if mindex==null || HUD_points[j][1][1]<HUD_points[mindex][1][1]:
								mindex=j
					if mindex:
						locked=enemies[mindex]
					Jet.shoot(self,true,locked,true if Input.is_action_pressed("slow_turn") else false)
					missiles-=1
					missile_cooldowns[i]=1.5
					break
		for i in range(missile_cooldowns.size()):
			missile_cooldowns[i]-=delta
		
		roll_momentum=(10.0*roll_momentum+rolling)/11
		pitch_momentum=(10.0*pitch_momentum+pitching)/11
		yaw_momentum=(10.0*yaw_momentum+yawing)/11
		
		speed=min(speed+(accelerating*acceleration*delta),top_speed)
		transform.basis=Jet.turn(transform.basis,roll_momentum*roll_speed,pitch_momentum*pitch_speed,yaw_momentum*yaw_speed,delta)
		velocity=transform.basis.z*speed
		move_and_slide()
		
		for i in range(get_slide_collision_count()):
			if not get_slide_collision(i).get_collider().is_in_group("weapons"):
				die()
	else:
		var sum=Vector3.ZERO
		for HUD_point in HUD_points:
			sum+=HUD_point[2]
		ave_enemy_pos=sum/HUD_points.size()
		transform.origin=ave_enemy_pos
		transform.basis=transform.basis.rotated(Vector3.UP,0.02*TAU*delta)
		transform.origin-=30*transform.basis.z
		# when explosions are working could zoom out from exploding jet & glide towards this view

func _on_bullet_hit():
	health-=1
	if health<=0:
		die()

func _on_missile_hit():
	health-=5
	if health<=0:
		die()

func die():
	for missile in missiles_following:
		missile.target=null
	missiles_following=[]
	health=0
	get_node("/root/Main").gaming=false
	get_node("/root/Main/UI/Endgame").text="We got em boys - away home to bed :)"
	get_node("/root/Main/UI/Endgame").show()
	$CollisionShape3D.set_deferred("disabled",true)
	$PlaceholderBody.hide()
	transform.basis=Basis(Vector3.RIGHT,Vector3(0,sqrt(3)/2,0.5),Vector3(0,-0.5,sqrt(3)/2))
