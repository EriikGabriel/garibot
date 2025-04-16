extends Node

var items = {
	"celular" : {"name": "ITEM_CELLPHONE","texture": load("res://assets/Images/Collectibles/celular.png"), 
	"type":"REEE", "blaster":"Elétrica", "count":0,
	"description":"""ITEM_DESCRIPTION_CELLPHONE""",
	"recyclabe": true,},
	
	"monitor" :  {"name": "ITEM_COMPUTER", "texture": load("res://assets/Images/Collectibles/monitor.png"), 
	"type":"REEE", "blaster":"Elétrica", "count":0,
	"description":"""ITEM_DESCRIPTION_COMPUTER""",
	"recyclabe": true,},
	
	"tv" : {"name": "ITEM_TV", "texture": load("res://assets/Images/Collectibles/tv.png"), 
	"type":"REEE", "blaster":"Elétrica", "count":0,
	"description":"""ITEM_DESCRIPTION_TV""",
	"recyclabe": true,},
	
	"impressora" : {"name": "ITEM_PRINTER", "texture": load("res://assets/Images/Collectibles/impressora.png"), 
	"type":"REEE", "blaster":"Elétrica", "count":0,
	"description":"""ITEM_DESCRIPTION_PRINTER""",
	"recyclabe": false,},
	
	"furadeira" : {"name": "ITEM_DRILL", "texture": load("res://assets/Images/Collectibles/furadeira.png"), 
	"type":"REEE", "blaster":"Elétrica", "count":0,
	"description":"""ITEM_DESCRIPTION_DRILL""",
	"recyclabe": false,},
	
	"fogao" : {"name": "ITEM_STOVE", "texture": load("res://assets/Images/Collectibles/fogao.png"), 
	"type":"REEE", "blaster":"Elétrica", "count":0,
	"description":"""ITEM_DESCRIPTION_STOVE""",
	"recyclabe": false,},
	
	"geladeira" : {"name": "ITEM_FRIDGE", "texture": load("res://assets/Images/Collectibles/geladeira.png"), 
	"type":"REEE", "blaster":"Elétrica", "count":0,
	"description":"""ITEM_DESCRIPTION_FRIDGE""",
	"recyclabe": false,},
	
	"microondas" : {"name": "ITEM_MICROWAVE", "texture": load("res://assets/Images/Collectibles/microondas.png"), 
	"type":"REEE", "blaster":"Elétrica", "count":0,
	"description":"""ITEM_DESCRIPTION_MICROWAVE""",
	"recyclabe": true,},
	
	"radio" : {"name": "ITEM_RADIO", "texture": load("res://assets/Images/Collectibles/radio.png"), 
	"type":"REEE", "blaster":"Elétrica", "count":0,
	"description":"""ITEM_DESCRIPTION_RADIO""",
	"recyclabe": false,},
	
	"bateria" : {"name": "ITEM_BATTERY", "texture": load("res://assets/Images/Collectibles/battery.png"), 
	"type":"REEE", "blaster":"Elétrica", "count":0,
	"description":"""ITEM_DESCRIPTION_BATTERY""",
	"recyclabe": false,},
	
	"agua" : {"name": "ITEM_PLASTIC_BOTTLE", "texture": load("res://assets/Images/Collectibles/agua.png"), 
	"type":"", "blaster":"", "count":0,
	"description":"""ITEM_DESCRIPTION_PLASTIC_BOTTLE""",
	"recyclabe": false,},
	
	"garrafa" : {"name": "ITEM_BOTTLE", "texture": load("res://assets/Images/Collectibles/garrafa.png"), 
	"type":"", "blaster":"", "count":0,
	"description":"""ITEM_DESCRIPTION_BOTTLE""",
	"recyclabe": false,},
	
	"jornal" : {"name": "ITEM_NEWSPAPER", "texture": load("res://assets/Images/Collectibles/jornal.png"), 
	"type":"", "blaster":"", "count":0,
	"description":"""ITEM_DESCRIPTION_NEWSPAPER""",
	"recyclabe": false,},
	
	"melancia" : {"name": "ITEM_WATERMELON", "texture": load("res://assets/Images/Collectibles/melancia.png"), 
	"type":"", "blaster":"", "count":0,
	"description":"""ITEM_DESCRIPTION_WATERMELON""",
	"recyclabe": false,},
	
	"refrigerante" : {"name": "ITEM_SODA", "texture": load("res://assets/Images/Collectibles/refri.png"), 
	"type":"", "blaster":"", "count":0,
	"description":"""ITEM_DESCRIPTION_SODA""",
	"recyclabe": false,},
	
	"sacola" : {"name": "ITEM_PLASTIC_BAG", "texture": load("res://assets/Images/Collectibles/sacola.png"), 
	"type":"", "blaster":"", "count":0,
	"description":"""ITEM_DESCRIPTION_PLASTIC_BAG""",
	"recyclabe": false,},
}

