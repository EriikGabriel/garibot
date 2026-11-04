class_name HealthComponent
extends Node

## Vida de um personagem, com um piscar vermelho ao levar dano.

@export var max_health := 100.0
@export var damage_flash_duration := 0.5

var health := 0.0

var _flash_left := 0.0
@onready var _owner_body := get_parent() as CanvasItem


func _ready() -> void:
	health = max_health


func _process(delta: float) -> void:
	if _flash_left <= 0.0:
		return
	_flash_left -= delta
	if _flash_left <= 0.0 and _owner_body:
		_owner_body.modulate = Color.WHITE


func damage(amount: float) -> void:
	if health <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	if _owner_body:
		_owner_body.modulate = Color(1, 0.4, 0.4)
		_flash_left = damage_flash_duration


func heal(amount: float) -> void:
	health = minf(health + amount, max_health)
