class_name BackgroundLayer
extends Node2D

## Camada de parallax. A arte usa o espaço u = x_mundo * scroll_factor; assim a
## camada fica em centro_da_câmera * (1 - scroll_factor).

@export var scroll_factor := Vector2(0.5, 0.5)
## Deriva automática em px/s (nuvens). Exige Sprite2D filho com region e repeat.
@export var drift_speed := 0.0
@export var drift_wrap := 640.0

var _drift := 0.0


func _ready() -> void:
	process_priority = 100  # depois da câmera


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	position = camera.get_screen_center_position() * (Vector2.ONE - scroll_factor)
	if drift_speed == 0.0 or Settings.get_setting("reduced_motion", false):
		return
	_drift = fposmod(_drift + drift_speed * delta, drift_wrap)
	for child in get_children():
		if child is Sprite2D and child.region_enabled:
			child.region_rect.position.x = roundf(fposmod(-_drift, drift_wrap))
