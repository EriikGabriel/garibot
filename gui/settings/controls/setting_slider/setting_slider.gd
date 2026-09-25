extends HBoxContainer
## Controle reutilizável que exibe um Rótulo + HSlider vinculado a uma
## configuração do autoload Settings (via settings_key).

signal slider_changed(key: String, value: float)

@export var label_text: String = "Setting"
@export var settings_key: String = ""
@export var min_value: float = 0.0
@export var max_value: float = 100.0
@export var step_value: float = 1.0
@export var value_ratio: float = 1.0   # converte o valor interno para a UI

@onready var label: Label = %Label
@onready var slider: HSlider = %Slider
@onready var value_label: Label = %ValueLabel

func _ready() -> void:
	label.text = label_text
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step_value
	# Inicializa de acordo com a configuração atual (dispara _on_slider_value_changed).
	slider.value_changed.connect(_on_slider_value_changed)
	Settings.setting_changed.connect(_on_setting_changed)
	slider.value = _to_ui(Settings.get_setting(settings_key, min_value))

func _to_ui(value: Variant) -> float:
	return float(value) * value_ratio

func _to_setting(value: float) -> float:
	return value / value_ratio

func _on_slider_value_changed(ui_value: float) -> void:
	var setting_value := _to_setting(ui_value)
	Settings.set_setting(settings_key, setting_value)
	value_label.text = str(int(ui_value))
	slider_changed.emit(settings_key, setting_value)

func set_value(value: Variant) -> void:
	slider.value = _to_ui(value)

func _on_setting_changed(changed_key: String, value: Variant) -> void:
	if changed_key == settings_key:
		set_value(value)
