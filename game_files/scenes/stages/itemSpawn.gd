extends Node2D

var spawnLix = preload("res://scenes/item/ItemMiniGame.tscn")


var posX = [50,700]

var itemName 

func _on_Timer_timeout():
	var lixo = spawnLix.instantiate()
	itemName = Global_variable.get_name_item_collect()
	if itemName.size() == 0 : 
		if $EndGame.is_stopped() :
			$EndGame.start(5)
	else : 
		lixo.itemName = itemName[randi() % itemName.size()]
		#print_debug(lixo.itemName)
		Global_variable.remove_item_collect(lixo.itemName)
		lixo.position.x = randi() % posX[1] + posX[0]
		lixo.position.y = 10
		get_parent().add_child(lixo)



func _on_EndGame_timeout():
	#get_node("../CanvasLayer/LevelBonusComplete").set_score()
	get_node("../CanvasLayer/LevelComplete").set_visible(true)
	get_node("../CanvasLayer/LevelComplete").set_score()
	get_node("../CanvasLayer/GameUI").set_visible(false)
