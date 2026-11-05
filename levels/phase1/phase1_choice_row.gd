class_name Phase1ChoiceRow
extends Node

## Deixa as alternativas lado a lado dentro do balão. Sem isso, o contêiner de
## escolhas do Dialogic fica com a largura do texto e empilha os botões.

## Largura máxima da fileira; acima disso os botões quebram de linha.
@export var max_row_width := 560.0

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
			if button.visible:
				width += button.get_combined_minimum_size().x + separation
		# O balão mede o contêiner alguns quadros depois e se ajusta a esta largura.
		container.custom_minimum_size.x = minf(maxf(width - separation, 0.0), max_row_width)
