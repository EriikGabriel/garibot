extends Node2D

const BEGIN_POS = 1710
const END_POS = 2630

const BEGIN_POS2 = 2775
const END_POS2 = 3800

export var player: NodePath 
onready var player_node = get_node(player)
var zoom = 1
var total_zoom = 1

func _process(_delta):
	_calculate_camera_zoom()

func _calculate_camera_zoom():
	if BEGIN_POS < player_node.position.x && player_node.position.x < END_POS:
		zoom = 1 + (1.25 * ((player_node.position.x - BEGIN_POS) / (END_POS - BEGIN_POS)))
		total_zoom = zoom
		player_node.get_node("Camera2D").set_zoom(Vector2(zoom, zoom))
	
	elif BEGIN_POS2 < player_node.position.x && player_node.position.x < END_POS2:
		zoom = total_zoom - (1.25 * ((player_node.position.x - BEGIN_POS2) / (END_POS2 - BEGIN_POS2)))
		player_node.get_node("Camera2D").set_zoom(Vector2(zoom, zoom))