onready var textures = {
	"celular" : load("res://assets/Images/Collectibles/celular.png"),
	"monitor" : load("res://assets/Images/Collectibles/monitor.png"),
	"tv" : load("res://assets/Images/Collectibles/tv.png"),
	"impressora" : load("res://assets/Images/Collectibles/impressora.png"),
	"furadeira" : load("res://assets/Images/Collectibles/furadeira.png"),
	"fogao" : load("res://assets/Images/Collectibles/fogao.png"),
	"geladeira" : load("res://assets/Images/Collectibles/geladeira.png"),
	"microondas" : load("res://assets/Images/Collectibles/microondas.png"),
	"agua" : load("res://assets/Images/Collectibles/agua.png"),
	"garrafa" : load("res://assets/Images/Collectibles/garrafa.png"),
	"jornal" : load("res://assets/Images/Collectibles/jornal.png"),
	"melancia" : load("res://assets/Images/Collectibles/melancia.png"),
	"refrigerante" : load("res://assets/Images/Collectibles/refri.png"),
	"sacola": load("res://assets/Images/Collectibles/sacola.png"),
	"radio": load("res://assets/Images/Collectibles/radio.png"),
	"bateria": load("res://assets/Images/Collectibles/battery.png"),
	}
onready var textures_d = {
	"ITEM_CELLPHONE" : load("res://assets/Images/Collectibles/celular_d.png"),
	"ITEM_COMPUTER" : load("res://assets/Images/Collectibles/monitor_d.png"),
	"ITEM_TV" : load("res://assets/Images/Collectibles/tv_d.png"),
	"ITEM_MICROWAVE" : load("res://assets/Images/Collectibles/microondas_d.png")
	}

onready var textures_m = {
	"ITEM_CELLPHONE" : load("res://assets/Images/Collectibles/celular_m.png"),
	"ITEM_COMPUTER" : load("res://assets/Images/Collectibles/monitor_m.png"),
	"ITEM_TV" : load("res://assets/Images/Collectibles/tv_m.png"),
	"ITEM_MICROWAVE" : load("res://assets/Images/Collectibles/microondas_m.png")	
}

var types = {
	"celular" : "REEE",
	"monitor" : "REEE",
	"tv" : "REEE",
	"impressora" : "REEE",
	"furadeira" : "REEE",
	"fogao" : "REEE",
	"geladeira" : "REEE",
	"microondas" : "REEE",
	"radio" : "REEE",
	"bateria" : "REEE",
	"agua" : "NORMAL",
	"garrafa" : "NORMAL",
	"jornal" : "NORMAL",
	"melancia" : "NORMAL",
	"sacola": "NORMAL",
	"refrigerante": "NORMAL",
	"banana" : "NORMAL",
}

var blasters = {
	"celular" : "Elétrica",
	"tv" : "Elétrica",
	"monitor" : "Elétrica",
	"impressora" : "Elétrica",
	"furadeira" : "Elétrica",
	"fogao" : "Elétrica",
	"geladeira" : "Elétrica",
	"microondas" : "Elétrica",
	"radio" : "Elétrica",
	"bateria" : "Elétrica",
}

var count = {
	"celular" : 0,
	"monitor" : 0,
	"tv" : 0,
	"impressora" : 0,
	"furadeira" : 0,
	"fogao" : 0,
	"geladeira" : 0,
	"microondas" : 0,
	"radio" : 0,
	"bateria" : 0,
	"agua" : 0,
	"garrafa" : 0,
	"jornal" : 0,
	"melancia" : 0,
	"refrigerante" : 0,
	"sacola": 0,
	}

func increase_count(item):
	if count.has(item):
		count[item] += 1
	else:
		count[item] = 1
	
	if items.has(item):
		items[item]["count"] += 1
	else:
		items[item] = {"count":1}


#TODO
func get(_name : String):
	if !items.keys().has(_name):
		return null
	return items[_name]
	#{"name":"TODO", "texture":"TODO", "type":"TODO", "description":"TODO","blaster":"TODO"}

var recyclabe_items = [
	"celular",
	"monitor",
	"tv",
	"microondas",
	]
