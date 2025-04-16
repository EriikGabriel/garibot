extends Area2D

func _on_TagItems_area_entered(area):
	if area.has_method("connect_to_minigame4"):
		area.connect_to_minigame4(get_parent())
		print_debug("method")
