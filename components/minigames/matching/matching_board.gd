class_name MatchingBoard
extends Control

## Associação de itens: escolha um item à esquerda e o destino correspondente à direita.
## Com [member left_icons]/[member right_icons], os cartões mostram um ícone e o item
## arrastado acompanha o ponteiro.

signal completed
signal answer_checked(correct: bool)

const TEXT_CARD_SIZE := Vector2(250, 64)
const ICON_CARD_SIZE := Vector2(310, 80)
## Ícones de 32 px em escala 2×, para manter o pixel duro.
const ICON_SIZE := 64
const DRAG_ICON_SIZE := Vector2(64, 64)
const MARGIN_X := 20.0
const COLUMN_GAP := 180.0
const FIRST_ROW_Y := 52.0
const ROW_GAP := 20.0
const FEEDBACK_GAP := 10.0
const FEEDBACK_HEIGHT := 42.0
const BOTTOM_MARGIN := 24.0
const LINE_COLOR := Color("#e0b75f")
const DRAG_LINE_COLOR := Color("#ffe29b")

## Dados da atividade. Cada posição em [member correct_targets] informa qual
## item da coluna direita corresponde ao item da mesma posição à esquerda.
@export var left_items: PackedStringArray
@export var right_items: PackedStringArray
@export var correct_targets: PackedInt32Array
## Ícones opcionais, na mesma ordem de [member left_items] e [member right_items].
@export var left_icons: Array[Texture2D] = []
@export var right_icons: Array[Texture2D] = []
@export_multiline var instruction_text := "Escolha um item e depois o destino correto."
## Textos de feedback; permitem reaproveitar o tabuleiro em outras atividades.
@export var wrong_text := "Essa função pertence a outra etapa. Tente novamente."
@export var right_text := "Correto! Etapa e função conectadas."
@export var done_text := "Todas as associações foram concluídas corretamente!"
@export var pick_destination_hint := "Agora escolha a função na coluna da direita."
## Textos lidos pelo leitor de tela; `%s` recebe o texto do cartão.
@export var left_announce := "Etapa: %s. Selecione e depois escolha a função correspondente."
@export var right_announce := "Função: %s."
@export var selected_left_text := "Etapa selecionada: %s."
@export var pick_left_first_text := "Primeiro escolha uma etapa na coluna da esquerda."

var selected_left := -1
var matches: Dictionary = {}
var left_buttons: Array[Button] = []
var right_buttons: Array[Button] = []
var feedback: Label
var dragging := false
var pointer := Vector2.ZERO
var _card_size := TEXT_CARD_SIZE
var _right_column_x := 0.0
var _drag_icon: TextureRect


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		dragging = false
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			for i in left_buttons.size():
				if (
					not matches.has(i)
					and left_buttons[i].get_global_rect().grow(12).has_point(
						get_global_mouse_position()
					)
				):
					_select_left(i)
					dragging = true
					pointer = get_local_mouse_position()
					_update_drag_icon()
					get_viewport().set_input_as_handled()
					queue_redraw()
					return
		elif dragging:
			dragging = false
			_drag_icon.hide()
			for i in right_buttons.size():
				if right_buttons[i].get_global_rect().grow(12).has_point(
					get_global_mouse_position()
				):
					_select_right(i)
					break
			get_viewport().set_input_as_handled()
			queue_redraw()
	elif event is InputEventMouseMotion and dragging:
		pointer = get_local_mouse_position()
		_update_drag_icon()
		queue_redraw()


func _ready() -> void:
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


func _has_icons() -> bool:
	return not left_icons.is_empty() or not right_icons.is_empty()


func _row_y(index: int) -> float:
	return FIRST_ROW_Y + index * (_card_size.y + ROW_GAP)


