extends Panel

func set_texts(image, label2, label3, label4):
	$VBoxContainer/CenterContainer/TextureRect.texture = image
	$VBoxContainer/Label2.text = label2
	$VBoxContainer/Label3.text = label3
	$VBoxContainer/Label4.text = label4


func _on_Timer_timeout():
	self.hide()

func _on_TutorialWindow_focus_entered():
	$Timer.start()
