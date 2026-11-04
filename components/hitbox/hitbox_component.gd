class_name HitboxComponent
extends Area2D

## Recebe golpes e repassa o dano ao componente de vida configurado.

@export var health: HealthComponent


func damage(attack: Attack) -> void:
	if health:
		health.damage(attack.damage)
