class_name HealthComponent
extends Node

## Vida de um personagem, com um piscar vermelho ao levar dano.

signal health_changed(health: float, max_health: float)
signal died

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


func is_dead() -> bool:
	return health <= 0.0


func damage(amount: float) -> void:
	if is_dead():
		return
	health = maxf(health - amount, 0.0)
	if _owner_body:
		_owner_body.modulate = Color(1, 0.4, 0.4)
		_flash_left = damage_flash_duration
	health_changed.emit(health, max_health)
	if is_dead():
		died.emit()


func heal(amount: float) -> void:
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)


## Volta à vida cheia (ex.: ao renascer no checkpoint).
func restore() -> void:
	heal(max_health)
