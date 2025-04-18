extends Node


var collectedItems = {
	}

#	"celular" : 0,
#	"monitor" : 0,
#	"tv" : 0,
#	"impressora" : 0,
#	"furadeira" : 0,
#	"fogao" : 0,
#	"geladeira" : 0,
#	"microondas" : 0,
#	"agua" : 0,
#	"garrafa" : 0,
#	"jornal" : 0,
#	"melancia" : 0,
#	"refri" : 0,
#	"sacola" : 0

const SPEED = 10

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var side = -1 + (int(get_parent().get_body().scale.x < 0)*2)
	var i = 0;
	for item in $Items.get_children():
		i += 1;
		if(i<=3):
			item.global_position = item.global_position.lerp( (self.global_position + 
									Vector2 (side*(i*20+12), 0)), delta*SPEED*(3-i+1)/3);
		else:
			item.set_visible(false)
	pass

func add_item(name, item_texture):
	# collected items list
	#GAMBIARRAAAAAA
	if name == null:
		add_to_collected_items(["celular", item_texture])
	else:
		add_to_collected_items([name, item_texture])
	
	Global_variable.add_item_collect(name)


	# follow items
	var next = $Items.get_child(0).get_texture()
	$Items.get_child(0).set_texture(item_texture)
	for i in range(1,3):
		var aux = next
		next = $Items.get_child(i).get_texture()
		$Items.get_child(i).set_texture(aux)


func add_to_collected_items(entry):
	var entry_name = entry[0]
	
	if collectedItems.has(entry_name):
		collectedItems[entry] += 1
	else:
		collectedItems[entry] = 1
	
	ItemTextureMap.increase_count(entry_name)


func hide():
	for item in $Items.get_children():
		item.set_visible(false);


func get_collected_items():
	return collectedItems

