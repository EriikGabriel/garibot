extends Node
class_name HealthComponent

## Componente reutilizável de vida e feedback visual de dano.
@export var max_health: float = 100.0
@export var damage_flash_duration: float = 0.5

var health: float = 0.0
var parent_node: Node2D

# Controle interno do flash de dano.
var flash_timer: float = 0
var is_flashing: bool = false

func _ready() -> void:
	health = max_health
	parent_node = get_parent() as Node2D
	if not parent_node:
		push_error("HealthComponent precisa de um Node2D como pai.")

func _process(delta: float) -> void:
	if is_flashing and parent_node:
		flash_timer -= delta
		
		if flash_timer <= 0:
			parent_node.modulate = Color(1, 1, 1, 1)
			is_flashing = false

func damage(amount: float) -> void:
	if health <= 0:
		return

	health = maxf(health - amount, 0.0)

	if parent_node:
		parent_node.modulate = Color(1, 0.4, 0.4, 1)
		is_flashing = true
		flash_timer = damage_flash_duration

func heal(amount: float) -> void:
	health = minf(health + amount, max_health)
