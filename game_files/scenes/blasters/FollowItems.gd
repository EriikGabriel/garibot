extends Node


var j = 0
const SPEED = 10


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var side = -1 + (int(self.get_parent().get_node("sprite").scale.x < 0)*2)
	var i = 0;
	for item in self.get_children():
		i += 1;
		item.position = (item.position.lerp( (self.get_parent().position + 
					Vector2 (i*(side)*20, 0)), delta*SPEED*(self.get_child_count()-i+2)/self.get_child_count()))
	pass
