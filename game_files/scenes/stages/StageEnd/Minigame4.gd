extends Node2D

@onready var dialog_boss_node = get_node_or_null("Dialog")

@export var final_boss : NodePath
@onready var final_boss_node = get_node(final_boss)

@export var player : NodePath
@onready var player_node = get_node(player)

signal gravity_altered

func plate_updated(pressed):
	emit_signal("gravity_altered", pressed)


func _on_StartDialog_body_entered(_body):
	player_node.set_ctrl_pressed(false)
	StageManager.set_checkpointed(true)
	dialog_boss_node.get_camera_3d().current = true
	dialog_boss_node.play("S3_BOSS_DIALOG") 


func _on_Dialog_finished():
	player_node.set_ctrl_pressed(true)
	player_node.set_camera_current(true)
	dialog_boss_node.visible = false
	final_boss_node.visible = true
	final_boss_node.boss_start_move()
	dialog_boss_node.queue_free()
	
	DJ.play('stage_final-chase')


func _on_Dialog_dialog_finished(node_name):
	if node_name == "Dialog":
		_on_Dialog_finished()



