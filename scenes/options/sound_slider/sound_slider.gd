extends HSlider

## Slider simples para um bus do AudioServer.
@export_enum("Master", "Music", "Sfx") var bus_name: String

var bus_index: int = -1

func _ready() -> void:
	bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("SoundSlider: bus de áudio não encontrado: %s" % bus_name)
		set_process(false)
		return

	value_changed.connect(_on_volume_changed)
	value = db_to_linear(AudioServer.get_bus_volume_db(bus_index)) * 100.0

func _on_volume_changed(slider_value: float) -> void:
	if bus_index == -1:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(slider_value / 100.0))
