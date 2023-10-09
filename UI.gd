extends Control
var screen_dimensions
var enemy_icon_scene=preload("res://enemy_icon.tscn")
var testing_enemy_icon

func _draw():
	draw_arc(screen_dimensions/2,screen_dimensions.y/2.2,0,TAU,100,Color("#0f0"),-1)

func _ready():
	screen_dimensions=get_node("/root").size
	testing_enemy_icon=enemy_icon_scene.instantiate()
	add_child(testing_enemy_icon)

func _process(delta):
	var player=get_node("/root/Main/Player")
	var target=Vector3.ZERO
	# To show enemies on the HUD, we want the angle from the 2d HUD's upward vector to the enemy's direction vector coming out perpendicularly from player's forward axis
	var tracker_plane=Plane(player.position,player.position+player.transform.basis.z,target) # get plane of: player pos, just ahead of player pos relative to player, enemy pos; this plane will always include player's forward vector
	var HUD_angle=tracker_plane.normal.signed_angle_to(player.transform.basis.x,-player.transform.basis.z) # angle between said plane & player's left/right splitting plane (the angle we need) = angle between said plane's normal & player's leftward vector
	
	testing_enemy_icon.position=Vector2(screen_dimensions/2)+screen_dimensions.y/2.2*Vector2.UP.rotated(HUD_angle)
