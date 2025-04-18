@tool
extends MarginContainer

@export var text: String = "TUTORIAL_HINT_0"

func _ready():
	if Global_variable.mobile_control_flag:
		text = tr(text + "_MOBILE")
	$Panel/HBoxContainer/Label.text = text
