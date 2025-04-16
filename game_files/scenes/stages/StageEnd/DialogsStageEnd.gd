extends Node2D

export var player : NodePath
onready var player_node = get_node(player)
onready var dialog_begin_node = $DialogTimothyBegin

func _ready():
	if !StageManager.get_checkpointed():
		player_node.set_control(false)
		dialog_begin_node.play(tr("S3_BEGIN_DIALOG"))
		(dialog_begin_node.get_camera() as Camera2D).current = true
	pass


func _on_DialogTimothyBegin_finished():
	player_node.set_control(true)
	player_node.set_camera_current(true)



