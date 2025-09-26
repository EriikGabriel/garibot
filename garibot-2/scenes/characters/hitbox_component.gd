extends Area2D
class_name HitboxComponent
@export var health:HealthComponent

func damage(att):
	if health:
		if(att is float):
			health.damage(att)
		else: if att is Toolkit.Attack:
			health.damage(att.damage)
