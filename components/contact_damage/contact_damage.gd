class_name ContactDamage
extends Node2D

## Dano causado a quem encosta no corpo pai (o pai deve estar no grupo "DamageOnContact").

@export var amount := 20.0

var attack: Attack


func _ready() -> void:
	attack = Attack.new(amount)
