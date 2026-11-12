class_name CollectibleProgressHud
extends Control

## Painel de progresso reutilizável para qualquer fase baseada em coleta.
##
## Com `set_items`, cada vaga mostra o ícone do item (apagado até ser coletado, para a
## criança saber o que procurar) e `mark_collected` acende a vaga com um "pulo".
## Sem ícones, o contador volta aos blocos simples de `set_progress`.
##
## `set_key_hint` mostra uma tecla desenhada acima do painel de instruções (ex.: o dash),
## "sendo apertada" de tempos em tempos.

const SLOT_SIZE := 38.0
const SLOT_GAP := 4.0
const ICON_SIZE := 32.0
## Margem direita/inferior das vagas dentro do painel do topo.
const SLOT_MARGIN := Vector2(12, 8)
const TOP_PANEL := Rect2(16, 16, 468, 92)
const POP_DURATION := 0.35
## Tecla de dica: altura, folga do texto, rótulo e ciclo da animação de "apertar" (s).
const KEY_HEIGHT := 34.0
const KEY_PADDING := 14.0
const KEY_FONT_SIZE := 18
const KEY_CAPTION := "DASH"
const KEY_PRESS_PERIOD := 1.2

var collected := 0
var total := 5
var tutorial_visible := true
var icons: Array[Texture2D] = []
var collected_flags: Array[bool] = []
var check := Color("#7fcf6a")
var ink := Color("#18252a")
var edge := Color("#8d9b77")
var paper := Color("#e9e4ca")
var active := Color("#e0b75f")
var empty := Color("#475453")

var _high_contrast := false
## Tempo restante do "pulo" de cada vaga recém-coletada.
var _pop_left: Dictionary = {}
var _key_hint := ""
var _key_time := 0.0


func set_tutorial_visible(value: bool) -> void:
	if tutorial_visible != value:
		tutorial_visible = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(queue_redraw)
	Settings.setting_changed.connect(_on_setting_changed)
	_apply_contrast(bool(Settings.get_setting("high_contrast", false)))


func _on_setting_changed(setting_name: String, value: Variant) -> void:
	if setting_name == "high_contrast":
		_apply_contrast(bool(value))


func _apply_contrast(enabled: bool) -> void:
	_high_contrast = enabled
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


## Um ícone por item, na ordem em que aparecem na fase.
func set_items(item_icons: Array[Texture2D]) -> void:
	icons = item_icons
	collected_flags.clear()
	collected_flags.resize(icons.size())
	collected_flags.fill(false)
	total = icons.size()
	queue_redraw()


func mark_collected(index: int) -> void:
	if index < 0 or index >= collected_flags.size() or collected_flags[index]:
		return
	collected_flags[index] = true
	collected = collected_flags.count(true)
	if not Settings.get_setting("reduced_motion", false):
		_pop_left[index] = POP_DURATION
	queue_redraw()


## Texto da tecla (ex.: "Shift"); vazio esconde a dica.
func set_key_hint(key_name: String) -> void:
	_key_hint = key_name
	_key_time = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if not _key_hint.is_empty() and tutorial_visible:
		_key_time += delta
		queue_redraw()
	if _pop_left.is_empty():
		return
	for index: int in _pop_left.keys():
		_pop_left[index] -= delta
		if _pop_left[index] <= 0.0:
			_pop_left.erase(index)
	queue_redraw()


func _draw() -> void:
	var view := get_viewport_rect().size
	_draw_panel(TOP_PANEL)
	if tutorial_visible:
		_draw_panel(Rect2(16, view.y - 96, minf(view.x - 32.0, 940.0), 78))
	if icons.is_empty():
		_draw_blocks()
	else:
		_draw_icon_slots()
	# Marcador de instrução na borda inferior.
	if tutorial_visible:
		draw_rect(Rect2(28, view.y - 80, 8, 8), active)
		draw_rect(Rect2(38, view.y - 76, 4, 4), paper)
		if not _key_hint.is_empty():
			_draw_key_hint(Vector2(16.0 + minf(view.x - 32.0, 940.0), view.y - 96))


