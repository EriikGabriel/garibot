extends Node2D

var initial_position

onready var player = get_tree().get_nodes_in_group("player").front()
onready var player_camera = player.get_node("Camera2D")
onready var level_complete = get_tree().get_nodes_in_group("level_complete").front()

onready var dialog = $Dialog
onready var camera = $Camera2D
onready var camera_anim = $Camera2D/AnimationPlayer

export(Array, String, MULTILINE) var start_dialog = ["..."]
export(Array, String, MULTILINE) var end_dialog = ["..."]

const MAX_CHAR = 90

enum STATE{
	START,
	END
}

var current_state

func play_start():
	current_state = STATE.START
	player.set_in_cutscene(true)
	initial_position = player.get_position()
	player_camera.current = false;
	camera.current = true
	camera_anim.play("zoom_in")
	dialog.play(start_dialog[0])

func stop(): 
	camera_anim.play("zoom_out")

func show_level_complete():
	level_complete.set_score()
	level_complete.set_visible(true)
	
func _on_Dialog_finished():
	stop()

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "zoom_out":
		player_camera.set_camera_current(true)
		player.set_in_cutscene(false)


func _on_Area2D6_play_animation(_anim):
	play_start()

