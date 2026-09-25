extends Control
class_name MatchingBoard

signal completed

const BOARD_SIZE := Vector2(720, 380)
const BUTTON_SIZE := Vector2(250, 64)
const LEFT_COLUMN_X := 20.0
const RIGHT_COLUMN_X := 450.0
const FIRST_ROW_Y := 52.0
const ROW_SPACING := 84.0

## Dados da atividade. Cada posição em [member correct_targets] informa qual
## item da coluna direita corresponde ao item da mesma posição à esquerda.
@export var left_items: PackedStringArray
@export var right_items: PackedStringArray
@export var correct_targets: PackedInt32Array
@export_multiline var instruction_text := "Escolha um item e depois o destino correto."

var selected_left := -1
var matches: Dictionary = {}
var left_buttons: Array[Button] = []
var right_buttons: Array[Button] = []
var feedback: Label
var dragging := false
var pointer := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		dragging = false
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			for i in left_buttons.size():
				if not matches.has(i) and left_buttons[i].get_global_rect().grow(12).has_point(get_global_mouse_position()):
					_select_left(i)
					dragging = true
					pointer = get_local_mouse_position()
					get_viewport().set_input_as_handled()
					queue_redraw()
					return
		elif dragging:
			dragging = false
			for i in right_buttons.size():
				if right_buttons[i].get_global_rect().grow(12).has_point(get_global_mouse_position()):
					_select_right(i)
					break
			get_viewport().set_input_as_handled()
			queue_redraw()
	elif event is InputEventMouseMotion and dragging:
		pointer = get_local_mouse_position()
		queue_redraw()

func _ready() -> void:
	custom_minimum_size = BOARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not _has_valid_data():
		push_error("MatchingBoard: configure itens e destinos com o mesmo número de entradas.")
		return
	_build_board()

func _has_valid_data() -> bool:
	if left_items.is_empty() or left_items.size() != correct_targets.size():
		return false
	for target in correct_targets:
		if target < 0 or target >= right_items.size():
			return false
	return true

func _build_board() -> void:
	var instruction := Label.new()
	instruction.text = instruction_text
	instruction.position = Vector2(LEFT_COLUMN_X, 0)
	instruction.size = Vector2(BOARD_SIZE.x - LEFT_COLUMN_X * 2.0, 34)
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.add_theme_font_size_override("font_size", 18)
	add_child(instruction)

	for index in left_items.size():
		var button := Button.new()
		button.text = left_items[index]
		button.toggle_mode = true
		button.position = Vector2(LEFT_COLUMN_X, FIRST_ROW_Y + index * ROW_SPACING)
		button.size = BUTTON_SIZE
		button.pressed.connect(_select_left.bind(index))
		add_child(button)
		left_buttons.append(button)
		_style_card(button)

	for index in right_items.size():
		var button := Button.new()
		button.text = right_items[index]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.position = Vector2(RIGHT_COLUMN_X, FIRST_ROW_Y + index * ROW_SPACING)
		button.size = BUTTON_SIZE
		button.pressed.connect(_select_right.bind(index))
		add_child(button)
		right_buttons.append(button)
		_style_card(button)

	feedback = Label.new()
	feedback.position = Vector2(LEFT_COLUMN_X, 314)
	feedback.size = Vector2(BOARD_SIZE.x - LEFT_COLUMN_X * 2.0, 42)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(feedback)

func _style_card(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 18)

func _select_left(index: int) -> void:
	if matches.has(index):
		return
	selected_left = index
	feedback.text = "Conecte: %s" % left_items[index]
	for button in left_buttons:
		button.button_pressed = false
	left_buttons[index].button_pressed = true

func _select_right(index: int) -> void:
	if selected_left == -1:
		feedback.text = "Primeiro escolha uma etapa na coluna da esquerda."
		return
	if correct_targets[selected_left] != index:
		feedback.text = "Essa função pertence a outra etapa. Tente novamente."
		return
	matches[selected_left] = index
	left_buttons[selected_left].disabled = true
	right_buttons[index].disabled = true
	feedback.text = "Correto! Etapa e função conectadas."
	selected_left = -1
	queue_redraw()
	if matches.size() == left_items.size():
		feedback.text = "Todas as associações foram concluídas corretamente!"
		completed.emit()

func _draw() -> void:
	for button in left_buttons:
		draw_circle(button.position + Vector2(button.size.x + 8, button.size.y / 2.0), 6, Color("#e0b75f"))
	for button in right_buttons:
		draw_circle(button.position + Vector2(-8, button.size.y / 2.0), 6, Color("#e0b75f"))
	if dragging and selected_left >= 0:
		var button: Button = left_buttons[selected_left]
		draw_line(button.position + Vector2(button.size.x, button.size.y / 2.0), pointer, Color("#ffe29b"), 4.0, true)
	for left_index in matches:
		var right_index := int(matches[left_index])
		var from := left_buttons[left_index].position + Vector2(left_buttons[left_index].size.x, left_buttons[left_index].size.y / 2.0)
		var to := right_buttons[right_index].position + Vector2(0, right_buttons[right_index].size.y / 2.0)
		draw_line(from, to, Color("#e0b75f"), 4.0, true)
