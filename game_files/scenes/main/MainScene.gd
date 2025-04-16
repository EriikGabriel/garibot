extends Node

const first_stage : String = "main_menu"

func _ready():
	StageManager.change_stage(first_stage)
	verify_touch()

func verify_touch():
	if OS.has_touchscreen_ui_hint():
		Global_variable.mobile_control_node.show_buttons()
		Global_variable.mobile_control_flag = true

func show_loading_screen():
	$LoadingScreen.show()

func hide_loading_screen():
	$LoadingScreen.hide()
