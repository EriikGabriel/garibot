extends TextureProgressBar

func _ready():
	self.max_value = (get_tree().get_nodes_in_group("item").size() 
					+ get_tree().get_nodes_in_group("enemies").size());
	
	for convencivel in get_tree().get_nodes_in_group("convencivel"):
		self.max_value += convencivel.qtditem
		
	if self.max_value == 0 :
		self.max_value = Global_variable.get_qtd_item()


func increase():
	value += 1
