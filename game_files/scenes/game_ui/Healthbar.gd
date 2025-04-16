extends TextureRect

var max_health = 5.0
#func _ready():
#	self.set_texture(load("res://assets/Images/gameUI/battery_full.png"))

func _damage(health : float = 5.0):
	var red
	var green
	if health > max_health/2:
		red = 1.0 - (health - (max_health/2))/max_health
		green = 1.0
	else:
		red = 1.0
		green = health/max_health
	
	for i in range(1, 6):
		if i > health:
			get_node("Health" + str(i)).set_modulate(Color(0,0,0,0))
		else:
			get_node("Health" + str(i)).set_modulate(Color(red, green, 0, 1))
	
#	if i == 2 :
#		self.set_texture(load("res://assets/Images/gameUI/battery_med.png"))
#	if i == 1 :
#		self.set_texture(load("res://assets/Images/gameUI/battery_low.png"))
#	if i == 0 :
#		self.set_texture(load("res://assets/Images/gameUI/no_battery.png"))
