# --- TRACKING ---

# BIG OPTIMISATION POTENTIAL CAN YOU DO THIS WITH DOT PRODUCTS?
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

static func track(transform,target_pos,target_velocity=null):
	var tracking_points={"pos":get_HUD_angles(transform,target_pos)}
	
	if target_velocity!=null:
		var bullet_intercept_pos=find_intercept(transform.origin,target_pos,target_velocity,100,tracking_points.pos.distance)
		tracking_points.intercept=get_HUD_angles(transform,bullet_intercept_pos)
	
	return tracking_points

# --- AUTOPILOT ---

static func instruct_look_at(target):
	var instructions={"rolling":target.clock_face,"pitching":0}
	
	if sin(target.forward_angle)*sin(abs(target.clock_face))<0.5: # target not to side
		instructions.pitching=-target.forward_angle
#		print("no roll")
	
	if abs(target.clock_face)>PI/2: # target below
		instructions.pitching*=-1
		instructions.rolling-=PI*sign(instructions.rolling)
#		print("under")
	
	return instructions

static func instruct_aim(target):
	var instructions={}
	
	if target.distance>30:
		instructions.accelerating=1
	
	if target.forward_angle<0.3: # target centrally infront
		instructions.pitching=-3*target.forward_angle*cos(target.clock_face)
		instructions.yawing=-3*target.forward_angle*sin(target.clock_face)
		instructions.rolling=0 # To signal that levelling is needed
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

static func instruct_avoid_multiple(HUD_points):
	var avoid_vector=Vector2.ZERO
	for point in HUD_points:
		if point.pos.distance<5: # if any are too close
			avoid_vector-=point.pos.forward_angle*Vector2.UP.rotated(point.pos.clock_face)/point.pos.distance
	if avoid_vector!=Vector2.ZERO:
		var total=abs(avoid_vector.x)+abs(avoid_vector.y)
		var instructions={"pitching":avoid_vector.y/total,"rolling":sign(-avoid_vector.y)*avoid_vector.x/total}
		instructions.emergency_override=true
		return instructions
	else:
		return {}

static func instruct_evade_missiles(transform,state):
	var min_dist=0
	var mindex=0
	for i in state.missiles_following.size():
		var dist=transform.origin.distance_to(state.missiles_following[i].position)
		if dist<min_dist:
			min_dist=dist
			mindex=i
	
	if min_dist>10:
		state.missile_memory=-sign(transform.origin.direction_to(state.missiles_following[mindex].position).dot(transform.basis.y))
	else:
		if randf()<1.0/120:
			state.missile_memory*=-1
		state.instructions.rolling=sign(999.5-Time.get_ticks_msec()%2000)
		state.instructions.pitching=state.missile_memory
	return state

static func instruct_avoid_ground(transform,speed,pitch_speed,ground_memory,caller):
	# this is effectively a cheap shape cast using multiple ray casts by moving around one ray
	var pos=caller.transform.origin
	var ray=caller.state.ray
	var basis=caller.transform.basis
	var space=caller.get_world_3d().direct_space_state
	var lookahead=15
	var samples=8
	var lookout=1
	
	# these vectors, when added to a central point, make up the rectangle being cast
	ray.from=pos
	var obstacles=[]
	var common_obstacle=null
	for sample in samples:
		ray.to=pos+(lookahead*basis.z)+lookout*basis.y.rotated(basis.z,sample*2*PI/samples) # setting ray
		obstacles.append(space.intersect_ray(ray)) # casting ray
		if obstacles[-1]:
			if common_obstacle==null: # set common obstacle to the first obstacle hit
				common_obstacle=obstacles[-1].collider_id
			elif common_obstacle!=obstacles[-1].collider_id:
				common_obstacle=0 # if there is more than 1 obstacle
	
	caller.state.erase("avoid_vec")
	caller.state.avoid_vecs=[]
	var avoid_vector=Vector3.ZERO
	if false && common_obstacle:
		
		caller.state.avoid_vecs.append(Vector2.ZERO)
		
		for sample in samples:
			if obstacles[sample]:
				
				caller.state.avoid_vecs.append(0.3*Vector2.UP.rotated(sample*2*PI/samples))
				
				avoid_vector-=basis.y.rotated(basis.z,sample*2*PI/samples)
				avoid_vector+=obstacles[sample].normal*basis/samples
	elif common_obstacle!=null || common_obstacle==0: # avoid multiple obstacles # avoid single/general obstacle
		for obstacle in obstacles:
			if obstacle:
				var avoid_point=pos-obstacle.position # vector in opposite direction from obstacle
				
				var test=avoid_point*basis
				test=Vector2(test.x,test.y)
				caller.state.avoid_vecs.append(test)
				
				avoid_point/=avoid_point.dot(avoid_point) # the closer the potential collision, the greater the avoid vector
				avoid_vector+=avoid_point # add together for each obstacle
	avoid_vector*=basis # traslate vector coefficients to caller pov
	avoid_vector=Vector2(avoid_vector.x,avoid_vector.y) # remove z component to flatten in view plane
	caller.state.avoid_vec=avoid_vector
	caller.state.emergency_override=true
	var total=abs(avoid_vector.x)+abs(avoid_vector.y)
	if total==0: total=1
	return {"pitching":-avoid_vector.y/total,"rolling":sign(-avoid_vector.y)*avoid_vector.x/total}
	
	# this is using the shape of the shape cast for a collision course
	# but the common_obstacle bit is more suited to a wider shape of potential paths
	# as it's more focused on making decisions for how to avoid multiple obstacles

