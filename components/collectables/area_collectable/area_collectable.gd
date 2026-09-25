extends Area2D
## Coletável por contato reutilizável em fases com objetivos de coleta.
class_name AreaCollectable

## Coletável simples de REEE. O visual pode ser substituído por um sprite sem
## alterar a regra de coleta ou o tutorial da fase.
@export var item_name := "resíduo eletrônico"
@export var collection_group: StringName = &"collectables"
@export var collector_group: StringName = &"player"
signal collected(item_name: String)

var _collected := false

func _ready() -> void:
	if not collection_group.is_empty():
		add_to_group(collection_group)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group(collector_group):
		return
	_collected = true
	set_deferred("monitoring", false)
	collected.emit(item_name)
	queue_free()
