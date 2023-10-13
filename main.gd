extends Node

var enemy_scene=preload("res://enemy.tscn")
var bullet_scene=preload("res://bullet.tscn")
var enemies=[]
var current_camera=-1
var gaming=true

func _ready():
	var initial_enemy_count=5
	$Player/Camera3D.current=true
	$UI/StatusLabel.text="Health: %s" %$Player.health
	for i in range(initial_enemy_count):
		enemies.append(enemy_scene.instantiate())
		enemies[i].transform.origin=Vector3(0,6,5)
		enemies[i].transform=enemies[i].transform.rotated(Vector3.UP,(1.0+i)/(initial_enemy_count+1)*PI/2)
		add_child(enemies[i])

func _unhandled_input(event):
	if InputMap.event_is_action(event,"toggle_camera") && event.pressed:
		current_camera+=1
		if current_camera==enemies.size():
			$Player/Camera3D.current=true
			current_camera=-1
			if gaming:
				$UI/StatusLabel.text="Health: %s" %$Player.health
			else:
				$UI/StatusLabel.text=""
		else:
			enemies[current_camera].get_node("Camera3D").current=true
			$UI/StatusLabel.text="Health: %s" %enemies[current_camera].health

func _on_enemy_die(dead):
	for i in range(enemies.size()):
		if enemies[i]==dead:
			enemies.remove_at(i)
			if current_camera>=i:
				current_camera-=1
				if current_camera==-1:
					$Player/Camera3D.current=true
					if gaming:
						$UI/StatusLabel.text="Health: %s" %$Player.health
					else:
						$UI/StatusLabel.text=""
				else:
					if current_camera<-1:
						current_camera=enemies.size()-1
					enemies[current_camera].get_node("Camera3D").current=true
					$UI/StatusLabel.text="Health: %s" %enemies[current_camera].health
			break
	dead.queue_free()
	
	if enemies.size()==0:
		$UI/Endgame.text="Those triangles had families"
		$UI/Endgame.show()

func _on_restart_pressed():
	get_tree().reload_current_scene()