static func instruct_level(transform):
	var rolling=1-Vector3.UP.dot(transform.basis.y) # level self
	if Vector3.UP.dot(transform.basis.x)>0: # if leftside up
		rolling*=-1 # roll negative (left) to level
	
	return rolling

static func autopilot(transform,speed,pitch_speed,HUD_points,state,caller):
	state.instructions={}
	if !state.emergency_override:
		var temp_instructions=instruct_avoid_ground(transform,speed,pitch_speed,state.ground_memory,caller)
		if temp_instructions:
			state.instructions=temp_instructions
			state.ground_memory=temp_instructions.pitching
	elif state.ground_memory: # after away from ground, reset ground memory
		state.ground_memory=0
	
#	if !state.instructions.has("emergency_override"): # if there are no avoid ground instructions
#		var temp_instructions=instruct_avoid_multiple(HUD_points)
#		if temp_instructions: # if there are planes in close proximity
#			state.instructions=temp_instructions
	
	if !state.emergency_override && state.missiles_following: # if no avoid instructions & missiles are following
		state=instruct_evade_missiles(transform,state)
		state.instructions.emergency_override=true
	
	var target_distance=HUD_points[0].pos.distance
	
	if false && state.thinking: # every 5 or 6 frames
		if !state.instructions.has("emergency_override"): # if no avoid/evade instructions
			if state.chasing:
				state.instructions=instruct_aim(HUD_points[0].intercept)
			else:
				state.instructions=instruct_avoid(HUD_points[0].pos)
			
			if !state.instructions.rolling:
				state.instructions.rolling=instruct_level(transform)
		
		state.state_duration+=1
		if target_distance>200: # if too far away
			state.chasing=true
			state.state_duration=0
		elif target_distance<randf_range(18,22) && HUD_points[0].intercept.forward_angle<0.15 && HUD_points[0].pos.forward_angle<0.15 && HUD_points[0].intercept.distance<HUD_points[0].pos.distance:
			# if playing chicken & getting close
			state.chasing=false
			state.state_duration=0
		elif !state.chasing && state.state_duration>randi_range(40,4000): # if been retreating for a while
			state.chasing=true
			state.state_duration=0
		elif state.chasing: # if pursuing
			if HUD_points[0].intercept.forward_angle<0.3: # & aimed at target
				state.state_duration=0 # forget how long been pursuing
			elif state.state_duration>80: # if chasing tails for more than 8s
				state.chasing=false
				state.state_duration=0
	
	state.instructions.shooting=state.gaming && target_distance<45 && HUD_points[0].intercept.forward_angle<PI/12
	state.instructions.firing_missile=state.gaming && target_distance<50 && HUD_points[0].pos.forward_angle<0.3
	
	return state

# --- TURNING ---

static func cap_absolute_at_1(param):
	if abs(param)>1:
		param=sign(param)
	return param

static func turn(basis,roll,pitch,yaw,delta):
	basis=basis.rotated(basis.z,roll*delta)
	basis=basis.rotated(basis.x,pitch*delta)
	basis=basis.rotated(basis.y,yaw*delta)
	return basis
