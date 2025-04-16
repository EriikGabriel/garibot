extends Area2D

func destroy():
	self.get_parent().queue_free()
