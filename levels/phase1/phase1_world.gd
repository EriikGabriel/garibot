extends Node2D
class_name Phase1World

## Cenário desenhado por código para manter a fase jogável mesmo sem os sprites
## finais. A paleta muda gradualmente conforme Garibot recolhe REEE.
var reee_collected: int = 0
var _smoke_time := 0.0

const SKY := Color("#73787a")
const SKY_POLLUTED := Color("#464b4e")
const BRICK := Color("#6d6862")
const ROAD := Color("#4a4c4b")
const GRASS := Color("#657052")
const DEAD_GRASS := Color("#867c4b")
const RIVER := Color("#4f7070")

func _ready() -> void:
	add_to_group("phase1_level")
	queue_redraw()

func _process(delta: float) -> void:
	_smoke_time += delta
	queue_redraw()

func register_reee() -> void:
	reee_collected += 1
	queue_redraw()

func pollution_ratio() -> float:
	return clampf(float(reee_collected) / 5.0, 0.0, 1.0)

func _draw() -> void:
	# A limpeza reduz o chumbo visual e recupera gradualmente a vegetação.
	var pollution := 1.0 - pollution_ratio()
	var sky := SKY.lerp(SKY_POLLUTED, pollution)
	draw_rect(Rect2(-1000, -520, 4400, 560), sky)

	# Fábrica antiga e fumaça densa ao fundo.
	draw_rect(Rect2(1390, -220, 470, 260), Color("#34383a"))
	draw_rect(Rect2(1450, -360, 52, 145), Color("#292d2f"))
	draw_rect(Rect2(1650, -430, 66, 215), Color("#292d2f"))
	draw_rect(Rect2(1785, -315, 45, 100), Color("#292d2f"))
	for chimney in [Vector2(1475, -365), Vector2(1680, -435), Vector2(1807, -320)]:
		for puff in range(4):
			var drift: float = sin(_smoke_time * 0.35 + puff) * 20.0 + puff * 34.0
			var p: Vector2 = chimney + Vector2(drift, -40.0 - puff * 35.0)
			draw_circle(p, 38.0 + puff * 8.0, Color(0.12, 0.14, 0.15, (0.58 - puff * 0.08) * pollution))

	# Casas desgastadas e rua de paralelepípedos.
	# for house in [Vector2(-260, -75), Vector2(380, -95), Vector2(1020, -90)]:
	# 	_draw_house(house)
	draw_rect(Rect2(-900, 40, 3600, 260), ROAD)
	for x in range(-880, 2600, 42):
		draw_line(Vector2(x, 42), Vector2(x + 15, 300), Color(0.18, 0.19, 0.18, 0.45), 1.0)
	for y in range(70, 300, 32):
		draw_line(Vector2(-900, y), Vector2(2600, y), Color(0.2, 0.2, 0.19, 0.35), 1.0)

	# Parque, rio e vegetação em transição: verde no início, amarelada no fim.
	draw_rect(Rect2(720, -10, 640, 48), RIVER.lerp(Color("#354344"), pollution))
	draw_rect(Rect2(720, 28, 640, 12), Color("#302f2d"))
	# Parquinho interditado, cercado pela água escura do rio.
	# draw_line(Vector2(865, 32), Vector2(865, -42), Color("#665c4d"), 5.0)
	# draw_line(Vector2(970, 32), Vector2(970, -42), Color("#665c4d"), 5.0)
	# draw_line(Vector2(865, -42), Vector2(970, -42), Color("#665c4d"), 5.0)
	# draw_line(Vector2(885, -8), Vector2(915, 22), Color("#8a765a"), 3.0)
	# draw_line(Vector2(945, -8), Vector2(915, 22), Color("#8a765a"), 3.0)
	for tree in [Vector2(650, 24), Vector2(780, 20), Vector2(1230, 20), Vector2(1320, 22)]:
		_draw_tree(tree, pollution * clampf((tree.x - 550.0) / 700.0, 0.25, 1.0))
	for x in range(700, 1360, 70):
		var grass_color := GRASS.lerp(DEAD_GRASS, pollution * clampf((x - 600.0) / 700.0, 0.2, 1.0))
		draw_line(Vector2(x, 38), Vector2(x - 4, 28), grass_color, 3.0)
		draw_line(Vector2(x + 5, 38), Vector2(x + 10, 30), grass_color, 2.0)

	# Base recicladora limpa, contrastando com a vila.
	# draw_rect(Rect2(-160, -145, 250, 145), Color("#356b69"))
	# draw_rect(Rect2(-135, -125, 62, 52), Color("#a5c2b4"))
	# draw_string(ThemeDB.fallback_font, Vector2(-120, -95), "BASE", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#d8ead5"))
	# draw_circle(Vector2(45, -160), 10.0 + sin(_smoke_time * 5.0) * 3.0, Color("#f2c95c"))

func _draw_house(origin: Vector2) -> void:
	draw_rect(Rect2(origin, Vector2(230, 115)), BRICK)
	draw_colored_polygon(PackedVector2Array([origin + Vector2(-14, 0), origin + Vector2(112, -78), origin + Vector2(244, 0)]), Color("#403e3b"))
	draw_rect(Rect2(origin + Vector2(32, 35), Vector2(43, 80)), Color("#3e494b"))
	draw_rect(Rect2(origin + Vector2(140, 35), Vector2(48, 38)), Color("#9c8c65"))

func _draw_tree(origin: Vector2, pollution: float) -> void:
	var leaf := Color("#68754b").lerp(Color("#81723f"), pollution)
	draw_rect(Rect2(origin + Vector2(-6, -90), Vector2(12, 92)), Color("#494237"))
	draw_line(origin + Vector2(0, -58), origin + Vector2(-30, -96), Color("#494237"), 5.0)
	draw_line(origin + Vector2(2, -49), origin + Vector2(34, -83), Color("#494237"), 4.0)
	draw_circle(origin + Vector2(-25, -105), 32.0, leaf)
	draw_circle(origin + Vector2(18, -110), 38.0, leaf.darkened(0.08))
