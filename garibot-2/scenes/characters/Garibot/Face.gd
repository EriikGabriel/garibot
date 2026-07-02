extends Sprite2D

func _ready():
	set_face(0);
	pass

func set_face( idx ):
	self.set_frame( idx );
	pass
