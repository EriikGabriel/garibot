extends Node2D

onready var dialog = $DialogTimothy
onready var label = $CanvasLayer/Label
var gallery_opened = false

func _ready():
	var text = "GALLERY_INSTRUCTIONS"
	var label_text = "GALLERY_LABEL"
	
	if Global_variable.mobile_control_flag:
		text = text + "_MOBILE"
		label_text = label_text + "_MOBILE"
	
	dialog.play(tr(text))
	label.text = tr(label_text)
	label.hide()


func _on_DialogTimothy_finished():
	label.show()


func _on_MenuManager_menu_closed():
	if gallery_opened:
		$CanvasLayer/LevelComplete.hide_stars()
		$CanvasLayer/LevelComplete.show()

func _on_Galeria_visibility_changed():
	gallery_opened = true
