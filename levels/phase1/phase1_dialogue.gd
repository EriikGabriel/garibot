extends RefCounted
class_name Phase1Dialogue

const CHARACTERS := {
	"garibot": "res://dialogic/characters/garibot.dch",
	"garidog": "res://dialogic/characters/garidog.dch",
	"correio_bo": "res://dialogic/characters/correio_bo.dch",
	"morador": "res://dialogic/characters/morador.dch",
	"crianca": "res://dialogic/characters/crianca.dch",
}
const BUBBLE_DIRECTION = preload("res://levels/phase1/phase1_bubble_direction.gd")

static func start(timeline_path: String, level: Node) -> void:
	var prepared_layout: Node = Dialogic.Styles.load_style("bubbles")
	if prepared_layout == null or not prepared_layout.has_method("register_character"):
		push_error("A fase 1 precisa do estilo de diálogo 'bubbles'.")
		return
	var points := {
		"garibot": level.get_node_or_null("Player/bubble_point"),
		"garidog": level.get_node_or_null("Garidog/BubblePoint"),
		"correio_bo": level.get_node_or_null("CorreioBo/BubblePoint"),
		"morador": level.get_node_or_null("Morador/BubblePoint"),
		"crianca": level.get_node_or_null("Crianca/BubblePoint"),
	}
	_register_points(prepared_layout, points)
	var layout: Node = Dialogic.start(timeline_path)
	if layout == null or not layout.has_method("register_character"):
		push_error("O Dialogic não retornou um layout de balões.")
		return
	_register_points(layout, points)
	if not layout.has_node("Phase1BubbleDirection"):
		var direction_controller = BUBBLE_DIRECTION.new()
		direction_controller.name = "Phase1BubbleDirection"
		direction_controller.layout = layout
		layout.add_child(direction_controller)

static func _register_points(layout: Node, points: Dictionary) -> void:
	for id in CHARACTERS:
		var point: Node = points[id]
		if point == null:
			push_error("Ponto de fala ausente: %s" % id)
			continue
		layout.register_character(load(CHARACTERS[id]), point)
