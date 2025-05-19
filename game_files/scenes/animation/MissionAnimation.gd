extends Node

var initial_position

@onready var player : Player = get_tree().get_nodes_in_group("player").front()
@onready var level_complete = get_tree().get_nodes_in_group("level_complete").front()

@onready var dialog : ControllerAnim = $Dialog
@onready var camera = $Camera2D
@onready var camera_anim = $Camera2D/AnimationPlayer

@export var start_dialog = ["..."] # (Array, String, MULTILINE)
@export var end_dialog = ["..."] # (Array, String, MULTILINE)

enum STATE {
	START,
	END
}

var current_state

func _ready():
	play_start()


func play_start():
	current_state = STATE.START
	player.set_control(false)
	initial_position = player.get_position()
	player.set_camera_current(false)
	camera.set_global_position(player.get_camera_position())
	dialog.play(start_dialog[0])


func play_end():
	current_state = STATE.END
	player.set_control(false)
	player.set_position(initial_position)
	player.change_orientation(1)
	player.set_camera_current(false)
	camera.set_offset(Vector2(75,-75))
	camera.set_zoom(Vector2(0.65,0.65))
	camera.set_current(true)
	dialog.play(end_dialog[0])


func stop(): 
	camera_anim.play("zoom_out")


func show_level_complete():
	level_complete.set_score()
	level_complete.set_visible(true)


func _on_Dialog_finished():
	if current_state == STATE.START:
		stop()
	elif StageManager.current_stage == 'tutorial' :
		StageManager.change_stage("gallery_tutorial")
	else:
		show_level_complete()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "zoom_out":
		player.set_camera_current(true)
		player.set_in_cutscene(false)
		player.set_control(true)


func _on_RecicleStation_play_end():
	play_end()


func _on_Area2D_body_entered(body):
	if body.is_in_group("player"):
		play_end()
		player.set_ctrl(false)
