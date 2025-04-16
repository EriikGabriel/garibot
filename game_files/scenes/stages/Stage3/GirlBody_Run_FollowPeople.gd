extends Node2D

const MIN_DIST = 0.1

var control = false
onready var last_x = 0

func _process(_delta):
	if _is_running():
		$GirlBody/Corpo/PersonAnimationPlayer.play("run")
	else:
		$GirlBody/Corpo/PersonAnimationPlayer.play("idle")
	
	last_x = global_position.x

func _is_running() -> bool:
	return global_position.x - last_x > MIN_DIST || global_position.x - last_x < -1*MIN_DIST
