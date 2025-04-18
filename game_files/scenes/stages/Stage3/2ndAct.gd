extends Node2D

const BEGIN_POS = 9300
const END_POS = 10500

@export var player: NodePath 
@onready var player_node = get_node(player)
var zoom = 1

func _process(_delta):
	_calculate_camera_zoom()
	_test_enable_follow_people()

func _calculate_camera_zoom():
	if BEGIN_POS < player_node.position.x && player_node.position.x < END_POS:
		zoom = 1 - (0.10 * ((player_node.position.x - BEGIN_POS) / (END_POS - BEGIN_POS)))
		player_node.get_node("Camera2D").set_zoom(Vector2(zoom, zoom))

func _test_enable_follow_people():
	var follow_people = player_node.get_node("FollowPeople")
	if player_node.position.x > END_POS and not follow_people.enabled:
		follow_people.enabled = true
