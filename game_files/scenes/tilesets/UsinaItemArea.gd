extends Area2D

var tagged = false
@export var texture : Texture2D

func tag():
	tagged = true
	get_parent().set_sprite(texture)
	print_debug("tagged")


func get_tag():
	return tagged

func get_name():
	return get_parent().name_item
func set_sprite(_texture):
	get_parent().set_sprite(_texture)

func connect_to_minigame4(minigame4):
	get_parent().connect_to_minigame4(minigame4)


func destroy():
	get_parent().queue_free()
	queue_free()
