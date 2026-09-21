extends Control
## Painel de progresso reutilizável para qualquer fase baseada em coleta.
class_name CollectibleProgressHud

var ink := Color("#18252a")
var edge := Color("#8d9b77")
var paper := Color("#e9e4ca")
var active := Color("#e0b75f")
var empty := Color("#475453")

var collected := 0
var total := 5

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(queue_redraw)
	Settings.setting_changed.connect(_on_setting_changed)
	_apply_contrast(bool(Settings.get_setting("high_contrast", false)))

func _on_setting_changed(setting_name: String, value: Variant) -> void:
	if setting_name == "high_contrast":
		_apply_contrast(bool(value))

func _apply_contrast(enabled: bool) -> void:
	if enabled:
		ink = Color.BLACK
		edge = Color.WHITE
		paper = Color.WHITE
		active = Color("#ffff00")
		empty = Color("#4d4d4d")
	else:
		ink = Color("#18252a")
		edge = Color("#8d9b77")
		paper = Color("#e9e4ca")
		active = Color("#e0b75f")
		empty = Color("#475453")
	queue_redraw()

func set_progress(value: int, maximum: int) -> void:
	collected = value
	total = maximum
	queue_redraw()

func _draw() -> void:
	var view := get_viewport_rect().size
	_draw_panel(Rect2(16, 16, 468, 92))
	_draw_panel(Rect2(16, view.y - 96, minf(view.x - 32.0, 940.0), 78))
	# Pequenos blocos em grade substituem ícones ornamentais no contador.
	for index in range(total):
		var x := 308.0 + float(index) * 30.0
		draw_rect(Rect2(x, 73, 22, 16), edge)
		draw_rect(Rect2(x + 2, 75, 18, 12), active if index < collected else empty)
		draw_rect(Rect2(x + 6, 77, 4, 4), ink if index < collected else edge)
	# Marcador de instrução na borda inferior.
	draw_rect(Rect2(28, view.y - 80, 8, 8), active)
	draw_rect(Rect2(38, view.y - 76, 4, 4), paper)

func _draw_panel(rect: Rect2) -> void:
	draw_rect(rect, ink)
	draw_rect(rect, edge, false, 2.0)
	draw_rect(Rect2(rect.position + Vector2(4, 4), Vector2(rect.size.x - 8, 2)), paper)
	# Cantos escalonados, desenhados em pixels inteiros.
	draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(4, 4)), active)
	draw_rect(Rect2(rect.end - Vector2(6, 6), Vector2(4, 4)), active)
