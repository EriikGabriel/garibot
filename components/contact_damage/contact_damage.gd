extends Node2D
class_name ContactDamage

## Dano entregue a uma HitboxComponent quando o corpo entra em contato.
@export var contact_damage: float = 20.0

var contact_att: Toolkit.Attack

func _ready() -> void:
	contact_att = Toolkit.Attack.new(contact_damage)
