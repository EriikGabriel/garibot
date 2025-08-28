extends Node

func _input(event):
	if event.is_action_pressed("window_mode"):
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_MAXIMIZED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN  
			else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
