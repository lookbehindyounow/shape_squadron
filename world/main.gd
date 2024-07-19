extends Node

var jet_methods=preload("res://players/JetMethods.gd")
var enemy_scene=preload("res://players/enemy.tscn")
var bullet_scene=preload("res://weapons/bullet.tscn")
var missile_scene=preload("res://weapons/missile.tscn")
var explosion_scene=preload("res://explosions/explosion.tscn")
var chemtrail_scene=preload("res://chemtrails/chemtrail.tscn")
var explosion_sound=preload("res://explosions/explosion.mp3")
var big_explosion_sound=preload("res://explosions/big_explosion.mp3")
var enemies=[]
var initial_enemy_count=1#5
var current_camera=-1
var gaming=true

func _ready():
	$Music.play(MusicContinuity.playback_pos)
	
	for i in range(initial_enemy_count):
		enemies.append(enemy_scene.instantiate())
#		enemies[i].transform.origin=Vector3(0,5.4,20)
#		enemies[i].transform=enemies[i].transform.rotated(Vector3.UP,(i+0.5)*(PI/2)/(initial_enemy_count))
		enemies[i].transform.origin=Vector3(-10,15,-8)
		enemies[i].transform.basis=enemies[i].transform.basis.rotated(Vector3.RIGHT,0.7)
		enemies[i].transform.basis=enemies[i].transform.basis.rotated(Vector3.UP,0.5)
		add_child(enemies[i])
	current_camera=initial_enemy_count-1
	update_camera()
	update_camera()

func _unhandled_input(event):
	if InputMap.event_is_action(event,"toggle_camera") && event.pressed:
		update_camera()

func _on_enemy_die(dead):
	for i in range(enemies.size()):
		if enemies[i]==dead:
			enemies.remove_at(i)
			if current_camera>=i:
				current_camera-=1
				if current_camera==i-1:
					update_camera()
			break
	explosion(dead.position,0.7)
	dead.queue_free()
	
	if enemies.size()==0:
		$UI/Endgame.text="Those triangles had families"
		$UI/Endgame.show()

func update_camera():
	current_camera+=1
	var guy
	if current_camera>=enemies.size():
		guy=$Player
		current_camera=-1
	else:
		guy=enemies[current_camera]
	guy.get_node("Camera3D").current=true
	$UI.guy=guy
	if $UI.missile:
		$UI.missile.watching=false
		$UI.missile=null

func _on_restart_pressed():
	MusicContinuity.playback_pos=$Music.get_playback_position()
	get_tree().reload_current_scene()

var chemtrail_pool=[]
func chemtrail(_transform,_life=8):
	var chem
	if chemtrail_pool:
		chem=chemtrail_pool[0]
		chemtrail_pool.remove_at(0)
	else:
		chem=chemtrail_scene.instantiate()
		add_child(chem)
	chem.set_up(_transform,_life)

var bullet_pool=[]
func bullet(_transform):
	var bull
	if bullet_pool:
		bull=bullet_pool[0]
		bullet_pool.remove_at(0)
	else:
		bull=bullet_scene.instantiate()
	bull.set_up(_transform)
	add_child(bull)

var missile_pool=[]
func missile(_transform,_target,_watching):
	var miss
	if missile_pool:
		miss=missile_pool[0]
		missile_pool.remove_at(0)
	else:
		miss=missile_scene.instantiate()
	miss.set_up(_transform,_target,_watching)
	add_child(miss)
	miss.get_node("AudioStreamPlayer3D").play()

var explosion_pool=[]
func explosion(_position,_life,silent=false):
	var boom
	if explosion_pool:
		boom=explosion_pool[0]
		explosion_pool.remove_at(0)
	else:
		boom=explosion_scene.instantiate()
	boom.set_up(_position,_life)
	add_child(boom)
	if not silent:
		boom.get_node("AudioStreamPlayer3D").play()

func _on_music_finished():
	$Music.play()
