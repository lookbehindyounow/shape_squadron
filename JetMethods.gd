static func get_HUD_angles(transform,target_pos):
	# talk abuot how this is done
	var tracking_plane=Plane(transform.origin,transform.origin+transform.basis.z,target_pos)
	var clock_face=tracking_plane.normal.signed_angle_to(transform.basis.x,-transform.basis.z)
	
	var forward_angle=acos((target_pos-transform.origin).normalized().dot(transform.basis.z))
	
	return [clock_face,forward_angle,target_pos]

static func find_intercept(transform,target_pos,target_velocity):
	# bullet speed is 50
	var targToPlayer_dot_targV=(transform.origin-target_pos).normalized().dot(target_velocity.normalized())
	var sin_target_travel_angle=target_velocity.length()*sqrt(1-(targToPlayer_dot_targV**2))/100
	var bullet_intercept_angle=PI-asin(sin_target_travel_angle)-acos(targToPlayer_dot_targV)
	var target_travel=sin_target_travel_angle*(transform.origin-target_pos).length()/sin(bullet_intercept_angle)
	var bullet_intercept_pos=target_pos+target_travel*target_velocity.normalized()
	
	return bullet_intercept_pos

static func track(transform,target_pos,target_velocity,enemy=true):
	var HUD_angles=get_HUD_angles(transform,target_pos)
	var ahead_HUD_angles=null
	
	if enemy:
		var bullet_intercept_pos=find_intercept(transform,target_pos,target_velocity)
		ahead_HUD_angles=get_HUD_angles(transform,bullet_intercept_pos)
	
	return [HUD_angles,ahead_HUD_angles]

static func cap_absolute_at_1(param):
	if abs(param)>1:
		if param>0:
			param=1
		else:
			param=-1
	return param

static func instruct_turn_new(transform,target_pos):
	var target_direction=(target_pos-transform.origin).normalized()
	var pitching=-target_direction.dot(transform.basis.y) # pitching up is negative
	# abs(pitching) approaches a continuous (smooth if you graphed it) maximum of 1 as target approaches an above/below position & bounces off 0 when target passes a beside/infront/behind position
	var rolling=1-abs(pitching) # so rolling amount does the same with 0 & 1 switched
	
	if (pitching<0)==(target_direction.dot(transform.basis.x)>0): # if pitching up & target left or pitching down & target right; target top-lef/bottom-right; roll left
		rolling*=-1 # rolling left is negative
	
	return [rolling,pitching]

# HERE HERE HERE HERE do what the first two comments say next
static func autopilot(transform,speed,pitch_speed,HUD_points): # change HUD points to just locations & ahead locations
	var multiplier=3
	var avoid_instructions=[0,0,0]
	
	# give different turn instructions with yaw, levelling & positive acceleration for target infront
	var instructions=instruct_turn_new(transform,HUD_points[0][1][2])+[0] # aim for player's ([0]) ahead/bullet_intercept ([1]) position ([2]) & add acceleration=0 (+[0])
	
	if transform.origin.y<5+speed/pitch_speed: # if near ground
		var down_dot_myForward=Vector3.DOWN.dot(transform.basis.z)
		if down_dot_myForward>0 && transform.origin.y<5+(speed/pitch_speed)*(1-sqrt(1-down_dot_myForward**2)): # if too near ground for current orientation
			avoid_instructions[0]=transform.basis.x.dot(Vector3.UP) # roll positive when leftside up, roll negative when leftside down
			avoid_instructions[1]=down_dot_myForward # pitch amount
			avoid_instructions[2]=-down_dot_myForward # decelerate
			if transform.basis.y.dot(Vector3.UP)>0: # upright
				avoid_instructions[0]*=-1 # pitch up
				avoid_instructions[1]*=-1
				# roll negative (left) when leftside up & upright
				# roll positive (right) when leftside down & upright
			# roll positive (right) when leftside up & upsidedown
			# roll negative (left) when leftside down & upsidedown
	
	var avoid_points_instructions=[] # for each HUD point
	var mindex=null
	var avoid_points=false
	for i in range(HUD_points.size()):
		var to_point=(HUD_points[i][0][2]-transform.origin)
		if to_point.length()<4: # if any are too close
			avoid_points=true # there are points to avoid
			avoid_points_instructions.append(instruct_turn_new(transform,HUD_points[i][0][2])+[to_point])
			avoid_points_instructions[i][1]*=-1 # flip pitch to avoid point instead of face point
			if mindex!=null:
				if avoid_points_instructions[i][2].length() < avoid_points_instructions[mindex][2].length():
					mindex=i # find index of minimum distance point's instructions
			else:
				mindex=i # if no mindex, this is minimum distance point
		else:
			avoid_points_instructions.append(null) # keeping indices the same between HUD_points & avoid_points_instructions
	
	if avoid_points: # if any points to avoid
		avoid_instructions[0]+=avoid_points_instructions[mindex][0]
		avoid_instructions[1]+=avoid_points_instructions[mindex][1]
		avoid_instructions[2]-=avoid_points_instructions[mindex][2].normalized().dot(transform.basis.z) # take away from acceleration
	
	if avoid_instructions!=[0,0,0]: # if any avoid instructions
		instructions=avoid_instructions # override instrucions
	
	instructions=instructions.map(func(instruction): return cap_absolute_at_1(instruction*multiplier))
	
	return instructions

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
