extends Node

var dicionario_item = {
	"agua" : 0,
	"garrafa" : 0,
	"jornal" : 0,
	"melancia" : 0,
	"refri" : 0,
	"sacola" : 0
}

var last_stage_number
var mobile_control_flag = false
var people_collect = 0

var mobile_control_node = null
var open_door = false

func add_item_collect( var item) :
	if dicionario_item.has(item) :
		dicionario_item[item] += 1

func remove_item_collect(var item) :
	#print(item)
	#print(dicionario_item.has(item))
	#print(dicionario_item[item])
	if dicionario_item.has(item) and dicionario_item[item] > 0 :
		#print(dicionario_item)
		dicionario_item[item] -= 1
		#print(dicionario_item[item])
		
func get_name_item_collect() :
	var lista = []
	for name in dicionario_item :
		if dicionario_item[name] > 0 :
			lista.append(name)
	#print("lista:")
	#print(lista)
	return lista

func get_qtd_item() :
	var qtd = 0
	for name in dicionario_item :
		qtd = qtd + dicionario_item[name]
	
	return qtd
	
func add_people_collect(qtd):
	people_collect = people_collect + qtd
	
func get_people_collect():
	return people_collect
func reset_people_collect():
	people_collect = 0
