extends Node

var has_touch = true

func _ready():
	#has_touch = Global_variable.mobile_control_flag
	
	$Mobile_button.set_visible(has_touch)
	$Space.set_visible(!has_touch)

