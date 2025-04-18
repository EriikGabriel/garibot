extends Area2D

enum TYPE {SWITCH, FADE_OUT}
@export var type: TYPE
@export var one_shot := true

func _on_SongTransitionTrigger_body_exited(_body):
	match type:
		TYPE.SWITCH:
			DJ.switch()
		TYPE.FADE_OUT:
			DJ.stop()
	if one_shot:
		queue_free()
