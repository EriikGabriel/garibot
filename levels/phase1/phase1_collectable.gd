extends Area2D
class_name Phase1Collectable

## Coletável simples de REEE. O visual pode ser substituído por um sprite sem
## alterar a regra de coleta ou o tutorial da fase.
@export var item_name := "resíduo eletrônico"
signal collected(item_name: String)

var _collected := false

func _ready() -> void:
	add_to_group("phase1_reee")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _collected or not body is Player:
		return
	_collected = true
	monitoring = false
	collected.emit(item_name)
	queue_free()
