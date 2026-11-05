class_name Phase1Dialogue
extends RefCounted

## Inicia diálogos da Fase 1 no estilo de balões, ligando cada personagem ao seu ponto de fala.

const SPEAKERS := {
	"res://dialogic/characters/garibot.dch": "Player/BubblePoint",
	"res://dialogic/characters/garidog.dch": "Garidog/BubblePoint",
	"res://dialogic/characters/correio_bo.dch": "CorreioBo/BubblePoint",
	"res://dialogic/characters/morador.dch": "Morador/BubblePoint",
	"res://dialogic/characters/crianca.dch": "Crianca/BubblePoint",
	"res://dialogic/characters/lia.dch": "DonaLia/BubblePoint",
	"res://dialogic/characters/pipa.dch": "Pipa/BubblePoint",
}


## Retorna `false` se o diálogo não pôde ser aberto.
static func start(timeline_path: String, level: Node) -> bool:
	# O layout é registrado antes e depois do start: o Dialogic pode recriá-lo.
	var prepared_layout: Node = Dialogic.Styles.load_style("bubbles")
	if prepared_layout == null or not prepared_layout.has_method("register_character"):
		push_error("A fase 1 precisa do estilo de diálogo 'bubbles'.")
		return false
	_register_speakers(prepared_layout, level)
	var layout: Node = Dialogic.start(timeline_path)
	if layout == null or not layout.has_method("register_character"):
		push_error("O Dialogic não retornou um layout de balões.")
		return false
	_register_speakers(layout, level)
	if not layout.has_node("Phase1BubbleDirection"):
		var direction := Phase1BubbleDirection.new()
		direction.name = "Phase1BubbleDirection"
		direction.layout = layout
		layout.add_child(direction)
	if not layout.has_node("Phase1ChoiceRow"):
		var choice_row := Phase1ChoiceRow.new()
		choice_row.name = "Phase1ChoiceRow"
		choice_row.layout = layout
		layout.add_child(choice_row)
	return true


static func _register_speakers(layout: Node, level: Node) -> void:
	for character_path: String in SPEAKERS:
		var point := level.get_node_or_null(SPEAKERS[character_path])
		if point == null:
			push_error("Ponto de fala ausente: %s" % SPEAKERS[character_path])
			continue
		layout.register_character(load(character_path), point)
