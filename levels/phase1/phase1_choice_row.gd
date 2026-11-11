class_name Phase1ChoiceRow
extends Node

## Deixa as alternativas lado a lado dentro do balão. Sem isso, o contêiner de
## escolhas do Dialogic fica com a largura do texto e empilha os botões.

const SPACER_NAME := &"ChoiceGap"

## Largura máxima da fileira; acima disso os botões quebram de linha.
@export var max_row_width := 560.0
## Espaço vertical entre a fala e as alternativas.
@export var text_gap := 14.0

var layout: Node


func _ready() -> void:
	Dialogic.Choices.question_shown.connect(_on_question_shown)


func _on_question_shown(_info: Dictionary) -> void:
	if not is_instance_valid(layout):
		return
	for bubble in layout.bubbles:
		if not is_instance_valid(bubble) or not bubble.is_visible_in_tree():
			continue
		var container: Container = bubble.choice_container
		if container == null:
			continue
		var separation := container.get_theme_constant(&"h_separation")
		var width := 0.0
		for button: Control in container.get_children():
			if button.visible and button.name != SPACER_NAME:
				width += button.get_combined_minimum_size().x + separation
		# O balão mede o contêiner alguns quadros depois e se ajusta a esta largura.
		var row_width := minf(maxf(width - separation, 0.0), max_row_width)
		container.custom_minimum_size.x = row_width
		_update_gap(container, row_width)


## Uma linha vazia no topo do contêiner afasta os botões do texto; como o balão
## soma a altura do contêiner, ele cresce junto.
func _update_gap(container: Container, row_width: float) -> void:
	var spacer: Control = container.get_node_or_null(NodePath(SPACER_NAME))
	if spacer == null:
		spacer = Control.new()
		spacer.name = SPACER_NAME
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spacer.focus_mode = Control.FOCUS_NONE
		container.add_child(spacer)
		container.move_child(spacer, 0)
	spacer.visible = row_width > 0.0
	var v_separation := container.get_theme_constant(&"v_separation")
	# Ocupa a largura toda para forçar os botões à linha de baixo.
	spacer.custom_minimum_size = Vector2(row_width, maxf(text_gap - v_separation, 0.0))
