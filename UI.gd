extends Control
var screen_dimensions
var enemy_icon_scene=preload("res://enemy_icon.tscn")
var testing_enemy_icon
var enemy_camera=false

func _draw():
	draw_arc(screen_dimensions/2,screen_dimensions.y/2.2,0,TAU,100,Color("#0f0"),-1)

func _ready():
	screen_dimensions=get_node("/root").size
	testing_enemy_icon=enemy_icon_scene.instantiate()
	add_child(testing_enemy_icon)

func _process(delta):
	var HUD_angle
	if enemy_camera:
		HUD_angle=get_node("/root/Main/Enemy").player_o_clock
	else:
		var player=get_node("/root/Main/Player")
		var target=get_node("/root/Main/Enemy")
		# To show enemies on the HUD, we want the angle from the 2d HUD's upward vector to the enemy's direction vector coming out perpendicularly from player's forward axis
		var tracker_plane=Plane(player.position,player.position+player.transform.basis.z,target.position) # get plane of: player pos, just ahead of player pos relative to player, enemy pos; this plane will always include player's forward vector
		HUD_angle=tracker_plane.normal.signed_angle_to(player.transform.basis.x,-player.transform.basis.z) # angle between said plane & player's left/right splitting plane (the angle we need) = angle between said plane's normal & player's leftward vector
	
	testing_enemy_icon.position=Vector2(screen_dimensions/2)+((screen_dimensions.y/2.2)*Vector2.UP.rotated(HUD_angle))

func _unhandled_input(event):
	if InputMap.event_is_action(event,"switch_camera") && event.pressed:
		enemy_camera=not enemy_camera

func _on_hit():
	$ScoreLabel.text="Hits: %d\nEnemy's hits: %d\nCrashes: %d\nEnemy's crashes: %d" %[get_node("/root/Main/Enemy").hits_taken,
	get_node("/root/Main/Player").hits_taken,get_node("/root/Main/Player").crashes,get_node("/root/Main/Enemy").crashes]
