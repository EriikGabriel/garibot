extends Button




func _on_VoltarButton_pressed():
	StageManager.change_stage("main_menu")
	get_parent().queue_free()
