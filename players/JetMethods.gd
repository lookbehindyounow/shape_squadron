static func get_HUD_angles(transform,target_pos):
	# talk abuot how this is done
	var tracking_plane=Plane(transform.origin,transform.origin+transform.basis.z,target_pos)
	var clock_face=tracking_plane.normal.signed_angle_to(transform.basis.x,-transform.basis.z)
	
	var target_direction=(target_pos-transform.origin).normalized()
	var forward_angle=acos(target_direction.dot(transform.basis.z))
	
	return [clock_face,forward_angle,target_pos]

static func track(transform,target_pos,target_velocity,enemy=true):
	var HUD_angles=get_HUD_angles(transform,target_pos)
	var ahead_HUD_angles=null
	
	if enemy:
		# bullet speed is 100
		var targToPlayer_dot_targV=(transform.origin-target_pos).normalized().dot(target_velocity.normalized())
		var sin_target_travel_angle=target_velocity.length()*sqrt(1-(targToPlayer_dot_targV**2))/100
		var bullet_intercept_angle=PI-asin(sin_target_travel_angle)-acos(targToPlayer_dot_targV)
		var target_travel=sin_target_travel_angle*(transform.origin-target_pos).length()/sin(bullet_intercept_angle)
		var bullet_intercept_pos=target_pos+target_travel*target_velocity.normalized()
		ahead_HUD_angles=get_HUD_angles(transform,bullet_intercept_pos)
	
	return [HUD_angles,ahead_HUD_angles]

static func instruct_aim(transform,target):
	var rolling=0
	var pitching=0
	var yawing=0
	var accelerating=0
	
	if (target[2]-transform.origin).length()>30:
		accelerating=1
	
	if target[1]<0.3: # target centrally infront
		rolling=1-Vector3.UP.dot(transform.basis.y) # level self
		if Vector3.UP.dot(transform.basis.x)>0: # if leftside up
			rolling*=-1 # roll negative (left) to level
		
		pitching=-3*target[1]*cos(target[0])
		yawing=-3*target[1]*sin(target[0])
		
		if (target[2]-transform.origin).length()<20:
			accelerating=-1
	else:
		rolling=target[0]
		if abs(rolling)>PI/2:
			if rolling>PI/2:
				rolling-=PI
			else:
				rolling+=PI
		
		pitching=sqrt(1-(target[2]-transform.origin).normalized().dot(transform.basis.z))
		if abs(target[0])<PI/2:
			pitching*=-1
	
	return [rolling,pitching,yawing,accelerating]

static func instruct_avoid(transform,target):
	var target_direction=(target[2]-transform.origin).normalized()
	var rolling=target_direction.dot(transform.basis.x)
	if abs(target[0])<PI/2:
		rolling*=-1
	
	var pitching=target_direction.dot(transform.basis.z)
	var accelerating=-pitching
	pitching**=2
	if abs(target[0])>PI/2:
		pitching*=-1
	
	return [rolling,pitching,0,accelerating]

static func cap_absolute_at_1(param):
	if abs(param)>1:
		if param>0:
			param=1
		else:
			param=-1
	return param

static func autopilot(transform,speed,pitch_speed,HUD_points,state,missiles_following):
	var multiplier=3
	var instructions=[0,0,0,0]
	var avoid_instructions=[0,0,0,0]
	
	if missiles_following:
		instructions[1]=cap_absolute_at_1(1000-Time.get_ticks_msec()%2000)
	elif state=="towards":
		instructions=instruct_aim(transform,HUD_points[0][1]) # aim for player's ([0]) ahead/bullet_intercept ([1])
	elif state=="away":
		instructions=instruct_avoid(transform,HUD_points[0][0])
	
	if transform.origin.y<5+speed/pitch_speed: # if near ground
		var down_dot_myForward=Vector3.DOWN.dot(transform.basis.z)
		if down_dot_myForward>0 && transform.origin.y<5+(speed/pitch_speed)*(1-sqrt(1-down_dot_myForward**2)): # if too near ground for current orientation
			avoid_instructions[0]=transform.basis.x.dot(Vector3.UP) # roll positive when leftside up, roll negative when leftside down
			avoid_instructions[1]=down_dot_myForward # pitch amount
			avoid_instructions[3]=-down_dot_myForward # decelerate
			if transform.basis.y.dot(Vector3.UP)>0: # upright
				avoid_instructions[0]*=-1 # pitch up
				avoid_instructions[1]*=-1
				# roll negative (left) when leftside up & upright
				# roll positive (right) when leftside down & upright
			# roll positive (right) when leftside up & upsidedown
			# roll negative (left) when leftside down & upsidedown
	
	var mindex=0
	var to_avoid_point=null
	for i in range(HUD_points.size()):
		var to_point=(HUD_points[i][0][2]-transform.origin)
		if to_point.length()<4: # if any are too close
			if to_avoid_point==null || (to_point.length()<to_avoid_point.length()):
				to_avoid_point=to_point
				mindex=i
	
	if to_avoid_point: # if there is a point to avoid
		var avoid_point_instructions=instruct_avoid(transform,HUD_points[mindex][0])
		avoid_instructions[0]+=avoid_point_instructions[0]
		avoid_instructions[1]+=avoid_point_instructions[1]
		avoid_instructions[3]+=avoid_point_instructions[3]
	
	if avoid_instructions!=[0,0,0,0]: # if any avoid instructions
		instructions=avoid_instructions # override instrucions
	
	instructions=instructions.map(func(instruction): return cap_absolute_at_1(instruction*multiplier))
	
	return instructions+[state]

static func turn(basis,roll,pitch,yaw,delta):
	basis=basis.rotated(basis.z,roll*delta)
	basis=basis.rotated(basis.x,pitch*delta)
	basis=basis.rotated(basis.y,yaw*delta)
	return basis

static func shoot(shooter,missile=false,locked=null,camera=false):
	var weapon
	if missile:
		weapon=shooter.get_node("/root/Main").missile_scene.instantiate()
		weapon.target=locked
	else:
		weapon=shooter.get_node("/root/Main").bullet_scene.instantiate()
		shooter.get_node("AudioStreamPlayer3D").play()
	weapon.transform=shooter.transform
	weapon.position+=1.5*shooter.transform.basis.z
	weapon.linear_velocity=weapon.transform.basis.z*100
	shooter.get_node("/root/Main").add_child(weapon)
	if camera:
		weapon.watching=true
