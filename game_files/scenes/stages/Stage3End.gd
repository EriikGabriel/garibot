extends Node2D

@export var level_complete: NodePath
@onready var level_complete_node = get_node(level_complete)
var end = false
var player = null

func _on_Area2D_body_entered(body):
	if body.is_in_group("player"):
		player = body
		body.has_control = false
		$DialogBoy/Camera2D.current = true
		$DialogGaridog2.play(tr("S2_END1_DIALOG"))
		end = true


func _on_DialogBoy_finished():
	if end:
		player.set_camera_current(true)
		player.has_control = true


func show_level_complete():
	level_complete_node.set_score()
	level_complete_node.set_visible(true)


func _on_DialogGaridog2_finished():
	$DialogBoy.play(tr("S2_END2_DIALOG"))


func _on_Area2D_end_body_entered(body):
	if body.is_in_group("player"):
		player = body
		body.has_control = false
		$DialogGaridog3/Camera2D.current = true
		if player.get_follow_people().amount > 5:
			$DialogGaridog3.play(tr("S2_END3_DIALOG"))
		else:
			$DialogGaridog3.play(tr("S2_END3_DIALOG_FAIL"))


func _on_DialogGaridog_dialog_finished(_node_name):
	show_level_complete()
