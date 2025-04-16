extends Node2D

onready var anim_player = $AnimationPlayer

func play(name: String, blend: float, speed: float, from_end: bool):
	anim_player.play(name, blend, speed, from_end)


func set_reaction(reaction: String):
	if reaction == 'Happy' or reaction == 'H':
		anim_player.play("Happy")
	elif reaction == 'Angry' or reaction == 'A':
		anim_player.play("Angry")
	elif reaction == 'Thinking' or reaction == 'T':
		anim_player.play("Thinking")
	else:
		anim_player.play("default")
