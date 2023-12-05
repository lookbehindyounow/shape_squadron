static func get_HUD_angles(transform,target_pos):
	var HUD_angles={"distance":(target_pos-transform.origin).length()}
	# talk abuot how this is done
	var tracking_plane=Plane(transform.origin,transform.origin+transform.basis.z,target_pos)
	HUD_angles.clock_face=tracking_plane.normal.signed_angle_to(transform.basis.x,-transform.basis.z)
	
	var target_direction=(target_pos-transform.origin).normalized()
	HUD_angles.forward_angle=acos(target_direction.dot(transform.basis.z))
	
	return HUD_angles

static func find_intercept(position,target_pos,target_velocity,projectile_speed,target_distance):
	var target_z=target_velocity.normalized()
	var sin_target_angle=target_pos.direction_to(position).dot(target_z)
	var sin_tracker_angle=target_velocity.length()*sqrt(1-(sin_target_angle**2))/projectile_speed
	var sin_intercept_angle=sin(PI-asin(sin_tracker_angle)-acos(sin_target_angle))
	var target_travel=target_distance*sin_tracker_angle/sin_intercept_angle
	var intercept_pos=target_pos+target_travel*target_z
	
	return intercept_pos

static func track(transform,target_pos,target_velocity,is_enemy=true):
	var tracking_points={"pos":get_HUD_angles(transform,target_pos)}
	
	if is_enemy:
		var bullet_intercept_pos=find_intercept(transform.origin,target_pos,target_velocity,100,tracking_points.pos.distance)
		tracking_points.intercept=get_HUD_angles(transform,bullet_intercept_pos)
	
	return tracking_points

static func instruct_look_at(target):
	var instructions={"rolling":target.clock_face,"pitching":0}
	
	if sin(target.forward_angle)*sin(abs(target.clock_face))<0.5: # target not to side
		instructions.pitching=-target.forward_angle
	
	if abs(target.clock_face)>PI/2: # target below
		instructions.pitching*=-1
		instructions.rolling-=PI*sign(instructions.rolling)
	
	return instructions

static func instruct_aim(transform,target):
	var instructions={}
	
	if target.distance>30:
		instructions.accelerating=1
	
	if target.forward_angle<0.3: # target centrally infront
		instructions.rolling=1-Vector3.UP.dot(transform.basis.y) # level self
		if Vector3.UP.dot(transform.basis.x)>0: # if leftside up
			instructions.rolling*=-1 # roll negative (left) to level
		
		instructions.pitching=-3*target.forward_angle*cos(target.clock_face)
		instructions.yawing=-3*target.forward_angle*sin(target.clock_face)
	else:
		var look_instructions=instruct_look_at(target)
		instructions.rolling=look_instructions.rolling
		instructions.pitching=look_instructions.pitching
	
	return instructions

static func instruct_avoid(target):
	var instructions={
		"rolling":sin(target.forward_angle)*sin(target.clock_face),
		"pitching":min(0,target.forward_angle-2)
	}
	if abs(target.clock_face)>PI/2: # target below
		instructions.rolling*=-1
		instructions.pitching*=-1
	
	return instructions

static func instruct_missiles(transform,missiles,state):
	var min_dist=0
	var mindex=0
	for i in missiles.size():
		var dist=transform.origin.distance_to(missiles[i].position)
		if dist<min_dist:
			min_dist=dist
			mindex=i
	
	if min_dist>10:
		state.missile_memory=instruct_look_at(get_HUD_angles(transform,missiles[mindex].position)).pitching
	else:
		if randf()<1.0/120:
			state.missile_memory*=-1
		state.instructions.rolling=sign(999.5-Time.get_ticks_msec()%2000)
		state.instructions.pitching=state.missile_memory
	return state

static func cap_absolute_at_1(param):
	if abs(param)>1:
		if param>0:
			param=1
		else:
			param=-1
	return param

static func avoid_multiple(HUD_points):
	var avoid_vector=Vector2.ZERO
	for point in HUD_points:
		if point.pos.distance<5: # if any are too close
			avoid_vector-=point.pos.forward_angle*Vector2.UP.rotated(point.pos.clock_face)/point.pos.distance
	if avoid_vector!=Vector2.ZERO:
		var total=abs(avoid_vector.x)+abs(avoid_vector.y)
		var instructions={"pitching":avoid_vector.y/total,"rolling":sign(-avoid_vector.y)*avoid_vector.x/total}
		return instructions
	else:
		return {}

static func autopilot(transform,speed,pitch_speed,HUD_points,state,missiles_following):
	state.instructions={}
	
	if transform.origin.y<1.5*speed/pitch_speed: # if near ground
		var down_dot_z=Vector3.DOWN.dot(transform.basis.z)
		if down_dot_z>0 && transform.origin.y<1+1.5*(speed/pitch_speed)*(1-sqrt(1-down_dot_z**2)): # if too near ground for current orientation
			state.instructions.rolling=transform.basis.x.dot(Vector3.UP) # roll positive when leftside up, roll negative when leftside down
			if transform.basis.y.dot(Vector3.UP)>0: # upright
				state.instructions.rolling*=-1
				state.instructions.pitching=-1 # pitch up when upright
				state.ground_memory=-1
			else:
				state.instructions.pitching=1 # pitch down when upsidedown
				state.ground_memory=1
				# roll negative (left) when leftside up & upright
				# roll positive (right) when leftside down & upright
			# roll positive (right) when leftside up & upsidedown
			# roll negative (left) when leftside down & upsidedown
		elif state.ground_memory:
			state.instructions[1]=state.ground_memory # if near ground but not at a critical angle, continue turning away to avoid jittery movement
	else:
		state.ground_memory=0 # reset when away from ground
	
	if state.instructions=={}: # if there are no avoid ground instructions
		state.instructions=avoid_multiple(HUD_points)
	if state.instructions=={} && missiles_following:
		state=instruct_missiles(transform,missiles_following,state)
	if state.thinking && state.instructions=={}:
		if state.chasing:
			state.instructions=instruct_aim(transform,HUD_points[0].intercept)
		else:
			state.instructions=instruct_avoid(HUD_points[0].pos)
	
	return state

static func turn(basis,roll,pitch,yaw,delta):
	basis=basis.rotated(basis.z,roll*delta)
	basis=basis.rotated(basis.x,pitch*delta)
	basis=basis.rotated(basis.y,yaw*delta)
	return basis
