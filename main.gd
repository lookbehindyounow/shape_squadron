extends Node

func _ready():
	$Player/Camera3D.current==true

func _unhandled_input(event):
	if InputMap.event_is_action(event,"switch_camera") && event.pressed:
		$Player/Camera3D.current=$Enemy/Camera3D.current
