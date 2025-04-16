extends Node2D

var player


func _process(delta):
	if player and get_node("../Player").position.x > 834:
		changecamera2D2()


func changecamera2D2():
	player.set_camera_current(false)
	get_node("Camera2D2").current = true


func _on_FinalBoss_half_life(variable):
	if variable == 1:
		get_node("Camera2D1").current = false
		player.set_camera_current(true)


func _on_Player_emit_player(_new):
	player = _new
