extends Node2D

# Declare member variables here. Examples:
# var a = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_node("TileMap").set_collision_layer_value(0,true)
	self.visible = true
		
#	pass


func _on_FinalBoss_half_life(variable):
	if variable == 1:
		get_node("TileMap").set_collision_layer_value(0,false)
		self.visible = false
	pass # Replace with function body.
