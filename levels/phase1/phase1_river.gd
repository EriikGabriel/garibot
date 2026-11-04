@tool
class_name Phase1River
extends Node2D

## Água do rio abaixo das pedras. Fica mais limpa conforme os REEE são coletados.

const WATER_RECT := Rect2(3580, 130, 1010, 440)
const DIRTY_COLOR := Color("#494b38")
const CLEAN_COLOR := Color("#4ca6ad")
const WAVE_COLOR := Color("#91bab3")

var _clean := 0.0
var _time := 0.0


func _ready() -> void:
	RestorationProgress.connect_to(self, _on_progress)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(WATER_RECT, DIRTY_COLOR.lerp(CLEAN_COLOR, _clean))
	var surface := WATER_RECT.position.y + 12.0
	for x in range(int(WATER_RECT.position.x) + 10, int(WATER_RECT.end.x) - 10, 65):
		var wave := sin(_time * 1.5 + x * 0.02) * 3.0
		draw_line(Vector2(x, surface + wave), Vector2(x + 35, surface + wave), WAVE_COLOR, 2.0)


func _on_progress(shown: float) -> void:
	_clean = shown
