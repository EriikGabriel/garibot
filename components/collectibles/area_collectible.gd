class_name AreaCollectible
extends Area2D

## Item coletado ao ser tocado por um corpo do grupo `collector_group`.

signal collected(item_name: String)

@export var item_name := "resíduo eletrônico"
@export var collection_group := &"collectibles"
@export var collector_group := &"player"

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
