extends Control

signal change_scene

func _on_PlayButton_button_pressed():
	self.get_tree().paused = false
	
	DJ.stop()
	DJ.play_sfx("ui_main_menu_select")
	
	emit_signal("change_scene", "story")
