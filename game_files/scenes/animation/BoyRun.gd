extends Node2D

var control = false
onready var last_x = 0

func _process(_delta):
	if last_x != global_position.x:
		$Corpo/PersonAnimationPlayer.play("run")
	else:
		$Corpo/PersonAnimationPlayer.play("idle")
	
	last_x = global_position.x
