extends Node2D
class_name ContactDamage
@export var contact_damage :float=20

var contact_att : Toolkit.Attack

func _ready()->void:
	contact_att = Toolkit.Attack.new(contact_damage)
