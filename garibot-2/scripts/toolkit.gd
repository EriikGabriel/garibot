extends Node
#Useful global classes and functions
func _input(event):
	if event.is_action_pressed("ui_cancel"):  # or "toggle_fullscreen"
		toggle_fullscreen()

func toggle_fullscreen():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		print("Switched to windowed mode")
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		print("Switched to fullscreen mode")
		
class Attack:
	var damage : float
	func _init(dam:float):
		self.damage = dam
		
