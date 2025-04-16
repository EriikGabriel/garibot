extends AnimationPlayer


func play_animation(anim):
	stop()
	play(anim)


func playback_animation(anim):
	play_backwards(anim)


func stop_animation():
	stop()
	play("vazio")


func _on_RecicleStation_play_end():
	get_parent().set_visible(false)