## Etiqueta "DASH" + tecla, encostada no canto superior direito do painel de instruções.
func _draw_key_hint(anchor: Vector2) -> void:
	var font := get_theme_default_font()
	var key_width := font.get_string_size(_key_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, KEY_FONT_SIZE).x
	var caption_width := font.get_string_size(KEY_CAPTION, HORIZONTAL_ALIGNMENT_LEFT, -1, KEY_FONT_SIZE).x
	var key_size := Vector2(roundf(key_width + KEY_PADDING * 2.0), KEY_HEIGHT)
	var box := Rect2(
		anchor - Vector2(key_size.x + caption_width + KEY_PADDING * 3.0, KEY_HEIGHT + 18.0),
		Vector2(key_size.x + caption_width + KEY_PADDING * 3.0, KEY_HEIGHT + 12.0)
	)
	_draw_panel(box)
	var baseline := box.position.y + box.size.y / 2.0 + KEY_FONT_SIZE * 0.35
	draw_string(
		font, Vector2(box.position.x + KEY_PADDING, baseline), KEY_CAPTION,
		HORIZONTAL_ALIGNMENT_LEFT, -1, KEY_FONT_SIZE, active
	)
	# A tecla "afunda" 3 px por um instante a cada ciclo (parada com movimento reduzido).
	var pressed := (
		not bool(Settings.get_setting("reduced_motion", false))
		and fmod(_key_time, KEY_PRESS_PERIOD) > KEY_PRESS_PERIOD * 0.75
	)
	var press := 3.0 if pressed else 0.0
	var key := Rect2(
		Vector2(box.end.x - KEY_PADDING - key_size.x, box.position.y + 4.0), key_size - Vector2(0, 4)
	)
	draw_rect(Rect2(key.position + Vector2(0, 4), key.size), ink)  # lateral/sombra
	var top := Rect2(key.position + Vector2(0, press), key.size)
	draw_rect(top, edge)
	draw_rect(top.grow(-2), active if pressed else paper)
	draw_string(
		font, Vector2(top.position.x + KEY_PADDING, top.position.y + top.size.y / 2.0 + KEY_FONT_SIZE * 0.35),
		_key_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, KEY_FONT_SIZE, ink
	)


## Contador simples (sem ícones): pequenos blocos em grade.
func _draw_blocks() -> void:
	for index in range(total):
		var x := 308.0 + float(index) * 30.0
		draw_rect(Rect2(x, 73, 22, 16), edge)
		draw_rect(Rect2(x + 2, 75, 18, 12), active if index < collected else empty)
		draw_rect(Rect2(x + 6, 77, 4, 4), ink if index < collected else edge)


## Vagas com o sprite de cada item, alinhadas à direita do painel do topo.
func _draw_icon_slots() -> void:
	var count := icons.size()
	var row_width := count * SLOT_SIZE + (count - 1) * SLOT_GAP
	var origin := TOP_PANEL.end - SLOT_MARGIN - Vector2(row_width, SLOT_SIZE)
	for index in count:
		var slot := Rect2(origin + Vector2(index * (SLOT_SIZE + SLOT_GAP), 0), Vector2.ONE * SLOT_SIZE)
		var done := collected_flags[index]
		draw_rect(slot, active if done else edge)
		draw_rect(slot.grow(-2), ink.blend(Color(active, 0.35)) if done else ink)
		var icon := icons[index]
		if icon == null:
			continue
		# "Pulo" ao coletar: cresce e volta ao tamanho normal.
		var pop: float = _pop_left.get(index, 0.0) / POP_DURATION
		var icon_size := ICON_SIZE * (1.0 + 0.35 * sin(pop * PI))
		var icon_rect := Rect2(slot.get_center() - Vector2.ONE * icon_size / 2.0, Vector2.ONE * icon_size)
		# Ainda não coletado: ícone apagado, só para reconhecer o que procurar.
		var tint := Color.WHITE if done else (Color(0.5, 0.5, 0.5) if _high_contrast else Color(0.32, 0.38, 0.4))
		draw_texture_rect(icon, icon_rect, false, tint)
		if done:
			_draw_check(slot.end - Vector2(11, 9))


## Pequeno "✓" em pixels no canto da vaga.
func _draw_check(at: Vector2) -> void:
	var points := [Vector2(0, 3), Vector2(1, 4), Vector2(2, 5), Vector2(3, 4), Vector2(4, 3), Vector2(5, 2), Vector2(6, 1)]
	for point: Vector2 in points:
		draw_rect(Rect2(at + point + Vector2(1, 1), Vector2(2, 2)), ink)
	for point: Vector2 in points:
		draw_rect(Rect2(at + point, Vector2(2, 2)), check)


func _draw_panel(rect: Rect2) -> void:
	if not _high_contrast:
		draw_style_box(get_theme_stylebox("panel", "PanelContainer"), rect)
		return
	draw_rect(rect, ink)
	draw_rect(rect, edge, false, 2.0)
	draw_rect(Rect2(rect.position + Vector2(4, 4), Vector2(rect.size.x - 8, 2)), paper)
	# Cantos escalonados, desenhados em pixels inteiros.
	draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(4, 4)), active)
	draw_rect(Rect2(rect.end - Vector2(6, 6), Vector2(4, 4)), active)
