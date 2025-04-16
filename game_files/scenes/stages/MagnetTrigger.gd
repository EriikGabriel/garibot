extends Area2D

export(int, "DOWN", "RIGHT", "UP", "LEFT") var gravity_trigger

func _on_MagnetTrigger_body_entered(body):
	if body.is_in_group("player"):
		#if body.gravity != gravity_trigger:
		body.change_gravity(gravity_trigger)
