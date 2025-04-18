extends Area2D

@export var gravity_trigger # (int, "DOWN", "RIGHT", "UP", "LEFT")

func _on_MagnetTrigger_body_entered(body):
	if body.is_in_group("player"):
		#if body.gravity != gravity_trigger:
		body.change_gravity(gravity_trigger)
