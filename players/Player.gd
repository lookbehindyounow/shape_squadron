extends CharacterBody3D
var Jet=preload("res://players/JetMethods.gd")
var health=50
const acceleration=2
const top_speed=15
const roll_speed=1
const pitch_speed=1
const yaw_speed=0.2
var speed=top_speed
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
var chemtrail_counter=0

var ave_enemy_pos=Vector3.ZERO

func _physics_process(delta):
	var gaming=get_node("/root/Main").gaming
	var enemies=get_node("/root/Main").enemies
	HUD_points=[]
	for enemy in enemies:
		HUD_points.append(Jet.track(transform,enemy.position,enemy.velocity))
	
	if Input.is_action_just_pressed("restart"):
		get_node("/root/Main")._on_restart_pressed()
	
	if gaming:
		var rolling=0
		var pitching=0
		var yawing=0
		var accelerating=0
		
		accelerating+=Input.get_action_strength("accelerate")
		accelerating-=Input.get_action_strength("decelerate")
		
		pitching-=Input.get_action_strength("pitch_up")
		pitching+=Input.get_action_strength("pitch_down")
		rolling-=Input.get_action_strength("roll_left")
		rolling+=Input.get_action_strength("roll_right")
		
		pitching-=Input.get_action_strength("slight_pitch_up")*yaw_speed
		pitching+=Input.get_action_strength("slight_pitch_down")*yaw_speed
		yawing+=Input.get_action_strength("yaw_left")
		yawing-=Input.get_action_strength("yaw_right")
		
		if abs(pitching)+abs(rolling)>1:
			pitching=Jet.cap_absolute_at_1(pitching*2)
			rolling=Jet.cap_absolute_at_1(rolling*2)
		
		if Input.is_action_pressed("shoot"):
			if cooldown<0:
				get_node("/root/Main").bullet(transform)
				$AudioStreamPlayer3D.play()
				cooldown=0.05
			else:
				cooldown-=delta
		
		if Input.is_action_just_pressed("missile"):
			for i in range(missile_cooldowns.size()):
				if missiles && missile_cooldowns[i]<0:
					var locked=null
					var mindex=null
					for j in range(HUD_points.size()):
						if HUD_points[j].pos.forward_angle<0.3 && HUD_points[j].pos.distance<100:
							if mindex==null || HUD_points[j].intercept.forward_angle<HUD_points[mindex].intercept.forward_angle:
								mindex=j
					if mindex!=null:
						locked=enemies[mindex]
					get_node("/root/Main").missile(transform,locked,true)
					missiles-=1
					missile_cooldowns[i]=1.5
					break
		for i in range(missile_cooldowns.size()):
			missile_cooldowns[i]-=delta
		
		roll_momentum=(7.0*roll_momentum+rolling)/8
		pitch_momentum=(7.0*pitch_momentum+pitching)/8
		yaw_momentum=(7.0*yaw_momentum+yawing)/8
		
		speed=min(max(speed+(accelerating*acceleration*delta),5),top_speed)
#		speed=min(speed+(accelerating*acceleration*delta),top_speed)
		transform.basis=Jet.turn(transform.basis,roll_momentum*roll_speed,pitch_momentum*pitch_speed,yaw_momentum*yaw_speed,delta)
		velocity=transform.basis.z*speed
		move_and_slide()
		
		chemtrail_counter+=1
		if chemtrail_counter>7:
			chemtrail_counter=0
			get_node("/root/Main").chemtrail(transform)
		
		for i in range(get_slide_collision_count()):
			if not get_slide_collision(i).get_collider().is_in_group("weapons"):
				die()
	else:
		var sum=Vector3.ZERO
		for enemy in get_node("/root/Main").enemies:
			sum+=enemy.position
		ave_enemy_pos=sum/HUD_points.size()
		transform.origin=ave_enemy_pos
		transform.basis=transform.basis.rotated(Vector3.UP,0.02*TAU*delta)
		transform.origin-=30*transform.basis.z
		# could zoom out from exploding jet & glide towards this view

func _on_bullet_hit():
	health-=1
	$HitSound.play()
	if health<=0:
		die()
	else:
		get_node("/root/Main/UI").flash(0.1)

func _on_missile_hit():
	health-=5
	if health<=0:
		die()
	else:
		get_node("/root/Main/UI").flash(0.3)

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
	get_node("/root/Main").explosion(position,1)
	transform.basis=Basis(Vector3.RIGHT,Vector3(0,sqrt(3)/2,0.5),Vector3(0,-0.5,sqrt(3)/2))
