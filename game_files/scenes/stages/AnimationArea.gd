extends Area2D

@export var animation = "parte4"
signal play_animation(anim)
signal stop_animation
signal playback_animation

func _on_Area2D_body_entered(_body):
	if _body.is_in_group("player"):
		emit_signal("play_animation", animation)

func _on_Area2D_body_exited(_body):
	emit_signal("stop_animation")


func _on_RecicleStation_created_ui(_a):
	emit_signal("playback_animation", animation)
