extends Area2D

enum TYPE {SWITCH, FADE_OUT}
export(TYPE) var type
export var oneshot := true

func _on_SongTransitionTrigger_body_exited(_body):
	match type:
		TYPE.SWITCH:
			DJ.switch()
		TYPE.FADE_OUT:
			DJ.stop()
	if oneshot:
		queue_free()
