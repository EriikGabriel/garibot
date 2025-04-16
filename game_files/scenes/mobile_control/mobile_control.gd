extends Node2D

onready var buttons_node = $CanvasLayer/Buttons
onready var pause_node = $CanvasLayer/Pause

func _ready():
	Global_variable.mobile_control_node = self

func set_bonus_controls():
	pause_node.set_bonus_stage_position()


func set_default_controls():
	pause_node.reset_default_position()


func show_buttons():
	buttons_node.set_visible(true)


func hide_buttons():
	buttons_node.set_visible(false)


func buttons_visibile() -> bool:
	 return $CanvasLayer/Buttons.is_visible_in_tree()


func show_pause_button():
	$CanvasLayer/Pause.set_visible(true)


func hide_pause_button():
	$CanvasLayer/Pause.set_visible(false)
