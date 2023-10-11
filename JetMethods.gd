static func get_HUD_angles(transform,target_pos):
	# talk abuot how this is done
	var tracking_plane=Plane(transform.origin,transform.origin+transform.basis.z,target_pos)
	var clock_face=tracking_plane.normal.signed_angle_to(transform.basis.x,-transform.basis.z)
	
	var forward_angle=acos((target_pos-transform.origin).normalized().dot(transform.basis.z))
	
	return [clock_face,forward_angle]

static func track(transform,target_pos,target_velocity):
	# bullet speed is 50
	var targToPlayer_dot_targV=(transform.origin-target_pos).normalized().dot(target_velocity.normalized())
	var sin_target_travel_angle=target_velocity.length()*sqrt(1-(targToPlayer_dot_targV**2))/50
	var bullet_intercept_angle=PI-asin(sin_target_travel_angle)-acos(targToPlayer_dot_targV)
	var target_travel=sin_target_travel_angle*(transform.origin-target_pos).length()/sin(bullet_intercept_angle)
	var bullet_intercept_pos=target_pos+target_travel*target_velocity.normalized()
	
	var HUD_angles=get_HUD_angles(transform,target_pos)
	var ahead_HUD_angles=get_HUD_angles(transform,bullet_intercept_pos)
	
	return [HUD_angles,ahead_HUD_angles]

static func autopilot(tracking_angles):
	var rolling=0
	var pitching=0
	
	# could maybe reduce code here by using positive/negative dot products (against all transform basis axes) to figure out which way to go
	if abs(tracking_angles[1][0])>PI/20 && abs(tracking_angles[1][0])<0.95*PI: # if target not at top or bottom centre of clock face
		if abs(tracking_angles[1][0])<2*PI/3: # target in top 2/3 of clock face
			if tracking_angles[1][0]>0:# top-right
				rolling+=1
			else: # top-left
				rolling-=1
		elif abs(tracking_angles[1][0])>=2*PI/3: # target in bottom 1/3 of clock face
			if tracking_angles[1][0]>0: # bottom-right
				rolling-=1
			else: # bottom-left
				rolling+=1

	if abs(tracking_angles[1][0])<0.4*PI: # target in top 2/5 of clock face
		pitching-=1
	elif abs(tracking_angles[1][0])>0.8*PI: # target in botom 1/5 of clock face
		pitching+=1
	return [rolling,pitching]

static func turn(basis,roll,pitch,delta):
	basis=basis.rotated(basis.z,roll*delta)
	basis=basis.rotated(basis.x,pitch*delta)
	return basis

static func shoot(shooter):
	var bullet=shooter.get_node("/root/Main").bullet_scene.instantiate()
	bullet.global_transform=shooter.global_transform
	bullet.position+=shooter.transform.basis.z
	bullet.linear_velocity=shooter.transform.basis.z*50
	shooter.get_node("/root/Main").add_child(bullet)

static func collide(collider):
	if collider.is_in_group("bullets"):
		collider.queue_free()
		return true
	return false
