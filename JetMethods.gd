static func track(transform,target_pos):
	var tracking_plane=Plane(transform.origin,transform.origin+transform.basis.z,target_pos)
	return tracking_plane.normal.signed_angle_to(transform.basis.x,-transform.basis.z)

static func autopilot(transform,target_pos):
	var rolling=0
	var pitching=0
	var shooting=false
	
	var target_o_clock=track(transform,target_pos)
	
	# if target within 15deg angle of forward vector (cos(15deg)≈0.966
	if (target_pos-transform.origin).normalized().dot(transform.basis.z)>0.966:
		shooting=true
	# could maybe reduce code here by using positive/negative dot products (against all transform basis axes) to figure out which way to go
	if abs(target_o_clock)>PI/20 && abs(target_o_clock)<0.95*PI: # if target not at top or bottom centre of clock face
		if abs(target_o_clock)<2*PI/3: # target in top 2/3 of clock face
			if target_o_clock>0:# top-right
				rolling+=1
			else: # top-left
				rolling-=1
		elif abs(target_o_clock)>=2*PI/3: # target in bottom 1/3 of clock face
			if target_o_clock>0: # bottom-right
				rolling-=1
			else: # bottom-left
				rolling+=1

	if abs(target_o_clock)<0.4*PI || abs(target_o_clock)>0.6*PI: # if target in top 2/5 or bottom 2/5 of clock face
		if (target_pos-transform.origin).normalized().dot(transform.basis.y)>0: # target above
			pitching-=1
		else: # target below
			pitching+=1
	return [target_o_clock,rolling,pitching,shooting]

static func turn(basis,roll,pitch,delta):
	basis=basis.rotated(basis.z,roll*delta)
	basis=basis.rotated(basis.x,pitch*delta)
	return basis

static func shoot(shooter):
	var bullet=shooter.get_node("/root/Main").bullet_scene.instantiate()
	bullet.global_transform=shooter.global_transform
	bullet.position+shooter.transform.basis.z
	if shooter.name=="Player":
		bullet.position+=0.2*shooter.transform.basis.y
	bullet.linear_velocity=shooter.transform.basis.z*100
	shooter.get_node("/root/Main").add_child(bullet)

static func collide(collider):
	if collider.is_in_group("bullets"):
		collider.queue_free()
		return true
	return false
