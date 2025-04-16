extends Button

func _pressed():
	$Residuo_popup2.popup_centered()
	

func _on_MenuPrincipal2_pressed():
	self.get_tree().paused = false
	StageManager.change_stage("world_map")