func _build_board() -> void:
	_card_size = ICON_CARD_SIZE if _has_icons() else TEXT_CARD_SIZE
	_right_column_x = MARGIN_X + _card_size.x + COLUMN_GAP
	var rows := maxi(left_items.size(), right_items.size())
	var feedback_y := _row_y(rows) + FEEDBACK_GAP
	var board_width := _right_column_x + _card_size.x + MARGIN_X
	custom_minimum_size = Vector2(board_width, feedback_y + FEEDBACK_HEIGHT + BOTTOM_MARGIN)

	var instruction := Label.new()
	instruction.text = instruction_text
	instruction.position = Vector2(MARGIN_X, 0)
	instruction.size = Vector2(board_width - MARGIN_X * 2.0, 34)
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.add_theme_font_size_override("font_size", 18)
	add_child(instruction)

	for index in left_items.size():
		var button := Button.new()
		button.text = left_items[index]
		button.set_meta("speech_managed", true)
		button.focus_entered.connect(_announce_left.bind(index))
		button.toggle_mode = true
		button.position = Vector2(MARGIN_X, _row_y(index))
		button.size = _card_size
		button.pressed.connect(_select_left.bind(index))
		add_child(button)
		left_buttons.append(button)
		_style_card(button, _icon(left_icons, index))

	for index in right_items.size():
		var button := Button.new()
		button.set_meta("audio_cue", &"")
		button.text = right_items[index]
		button.set_meta("speech_managed", true)
		button.focus_entered.connect(_announce_right.bind(index))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.position = Vector2(_right_column_x, _row_y(index))
		button.size = _card_size
		button.pressed.connect(_select_right.bind(index))
		add_child(button)
		right_buttons.append(button)
		_style_card(button, _icon(right_icons, index))

	feedback = Label.new()
	feedback.position = Vector2(MARGIN_X, feedback_y)
	feedback.size = Vector2(board_width - MARGIN_X * 2.0, FEEDBACK_HEIGHT)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(feedback)

	# por último, para ficar por cima dos cartões enquanto o item é arrastado
	_drag_icon = TextureRect.new()
	_drag_icon.size = DRAG_ICON_SIZE
	_drag_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_drag_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_drag_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_icon.hide()
	add_child(_drag_icon)


func _icon(icons: Array[Texture2D], index: int) -> Texture2D:
	return icons[index] if index < icons.size() else null


func _style_card(button: Button, icon: Texture2D) -> void:
	button.add_theme_font_size_override("font_size", 18)
	if icon == null:
		return
	button.icon = icon
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_constant_override("icon_max_width", ICON_SIZE)
	button.add_theme_constant_override("h_separation", 12)


func _update_drag_icon() -> void:
	var icon: Texture2D = null
	if selected_left >= 0:
		icon = _icon(left_icons, selected_left)
	_drag_icon.texture = icon
	_drag_icon.visible = dragging and icon != null
	_drag_icon.position = pointer - DRAG_ICON_SIZE / 2.0


func _announce_left(index: int) -> void:
	Speech.speak(left_announce % left_items[index], "minigame")


func _announce_right(index: int) -> void:
	var context := (
		pick_left_first_text
		if selected_left < 0
		else selected_left_text % left_items[selected_left]
	)
	Speech.speak("%s %s" % [right_announce % right_items[index], context], "minigame")


func _select_left(index: int) -> void:
	if matches.has(index):
		return
	selected_left = index
	feedback.text = "Conecte: %s" % left_items[index]
	for button in left_buttons:
		button.set_pressed_no_signal(false)
	left_buttons[index].set_pressed_no_signal(true)
	Speech.speak("%s. %s" % [feedback.text, pick_destination_hint], "minigame")


func _select_right(index: int) -> void:
	if selected_left == -1:
		feedback.text = pick_left_first_text
		Speech.speak(feedback.text, "minigame")
		return
	if correct_targets[selected_left] != index:
		answer_checked.emit(false)
		feedback.text = wrong_text
		Speech.speak(feedback.text, "minigame")
		return
	matches[selected_left] = index
	answer_checked.emit(true)
	left_buttons[selected_left].disabled = true
	right_buttons[index].disabled = true
	feedback.text = right_text
	selected_left = -1
	queue_redraw()
	if matches.size() == left_items.size():
		feedback.text = done_text
		completed.emit()
	Speech.speak(feedback.text, "minigame")


func _draw() -> void:
	for button in left_buttons:
		draw_circle(
			button.position + Vector2(button.size.x + 8, button.size.y / 2.0), 6, LINE_COLOR
		)
	for button in right_buttons:
		draw_circle(button.position + Vector2(-8, button.size.y / 2.0), 6, LINE_COLOR)
	if dragging and selected_left >= 0:
		var button: Button = left_buttons[selected_left]
		draw_line(
			button.position + Vector2(button.size.x, button.size.y / 2.0),
			pointer,
			DRAG_LINE_COLOR,
			4.0,
			true
		)
	for left_index in matches:
		var right_index := int(matches[left_index])
		var from := (
			left_buttons[left_index].position
			+ Vector2(left_buttons[left_index].size.x, left_buttons[left_index].size.y / 2.0)
		)
		var to := (
			right_buttons[right_index].position
			+ Vector2(0, right_buttons[right_index].size.y / 2.0)
		)
		draw_line(from, to, LINE_COLOR, 4.0, true)
		_draw_check(to + Vector2(right_buttons[right_index].size.x + 14, 0))


## Marca de "certo" ao lado do destino já preenchido.
func _draw_check(at: Vector2) -> void:
	var points := PackedVector2Array(
		[at + Vector2(-6, 0), at + Vector2(-2, 5), at + Vector2(7, -6)]
	)
	draw_polyline(points, LINE_COLOR, 4.0, true)
