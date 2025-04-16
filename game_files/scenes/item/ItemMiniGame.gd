tool
extends Area2D

var float_direction = 1
var float_amount
var item
onready var value_bar = get_tree().get_nodes_in_group("value_bar").front()


export	(String,"agua","garrafa","jornal",
		"melancia","refri","sacola") var itemName

var textures = {
	"agua" : load("res://assets/Images/Collectibles/agua.png"),
	"garrafa" : load("res://assets/Images/Collectibles/garrafa.png"),
	"jornal" : load("res://assets/Images/Collectibles/jornal.png"),
	"melancia" : load("res://assets/Images/Collectibles/melancia.png"),
	"refri" : load("res://assets/Images/Collectibles/refri.png"),
	"sacola": load("res://assets/Images/Collectibles/sacola.png")	
	}

var dictonary = {
	"agua" : 4,
	"garrafa" : 3,
	"jornal" : 1,
	"melancia" : 2,
	"refri" : 0,
	"sacola" : 4,
}

var color_border = {
	"agua" : Color.red,
	"garrafa" : Color.green,
	"jornal" : Color.blue,
	"melancia" : Color.brown,
	"refri" : Color.yellow,
	"sacola" : Color.red,		
}
func _ready():
	change_item(itemName)
	var _error = $SFX.connect("finished", self, "_on_sfx_finished")
	
	
	add_to_group("item")
	pass

func _physics_process(_delta):
	self.position.y = self.position.y + 0.75
	
	if position.y > 400 :
		queue_free()
	

func _on_Item_body_entered(body):
	if body.name == "Player":
		stop_signal()
		collect(body)
	
func collect( var player ):
	visible = false
	if player.typelixeira == dictonary[item] :
		$SFX.play()
		value_bar.value += 1
	else :
		pass

	#player.get_node("FollowItems").setCollectedItem(self.item)

func _on_sfx_finished():
	queue_free()

func change_item( var name : String ):
	if textures.has(name):
		item = name
		$Sprite.set_texture(textures.get(name))
		$Sprite.material = $Sprite.material.duplicate()
		$Sprite.material.set_shader_param("outLineColor",color_border.get(name))

func stop_signal():
	if self.is_connected("body_entered", self, "_on_Item_body_entered"):
			self.disconnect("body_entered", self, "_on_Item_body_entered")

func _on_Timer_timeout():
	self.monitoring = true
