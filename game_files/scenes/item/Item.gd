tool
extends "res://scenes/item/ItemScript.gd"

var item
onready var value_bar = get_tree().get_nodes_in_group("value_bar").front()

var _itemName
export (String, "celular", "monitor", "tv", "impressora",
		"furadeira", "fogao", "geladeira", "microondas","agua","garrafa","jornal",
		"melancia","refri","sacola","radio","bateria") var itemName setget setItemName, getItemName

var map_of_eletric_texture ={
	1: "celular",
	2: "monitor",
	3: "tv",
	4: "impressora",
	5: "furadeira",
	6: "fogao",
	7: "geladeira",
	8: "microondas",
	9: "radio",
	10: "bateria",
	}

func _ready():
	var _error = $SFX.connect("finished", self, "_on_sfx_finished")
	add_to_group("item")


func setItemName(newName):
	_itemName = newName
	change_item()


func getItemName():
	return _itemName


func _on_Item_body_entered(body):
	if body.name == "Player":
		stop_signal()
		collect(body)


func collect( var player ):
	visible = false
	$SFX.play()
	player.add_item(self.item, $Sprite.get_texture())
	#player.get_node("FollowItems").setCollectedItem(self.item)
	value_bar.value += 1


func _on_sfx_finished():
	queue_free()


func change_item():
	if ItemTextureMap and ItemTextureMap.get(_itemName) != null:
		item = _itemName
		if get_node_or_null("Sprite"): $Sprite.set_texture(ItemTextureMap.get(_itemName).texture)


func stop_signal():
	if self.is_connected("body_entered", self, "_on_Item_body_entered"):
		self.disconnect("body_entered", self, "_on_Item_body_entered")

func _on_Timer_timeout():
	self.monitoring = true
