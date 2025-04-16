extends Node2D

var collectedItems = { }

export var y_default = 128.8

const SPEED = 10

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var side = -1 + (int(get_parent().get_body().scale.x < 0)*2)
	var i = 0;
	for item in $Items.get_children():
		i += 1;
		item.position.y = y_default
		if(i<=3):
			(item as RigidBody2D).add_central_force((get_parent().get_body().global_position - item.global_position));
		else:
			item.set_visible(false)
	pass

func add_item(name, var item_texture):
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
	
	if ItemTextureMap.count.has(entry_name):
		ItemTextureMap.count[entry_name] += 1
	else:
		ItemTextureMap.count[entry_name] = 1


func hide():
	for item in $Items.get_children():
		item.set_visible(false);


func get_collected_items():
	return collectedItems

