extends Control

func show():
	visible = true
	#$Screen/AnimationPlayer.play("show",0.0)
	#$Screen/AnimationPlayer.queue("move")

func hide():
	#$Screen/AnimationPlayer.play("hide",0.0)
	visible = false
