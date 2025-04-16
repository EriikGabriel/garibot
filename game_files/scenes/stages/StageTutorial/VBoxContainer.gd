extends VBoxContainer

var has_touch = null

func _ready():
	has_touch = Global_variable.mobile_control_flag
	
	$TextureRect3.set_visible(has_touch)
	$TextureRect2.set_visible(!has_touch)

