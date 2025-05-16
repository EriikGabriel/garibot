extends Control

signal change_scene_to_file

func _on_play_button_if_button_pressed() -> void:
	self.get_tree().paused = false
	
	DJ.stop()
	DJ.play_sfx("ui_main_menu_select")
	
	emit_signal("change_scene_to_file", "story")
