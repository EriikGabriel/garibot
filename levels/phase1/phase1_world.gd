@tool
extends Node2D
class_name Phase1World

## Plano do jogo (casas, árvores, rio). O fundo em parallax fica em Background.
## Blockout: As plataformas e os marcos editáveis ficam em Blockout/Flow.
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
	# O céu e os cenários distantes ficam no Background (parallax em pixel art).
	# Casas e árvores em pixel art ficam no nó Frente (levels/phase1/front).
	# Rio abaixo da rota; cair devolve o jogador à margem, sem perder coletas.
	draw_rect(Rect2(3580, 130, 1010, 440), Color("#494b38").lerp(Color("#4ca6ad"), clean))
	for x in range(3590, 4580, 65):
		var wave := sin(_water_time * 1.5 + float(x) * 0.02) * 3.0
		draw_line(Vector2(x, 142 + wave), Vector2(x + 35, 142 + wave), Color("#91bab3"), 2.0)


func _label(at: Vector2, text: String, color: Color, font_size: int) -> void:
	draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
