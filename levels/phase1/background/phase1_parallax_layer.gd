@tool
extends Node2D
class_name Phase1ParallaxLayer

## Camada do fundo. A arte usa o espaço u = x_mundo * scroll_factor, então a
## posição da camada é centro_da_câmera * (1 - scroll_factor).
@export var scroll_factor := Vector2(0.5, 0.5)
## Deriva automática em px/s (nuvens). Exige Sprite2D com region e repeat.
@export var drift_speed := 0.0
@export var drift_wrap := 640.0

var _drift := 0.0

func follow(center: Vector2, delta: float, animate: bool) -> void:
	position = center * (Vector2.ONE - scroll_factor)
	if drift_speed == 0.0:
		return
	if animate:
		_drift = fposmod(_drift + drift_speed * delta, drift_wrap)
	for child in get_children():
		if child is Sprite2D and child.region_enabled:
			child.region_rect.position.x = roundf(fposmod(-_drift, drift_wrap))
