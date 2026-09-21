extends Area2D
class_name HitboxComponent

## Encaminha dano recebido ao componente de vida configurado na cena.
@export var health: HealthComponent

func damage(attack: Variant) -> void:
	if health == null:
		return

	if attack is float or attack is int:
		health.damage(float(attack))
	elif attack is Toolkit.Attack:
		health.damage(attack.damage)
