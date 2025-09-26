extends Node2D
class_name HealthComponent

@export var max_health:float = 100
var health = 0
func _ready()->void:
	health = max_health
func damage(dam:float):
	print("Gah Dam: "+str(dam))
	if(health>=dam):
		health -= dam
	
func heal(h:float):
	if(health+h<=max_health):
		health += h
	
