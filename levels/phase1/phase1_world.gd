@tool
extends Node2D
class_name Phase1World

## Fundo do blockout. As plataformas e os marcos editáveis ficam em Blockout/Flow.
@export var reee_total := 5
var reee_collected := 0
var _water_time := 0.0

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		_water_time += delta
	queue_redraw()

func register_reee() -> void:
	reee_collected += 1
	queue_redraw()

func pollution_ratio() -> float:
	return clampf(float(reee_collected) / maxi(reee_total, 1), 0.0, 1.0)

func _draw() -> void:
	var clean := pollution_ratio()
	draw_rect(Rect2(-900, -900, 7000, 1600), Color("#434e55").lerp(Color("#9bbbc1"), clean))
	# Base, bairro, parque, rio e praça têm silhuetas distintas já no protótipo.
	draw_rect(Rect2(-180, -170, 370, 210), Color("#376d70"))
	draw_rect(Rect2(-100, -115, 90, 155), Color("#203e49"))
	for x in [1190, 1510, 1830, 2120]:
		_draw_house(Vector2(x, 40), clean)
	for x in [2340, 2630, 2960, 3300, 4770, 5180]:
		_draw_tree(Vector2(x, 40), clean)
	# Rio abaixo da rota; cair devolve o jogador à margem, sem perder coletas.
	draw_rect(Rect2(3580, 130, 1010, 440), Color("#494b38").lerp(Color("#4ca6ad"), clean))
	for x in range(3590, 4580, 65):
		var wave := sin(_water_time * 1.5 + float(x) * 0.02) * 3.0
		draw_line(Vector2(x, 142 + wave), Vector2(x + 35, 142 + wave), Color("#91bab3"), 2.0)
	# Recompensa legível: água, folhas, flores e bandeira recuperam a cor.
	for x in range(400, 5300, 85):
		if x > 3550 and x < 4600:
			continue
		var grass := Color("#8a7a52").lerp(Color("#66a86e"), clean)
		draw_line(Vector2(x, 40), Vector2(x - 5, 26), grass, 3.0)
		if clean >= 0.4:
			draw_circle(Vector2(x - 5, 23), 4.0, Color("#efd47d"))
	draw_line(Vector2(5020, 40), Vector2(5020, -150), Color("#c6d2c3"), 5)
	draw_rect(Rect2(5020, -150, 115, 60), Color("#67716b").lerp(Color("#78b993"), clean))
	# Sinalização dos desafios; plataformas são retângulos, REEE são círculos.
	for point in [Vector2(685, -35), Vector2(2480, -55), Vector2(3710, -35)]:
		_label(point, "!", Color("#f1d985"), 28)

func _label(at: Vector2, text: String, color: Color, font_size: int) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw_house(at: Vector2, clean: float) -> void:
	draw_rect(Rect2(at + Vector2(0, -210), Vector2(245, 210)), Color("#675f59").lerp(Color("#a18e74"), clean))
	draw_colored_polygon(PackedVector2Array([at + Vector2(-12, -210), at + Vector2(122, -290), at + Vector2(257, -210)]), Color("#554f4a"))
	draw_rect(Rect2(at + Vector2(30, -95), Vector2(52, 95)), Color("#3b4b51"))
	draw_rect(Rect2(at + Vector2(140, -155), Vector2(60, 65)), Color("#847d60").lerp(Color("#c4d6b3"), clean))

func _draw_tree(at: Vector2, clean: float) -> void:
	draw_rect(Rect2(at + Vector2(-7, -160), Vector2(14, 160)), Color("#625c48"))
	var leaf := Color("#827749").lerp(Color("#5d995f"), clean)
	draw_circle(at + Vector2(-28, -165), 45, leaf)
	draw_circle(at + Vector2(24, -190), 55, leaf.lightened(0.08))
