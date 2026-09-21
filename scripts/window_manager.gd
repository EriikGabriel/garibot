extends Node

func _input(event):
	if event.is_action_pressed("window_mode"):
		var fullscreen_now: bool = DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_MAXIMIZED if fullscreen_now
			else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
		if Settings:
			Settings.set_setting("fullscreen", fullscreen_now)
