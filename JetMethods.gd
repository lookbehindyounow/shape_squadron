static func get_HUD_angles(transform,target_pos):
	# talk abuot how this is done
	var tracking_plane=Plane(transform.origin,transform.origin+transform.basis.z,target_pos)
	var clock_face=tracking_plane.normal.signed_angle_to(transform.basis.x,-transform.basis.z)
	
	var forward_angle=acos((target_pos-transform.origin).normalized().dot(transform.basis.z))
	
	return [clock_face,forward_angle]

static func track(transform,target_pos,target_velocity,enemy=true):
	var HUD_angles=get_HUD_angles(transform,target_pos)
	var ahead_HUD_angles=null
	
	if enemy:
		# bullet speed is 50
		var targToPlayer_dot_targV=(transform.origin-target_pos).normalized().dot(target_velocity.normalized())
		var sin_target_travel_angle=target_velocity.length()*sqrt(1-(targToPlayer_dot_targV**2))/100
		var bullet_intercept_angle=PI-asin(sin_target_travel_angle)-acos(targToPlayer_dot_targV)
		var target_travel=sin_target_travel_angle*(transform.origin-target_pos).length()/sin(bullet_intercept_angle)
		var bullet_intercept_pos=target_pos+target_travel*target_velocity.normalized()
	
		ahead_HUD_angles=get_HUD_angles(transform,bullet_intercept_pos)
	
	return [HUD_angles,ahead_HUD_angles,target_pos]

static func instruct_turn(clock_face):
	var rolling=0
	var pitching=0
	# could maybe reduce code here by using positive/negative dot products (against all transform basis axes) to figure out which way to go
	if abs(clock_face)>PI/20 && abs(clock_face)<0.95*PI: # if target not at top or bottom centre of clock face
		if abs(clock_face)<2*PI/3: # target in top 2/3 of clock face
			if clock_face>0:# top-right
				rolling+=1
			else: # top-left
				rolling-=1
		elif abs(clock_face)>=2*PI/3: # target in bottom 1/3 of clock face
			if clock_face>0: # bottom-right
				rolling-=1
			else: # bottom-left
				rolling+=1
	
	if abs(clock_face)<0.4*PI: # target in top 2/5 of clock face
		pitching-=1
	elif abs(clock_face)>0.8*PI: # target in botom 1/5 of clock face
		pitching+=1
	
	return [rolling,pitching]

static func autopilot(transform,speed,pitch_speed,HUD_points,target=0): # target is index of HUD point
	var accelerating=0
	
	var turn_instructions=instruct_turn(HUD_points[target][1][0]) # aim for player's ahead marker
	
	if transform.origin.y<5+speed/pitch_speed: # if near ground
		if transform.origin.y<5+(speed/pitch_speed)*(1-sin(Vector3.DOWN.angle_to(transform.basis.z))): # if too near ground for current orientation
			if transform.basis.y.dot(Vector3.DOWN)<0: # upright
				turn_instructions[1]=-1 # pitch up
				if transform.basis.x.dot(Vector3.DOWN)>0: # leftside down
					turn_instructions[0]=1 # roll right
				else: # rightside down
					turn_instructions[0]=-1 # roll left
			else: # upside down
				turn_instructions[1]=1 # pitch down
				if transform.basis.x.dot(Vector3.DOWN)>0: # leftside down
					turn_instructions[0]=-1 # roll left
				else: # rightside down
					turn_instructions[0]=1 # roll right
	
	for point in HUD_points:
		var to_point=point[2]-transform.origin
		if to_point.length()<3:
			var avoid_instructions=instruct_turn(point[0][0])
			turn_instructions[0]=-avoid_instructions[0]
			turn_instructions[1]=-avoid_instructions[1]
			
			if to_point.dot(transform.basis.z)>0:
				accelerating=-1
			else:
				accelerating+=1
	
	return [turn_instructions[0],turn_instructions[1],accelerating]

static func turn(basis,roll,pitch,delta):
	basis=basis.rotated(basis.z,roll*delta)
	basis=basis.rotated(basis.x,pitch*delta)
	return basis

static func shoot(shooter):
	var bullet=shooter.get_node("/root/Main").bullet_scene.instantiate()
	bullet.transform=shooter.transform
	bullet.position+=shooter.transform.basis.z	
	bullet.linear_velocity=bullet.transform.basis.z*100
	shooter.get_node("/root/Main").add_child(bullet)
