extends CanvasLayer

## Filtro global de brilho aplicado depois do mundo e de toda a interface.

@onready var filter_material := ($Filter as ColorRect).material as ShaderMaterial


func _ready() -> void:
	Settings.setting_changed.connect(_on_setting_changed)
	_apply_brightness(float(Settings.get_setting("brightness", 1.0)))


func _on_setting_changed(setting_name: String, value: Variant) -> void:
	if setting_name == "brightness":
		_apply_brightness(float(value))


func _apply_brightness(value: float) -> void:
	if filter_material != null:
		filter_material.set_shader_parameter("brightness", clampf(value, 0.5, 1.25))
