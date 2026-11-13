class_name BossHealthBar
extends Control

## Barra do chefe no topo da tela, em segmentos (um por "golpe" necessário).
## Sem sprites: tudo desenhado aqui. Cores seguem o HUD da coleta e o alto contraste.

const PANEL_SIZE := Vector2(420, 70)
const TOP_MARGIN := 16.0
const SEGMENT_GAP := 6.0
const SEGMENT_HEIGHT := 16.0

@export var title := "NUVEM DE POLUIÇÃO"
## Texto embaixo da barra; `%d/%d` recebe progresso e total.
@export var progress_format := "Plantas curativas: %d/%d"
@export var filled_color := Color("#7fcf6a")
@export var empty_color := Color("#5b5649")

var value := 0
var maximum := 3

var _ink := Color("#18252a")
var _edge := Color("#8d9b77")
var _paper := Color("#e9e4ca")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	get_viewport().size_changed.connect(queue_redraw)
	Settings.setting_changed.connect(_on_setting_changed)
	_apply_contrast(bool(Settings.get_setting("high_contrast", false)))


func set_progress(current: int, total: int) -> void:
	value = current
	maximum = maxi(total, 1)
	queue_redraw()


func _on_setting_changed(setting_name: String, setting_value: Variant) -> void:
	if setting_name == "high_contrast":
		_apply_contrast(bool(setting_value))


func _apply_contrast(enabled: bool) -> void:
	_ink = Color.BLACK if enabled else Color("#18252a")
	_edge = Color.WHITE if enabled else Color("#8d9b77")
	_paper = Color.WHITE if enabled else Color("#e9e4ca")
	queue_redraw()


func _draw() -> void:
	var view := get_viewport_rect().size
	var panel := Rect2(Vector2((view.x - PANEL_SIZE.x) / 2.0, TOP_MARGIN), PANEL_SIZE)
	draw_rect(panel, _edge)
	draw_rect(panel.grow(-2), _ink)
	var font := get_theme_default_font()
	draw_string(
		font, panel.position + Vector2(0, 22), title, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 16, _paper
	)
	var bar := Rect2(panel.position + Vector2(16, 30), Vector2(panel.size.x - 32, SEGMENT_HEIGHT))
	var width := (bar.size.x - SEGMENT_GAP * (maximum - 1)) / maximum
	for index in maximum:
		var cell := Rect2(bar.position + Vector2(index * (width + SEGMENT_GAP), 0), Vector2(width, bar.size.y))
		draw_rect(cell, _edge)
		draw_rect(cell.grow(-2), filled_color if index < value else empty_color)
	draw_string(
		font, panel.position + Vector2(0, panel.size.y - 6), progress_format % [value, maximum],
		HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 13, _paper
	)
