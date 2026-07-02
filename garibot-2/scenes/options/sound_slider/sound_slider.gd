extends HSlider

@export_enum("Master","Music","Sfx")  var bus_name : String
var bus_index:int
func _ready() -> void:
	bus_index = AudioServer.get_bus_index(bus_name)
	value_changed.connect(_on_volume_changed)
	value =  db_to_linear(AudioServer.get_bus_volume_db(bus_index))*100
	pass # Replace with function body.

func _on_volume_changed(value : float) -> void:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value/100))
		pass
