extends Control

func show_control():
	visible = true
	#$Screen/AnimationPlayer.play("show",0.0)
	#$Screen/AnimationPlayer.queue("move")

func hide_control():
	#$Screen/AnimationPlayer.play("hide",0.0)
	visible = false
