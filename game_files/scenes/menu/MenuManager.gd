extends Node

signal menu_closed

func _input(event):
	#if event is InputEventKey:
		#Abrir menu de pause com a tecla P
		if event.is_action_pressed("ui_pause") and event.is_pressed() == true :
			if $GameMenu.visible == false :
				$GameMenu.open_pause_menu()
			else :
				$GameMenu.close_pause_menu()
		#Abrir galeria com a tecla G
		elif event.is_action_pressed("ui_galery") and event.is_pressed() == true :
			if $Galeria.visible == false:
				$Galeria.open_gallery()
			else :
				$Galeria.close_gallery()
		pass


func _menu_closed():
	emit_signal("menu_closed")


func _on_Galeria_hide():
	_menu_closed()


func _on_GameMenu_hide():
	_menu_closed()

