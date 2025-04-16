extends Node2D

onready var map = self.get_parent()
onready var player_body_node = $player_body

var lastPos
onready var bodyAnimation = get_node("player_body/AnimationPlayer")
# Called when the node enters the scene tree for the first time.
func _ready():
	lastPos = self.position
	pass # Replace with function body.

func _process(_delta):
	if lastPos.x < self.position.x:
		player_body_node.set_scale(Vector2(1,1))
		bodyAnimation.play("walk",-1,5)
	elif lastPos.x > self.position.x:
		player_body_node.set_scale(Vector2(-1,1))
		bodyAnimation.play("walk",-1,5)
	else:
		bodyAnimation.play("idle")
	
	lastPos = self.position
