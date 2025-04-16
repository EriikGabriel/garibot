extends Area2D

onready var dialog_node = get_parent()
var dialog_check = false

export var player: NodePath
export var galeria : NodePath
onready var player_node = get_node(player)
onready var galeria_node = get_node(galeria)


func _on_ActivationArea_body_entered(_body):
	dialog_node.get_camera().current = true
	dialog_node.play(tr('S3_FACTORY_DIALOG'))
	player_node.set_in_cutscene(true)
	dialog_check = true


func _on_DialogTimothy_finished():
	player_node.set_camera_current(true)
	player_node.set_in_cutscene(false)
	if dialog_check:
		galeria_node.open_gallery()
		dialog_check = false


func _on_DialogHoloTimothy_finished():
	player_node.set_camera_current(true)
	player_node.set_in_cutscene(false)
