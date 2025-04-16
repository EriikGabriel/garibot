extends Node2D
onready var animPlayer = $AnimationPlayer

func play( st , spd = 1):
	animPlayer.play(st, -1, spd)
