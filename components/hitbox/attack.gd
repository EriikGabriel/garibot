class_name Attack
extends RefCounted

## Dados de um golpe, para que hitboxes não dependam do tipo de quem ataca.

var damage: float


func _init(amount: float) -> void:
	damage = amount
