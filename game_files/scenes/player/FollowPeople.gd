extends Node

var amount = 0
export var enabled: bool = false
export var y_default = 600.0
export var start_people = 0

#primeiras 5 posições são meninos, as 5 posições seguintes são meninas e as outras 5 são mulheres
var qtd_boy = 0
var qtd_girl = 5
var qtd_woman = 10

const SPEED = 10
const MAX_PEOPLE = 16

func _process(delta):
	if enabled:
		_update_position(delta)

func _update_position(delta):
	
	var side = -1 + (int(get_parent().get_body().scale.x < 0)*2)
	
	var visible_itens = []
	for item in $Items.get_children():
		if item.is_visible_in_tree():
			visible_itens.push_back(item) 
	
	
	for i in range(len(visible_itens)):
		var item = visible_itens[i]
		
		item.global_position.y = y_default
		
		if (i <= MAX_PEOPLE):
			var player_orientation = get_orientation()
			item.scale.x = player_orientation
			
			item.global_position.x = interpolate(item.global_position.x,
			self.global_position.x -30*player_orientation + side*(i*40+12), 
			(delta*SPEED*(MAX_PEOPLE-i+1)/MAX_PEOPLE)
			)
		else:
			item.set_visible(false)


func interpolate(A, B, t):
	return A * (1 - t) + B * t

# Nova funçao ready, assim consigo fazer pessoas diferentes aparecerem
func ready_set_person(Body_type, shirt_color, hair_color):
	enabled = true
	for _i in range(start_people):
		add_person(Body_type, shirt_color, hair_color)	


func add_person(Body_type, shirt_color, hair_color):
	var item = null
	if amount < MAX_PEOPLE:
		if(Body_type == 'boy'):
			item = $Items.get_children()[qtd_boy]
			qtd_boy += 1
		elif(Body_type == 'girl'):
			item = $Items.get_children()[qtd_girl]
			qtd_girl += 1
		elif(Body_type == 'woman'):
			item = $Items.get_children()[qtd_woman]
			qtd_woman += 1
		update_item_colors(item, shirt_color, hair_color)
		
		item.visible = true
		item.global_position.x = self.global_position.x 
		
		amount += 1
		get_tree().call_group("convencivel", "update_seguidores", amount)

func hide():
	for item in $Items.get_children():
		item.set_visible(false);

func get_orientation():
	return self.get_parent().get_orientation()

func get_gravity():
	return self.get_parent().is_gravity_correct()

func update_item_colors(item, shirt_color, hair_color):
	item.get_child(0).shirt_color = shirt_color
	item.get_child(0).hair_color = hair_color
	item.get_child(0).update_colors()
