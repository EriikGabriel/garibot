extends Area2D

onready var dialog_node = get_parent()

export var player: NodePath
onready var player_node = get_node(player)

export var dialog_text: String

var first_time = true;

func _on_ActivationArea_body_entered(_body):
	if first_time:
		dialog_node.get_camera().current = true
		dialog_node.play(tr(dialog_text))
		player_node.set_in_cutscene(true)
	else:
		dialog_node.play(tr(dialog_text))


func _on_DialogTimothy_finished():
	if first_time:
		player_node.set_camera_current(true)
		player_node.set_in_cutscene(false)
		first_time = false


func _dialog_finished():
	if first_time:
		player_node.set_camera_current(true)
		player_node.set_in_cutscene(false)
		first_time = false


func _on_DialogHoloTimothy_finished():
	_dialog_finished()

func _on_DialogHoloTimothy2_finished():
	_dialog_finished()


func _on_DialogHoloTimothy3_finished():
	_dialog_finished()


func _on_DialogHoloTimothy4_finished():
	_dialog_finished()


func _on_DialogHoloTimothy5_finished():
	_dialog_finished()


func _on_DialogHoloTimothy6_finished():
	_dialog_finished()
