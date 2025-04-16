extends Node2D

var counter = 0
signal all_done

func _on_BlackBox_area_entered(area):
	
	if !area.get_tag():
		area.destroy()
	else:
		counter += 1
		if counter < 5:
			DJ.play_sfx('right_answer_1')
			$Label.text = str(counter) + "/5"
			area.destroy()
		elif counter >= 5:
			DJ.play_sfx('right_answer_3')
			area.set_sprite(ItemTextureMap.textures_m[area.get_name()])
			emit_signal("all_done")
			counter = 5
			$Label.text = str(counter) + "/5"
		else:
			area.destroy()
